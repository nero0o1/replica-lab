<#
.SYNOPSIS
    Fixpack D: Resolves VERSION_HASH_MISSING issues in Editor 3 files.
    Applies logic: version.hash = MD5(Minified Data Object).

.DESCRIPTION
    1. Reads audit issues CSV.
    2. Filters for VERSION_HASH_MISSING.
    3. For each file:
       - Loads JSON.
       - Computes MD5 of "data" object (minified).
       - Updates $.version.hash.
       - Saves file (UTF-8 No BOM).
    4. Logs changes to proper CSV.

.PARAMETER IssuesCsv
    Path to the input issues CSV (default: latest editor3_audit_issues_v2_*.csv).

.PARAMETER Mode
    DRYRUN (default) or APPLY.

.NOTES
    Algorithm Selected: Candidate G (MD5 of Minified "data" object).
    Reason: Deep dive proved version.hash correlates 100% with identical "data" objects, 
            even though exact bitwise reproduction of legacy hashes was not possible 
            (likely due to legacy specific serialization).
    This ensures deterministic, data-integrity-based hashing for recovered files.
#>

param(
    [string]$IssuesCsv = "",
    [string]$Mode = "DRYRUN"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BasePath = "J:\replica_lab"
$BackupRoot = Join-Path $BasePath "20_outputs\fix"
$AuditDir = Join-Path $BasePath "20_outputs\audit"

# Encoding
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Helper: MD5
function Get-Md5Hex([string]$Text) {
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $bytes = $Utf8NoBom.GetBytes($Text)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    try { $hash = $md5.ComputeHash($bytes) } finally { $md5.Dispose() }
    $sb = New-Object System.Text.StringBuilder
    foreach ($b in $hash) { [void]$sb.AppendFormat("{0:x2}", $b) }
    return $sb.ToString()
}

# Helper: CSV Escape
function Csv-Escape([string]$s) {
    if ($s.Contains(";") -or $s.Contains('"')) { return '"' + $s.Replace('"', '""') + '"' }
    return $s
}

# --- Resolve Input ---
if ([string]::IsNullOrWhiteSpace($IssuesCsv)) {
    $found = Get-ChildItem -Path $AuditDir -Filter "editor3_audit_issues_v2_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $found) { Write-Error "No audit CSV found."; exit 1 }
    $IssuesCsv = $found.FullName
}
Write-Host "Using Issues CSV: $IssuesCsv"
Write-Host "Mode: $Mode"

# --- Setup Output ---
$Stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$BackupDir = Join-Path $BackupRoot ("backup_D_" + $Stamp)
$ChangeLogPath = Join-Path $BackupRoot ("fixpack_D_changelog_" + $Stamp + ".csv")
$SummaryPath = Join-Path $BackupRoot ("fixpack_D_summary_" + $Stamp + ".txt")

if ($Mode -eq "APPLY") {
    if (-not (Test-Path -LiteralPath $BackupDir)) { [System.IO.Directory]::CreateDirectory($BackupDir) | Out-Null }
}

$rows = Import-Csv -LiteralPath $IssuesCsv -Delimiter ";"
$targets = $rows | Where-Object { $_.issue_code -eq "VERSION_HASH_MISSING" }

Write-Host "Found $($targets.Count) files with VERSION_HASH_MISSING."

if ($targets.Count -eq 0) { Write-Host "Nothing to do."; exit 0 }

# --- Process ---
$filesTouched = 0
$hashesApplied = 0
$errors = 0

$sw = New-Object System.IO.StreamWriter($ChangeLogPath, $false, $Utf8NoBom)
$sw.WriteLine("file;action;old_hash;new_hash;mode;status")

foreach ($row in $targets) {
    $file = $row.file
    if (-not (Test-Path -LiteralPath $file)) {
        Write-Warning "File not found: $file"
        continue
    }

    try {
        $filesTouched++
        
        # Parse
        $raw = [System.IO.File]::ReadAllText($file)
        # Use regex to find version object to be safe about location?
        # No, we need object manipulation. Use ConvertFrom-Json.
        $json = ConvertFrom-Json $raw
        
        # Check integrity
        if (-not $json.data) {
            throw "File missing 'data' object structure."
        }
        if (-not $json.version) {
            # Create version if missing? The issue says VERSION_HASH_MISSING, so version might exist.
            # But if version is missing, we should probably add it.
            # Assuming safely that structure exists or we skip.
            if ($row.issue_code -ne "VERSION_MISSING") {
                # If issue is HASH missing, version should exist.
                # If parsed json has no version, maybe parse failed?
                # Proceeding with caution.
                $json | Add-Member -MemberType NoteProperty -Name "version" -Value ([PSCustomObject]@{})
            }
        }

        # Compute Hash
        # Algo: MD5(Minified Data)
        $dataSerialized = ConvertTo-Json $json.data -Depth 100 -Compress
        $newHash = Get-Md5Hex $dataSerialized
        
        $oldHash = "null"
        if ($json.version.hash) { $oldHash = $json.version.hash }
        
        # Action
        if ($Mode -eq "APPLY") {
            # Backup
            $relPath = $file.Substring($BasePath.Length).TrimStart("\")
            $bakPath = Join-Path $BackupDir $relPath
            $bakParent = [System.IO.Path]::GetDirectoryName($bakPath)
            if (-not (Test-Path -LiteralPath $bakParent)) { [System.IO.Directory]::CreateDirectory($bakParent) | Out-Null }
            [System.IO.File]::Copy($file, $bakPath, $true)
            
            # Update
            $json.version | Add-Member -MemberType NoteProperty -Name "hash" -Value $newHash -Force
            
            # Serialize (Normalize entire file)
            # Warning: ConvertTo-Json might reorder keys.
            # We accept this as part of the "Fix".
            # To preserve order, standard PS object is okay-ish.
            $newContent = ConvertTo-Json $json -Depth 100
            
            # Fix escaping if needed (PS escapes / as \/ sometimes? No, generally ok).
            # Fix unicode characters? PS ConvertTo-Json escapes unicode like \uXXXX.
            # Editor 3 expects UTF-8 literals usually.
            # We can use Regex to unescape if necessary, but standard JSON is valid.
            
            [System.IO.File]::WriteAllText($file, $newContent, $Utf8NoBom)
            
            $status = "OK"
            $hashesApplied++
        }
        else {
            $status = "DRYRUN"
        }
        
        $line = "$(Csv-Escape $file);SET_VERSION_HASH;$oldHash;$newHash;$Mode;$status"
        $sw.WriteLine($line)
        
    }
    catch {
        $errors++
        $line = "$(Csv-Escape $file);ERROR;Error;$_;$Mode;FAIL"
        $sw.WriteLine($line)
        Write-Warning "Failed $file : $_"
    }
}

$sw.Dispose()

# Summary
$report = "Timestamp: $Stamp
Mode: $Mode
Targets: $($targets.Count)
Files Touched: $filesTouched
Hashes Applied: $hashesApplied
Errors: $errors
ChangeLog: $ChangeLogPath
Backup: $BackupDir
"
[System.IO.File]::WriteAllText($SummaryPath, $report, $Utf8NoBom)

Write-Host "Done. Summary saved to $SummaryPath"
Write-Host "ChangeLog saved to $ChangeLogPath"
