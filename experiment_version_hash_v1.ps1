<#
.SYNOPSIS
    Experiment to reverse-engineer Editor 3 version.hash algorithm.
    T2 of the Version Hash resolution plan.

.DESCRIPTION
    1. Scans for .edt files with existing 32-char hex version hashes.
    2. Selects a random sample of 120 files.
    3. Computes 5 candidate hashes for each file:
       A: MD5(Raw Bytes)
       B: MD5(Normalized Text - Trim/Whitespace)
       C: MD5(Minified JSON)
       D: MD5(Version Object part without 'hash' field)
       E: MD5(Canonical Version Object leaf-values)
    4. Exports results to CSV.

.NOTES
    Encoding: UTF-8 No BOM throughout.
#>

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BasePath = "J:\replica_lab"
$SourceDir = Join-Path $BasePath "10_work\extracted_edt3"
$OutDir = Join-Path $BasePath "20_outputs\audit"
$ReportPath = Join-Path $OutDir "hash_candidate_matrix.csv"
$SampleIndexPath = Join-Path $OutDir "hash_sample_index.csv"

# Ensure output dir
if (-not (Test-Path -LiteralPath $OutDir)) { [System.IO.Directory]::CreateDirectory($OutDir) | Out-Null }

# UTF-8 No BOM
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-Md5Hex([byte[]]$bytes) {
    if ($null -eq $bytes) { return "" }
    $md5 = [System.Security.Cryptography.MD5]::Create()
    try { $hash = $md5.ComputeHash($bytes) }
    finally { $md5.Dispose() }
    $sb = New-Object System.Text.StringBuilder
    foreach ($b in $hash) { [void]$sb.AppendFormat("{0:x2}", $b) }
    return $sb.ToString()
}

# Candidate A: Raw File Bytes
function Get-CandidateA([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    return Get-Md5Hex $bytes
}

# Candidate B: Normalized Text (Trim + condense whitespace)
function Get-CandidateB([string]$Text) {
    # Trim and collapse runs of whitespace to single space
    $norm = $Text.Trim() -replace '\s+', ' '
    return Get-Md5Hex $Utf8NoBom.GetBytes($norm)
}

# Candidate C: Minified JSON (remove all whitespace outside strings - simplistic regex approach)
# WARNING: This is a heuristics approach. A proper parser-based minify is safer but regex is fast for "structure" checks.
# For T2, we want to see if they just stripped whitespace.
function Get-CandidateC([string]$Text) {
    # Remove all whitespace characters. Note: this destroys strings with spaces!
    # If the producer used a standard "Minify", it preserves strings.
    # Let's try a smarter regex: Replace whitespace that is NOT inside quotes? Too complex for regex.
    # We will try the "lazy" minify: Remove \r, \n, \t and spaces around braces/colons.
    # Actually, simpler: if they used a JSON serializer without formatting.
    # Let's assume standard "Minify" means no extra whitespace.
    # For this experiment, let's try strict removal of ALL whitespace if C fails overly we know why.
    # Better: Parsing and re-serializing as Minified.
    try {
        $obj = ConvertFrom-Json $Text
        $min = ConvertTo-Json $obj -Depth 100 -Compress
        return Get-Md5Hex $Utf8NoBom.GetBytes($min)
    }
    catch {
        return "ERROR"
    }
}

# Candidate D: Version Object source substring minus the hash field
# This assumes the hash is calculated on the "version": { ... } part BEFORE the hash is inserted.
function Get-CandidateD([string]$Text) {
    # Extract "version": { ... }
    # We look for the exact string in the file to preserve order/formatting of the producer
    if ($Text -match '(?s)"version"\s*:\s*\{(.*?)\}') {
        $inner = $Matches[1]
        # Remove "hash": "..." and potential trailing comma
        # Regex to remove "hash" key and value, handling quotes and potential comma
        $cleaned = $inner -replace '(?s)"hash"\s*:\s*"[a-fA-F0-9]{32}"\s*,?', ''
        $cleaned = $cleaned.Trim()
        # Fix trailing comma if we removed the last item and left a comma
        if ($cleaned.EndsWith(",")) { $cleaned = $cleaned.Substring(0, $cleaned.Length - 1) }
        
        # Reconstruct the braces
        $block = "{" + $cleaned + "}"
        return Get-Md5Hex $Utf8NoBom.GetBytes($block)
    }
    return "MISSING_VERSION_BLOCK"
}

# Candidate E: Canonical Object (Parsing and canonicalizing values)
function Get-CandidateE([string]$Text) {
    try {
        $obj = ConvertFrom-Json $Text
        if ($null -eq $obj.version) { return "MISSING_VERSION_OBJ" }
        
        # Build canonical string of version properties (excluding hash)
        # Sort keys? Or use definition order? The prompts says "root key order EXACT". 
        # But for hash generation, usually it's specific fields.
        # Let's try: major|minor|revision|timestamp|... concatenated
        
        $v = $obj.version
        $props = $v.PSObject.Properties | Where-Object { $_.Name -ne "hash" } 
        # PowerShell JSON object properties might be ordered if using OrderedDict, but ConvertFrom-Json in PS5.1 is... tricky.
        # Let's assume standard fields: major, minor, revision, build, timestamp
        
        $sb = New-Object System.Text.StringBuilder
        foreach ($p in $props) {
            $val = $p.Value
            if ($null -eq $val) { $val = "null" }
            $sb.Append($p.Name).Append(":").Append($val).Append("|")
        }
        return Get-Md5Hex $Utf8NoBom.GetBytes($sb.ToString())
    }
    catch {
        return "ERROR"
    }
}

# --- Main ---

Write-Host "Scanning for candidate files..."
$files = Get-ChildItem -LiteralPath $SourceDir -Recurse -Filter "*.edt" -File
$candidates = @()

foreach ($f in $files) {
    # Quick check for existing hash without parsing everything
    $content = [System.IO.File]::ReadAllText($f.FullName) # Default encoding check?
    # Ensure raw read
    # Actually, let's use the helper to read text properly if needed, but ReadAllText usually handles UTF8 BOM/NoBOM auto-detect well enough for regex
    
    if ($content -match '"hash"\s*:\s*"([a-fA-F0-9]{32})"') {
        $storedHash = $Matches[1]
        $candidates += [PSCustomObject]@{
            Path       = $f.FullName
            Content    = $content
            StoredHash = $storedHash
        }
    }
}

Write-Host "Found $($candidates.Count) files with existing hashes."
if ($candidates.Count -eq 0) {
    Write-Error "No candidates found for reverse engineering."
}

# Sample size
$sampleSize = 120
$sample = $candidates | Get-Random -Count $sampleSize

Write-Host "Selected sample of $($sample.Count) files. Analyzing..."

$results = @()
$matchesA = 0
$matchesB = 0
$matchesC = 0
$matchesD = 0
$matchesE = 0

foreach ($item in $sample) {
    $raw = $item.Content
    $target = $item.StoredHash.ToLower()
    
    $cA = Get-CandidateA $item.Path
    $cB = Get-CandidateB $raw
    $cC = Get-CandidateC $raw
    $cD = Get-CandidateD $raw
    $cE = Get-CandidateE $raw
    
    $matchA = ($cA -eq $target)
    $matchB = ($cB -eq $target)
    $matchC = ($cC -eq $target)
    $matchD = ($cD -eq $target)
    $matchE = ($cE -eq $target)
    
    if ($matchA) { $matchesA++ }
    if ($matchB) { $matchesB++ }
    if ($matchC) { $matchesC++ }
    if ($matchD) { $matchesD++ }
    if ($matchE) { $matchesE++ }

    $results += [PSCustomObject]@{
        File        = [System.IO.Path]::GetFileName($item.Path)
        Result      = $(if ($matchA -or $matchB -or $matchC -or $matchD -or $matchE) { "MATCH" } else { "FAIL" })
        Stored      = $target
        CandA_Raw   = $cA
        MatchA      = $matchA
        CandB_Norm  = $cB
        MatchB      = $matchB
        CandC_Min   = $cC
        MatchC      = $matchC
        CandD_Part  = $cD
        MatchD      = $matchD
        CandE_Canon = $cE
        MatchE      = $matchE
    }
}

$results | Export-Csv -Path $ReportPath -NoTypeInformation -Delimiter ";"
Write-Host "Results exported to $ReportPath"
Write-Host ""
Write-Host "--- Summary ---"
Write-Host "Total Sample: $($sample.Count)"
Write-Host "Match A (Raw): $matchesA"
Write-Host "Match B (Norm): $matchesB"
Write-Host "Match C (Minify): $matchesC"
Write-Host "Match D (VersionObj - hash): $matchesD"
Write-Host "Match E (Canonical): $matchesE"

if ($matchesD -gt ($sample.Count * 0.95)) {
    Write-Host "WINNER CANDIDATE: D (Version Object Block without hash tag)" -ForegroundColor Green
}
elseif ($matchesA -gt ($sample.Count * 0.95)) {
    Write-Host "WINNER CANDIDATE: A (Raw File MD5)" -ForegroundColor Green
}
else {
    Write-Host "NO CLEAR WINNER. Check CSV." -ForegroundColor Red
}
