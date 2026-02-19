<#
.SYNOPSIS
    Deep dive into ONE specific hash group to find the common denominator.
    Target Hash: 38dc8cb8e8eb9111af8491cdab02b492 (from 3.headers_CABECALHO_SES_GO1.edt)
#>

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BasePath = "J:\replica_lab"
$SourceDir = Join-Path $BasePath "10_work\extracted_edt3"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$TargetHash = "38dc8cb8e8eb9111af8491cdab02b492"

function Get-Md5Hex([string]$Text) {
    $bytes = $Utf8NoBom.GetBytes($Text)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    try { $hash = $md5.ComputeHash($bytes) } finally { $md5.Dispose() }
    $sb = New-Object System.Text.StringBuilder
    foreach ($b in $hash) { [void]$sb.AppendFormat("{0:x2}", $b) }
    return $sb.ToString()
}

Write-Host "Searching for files with hash $TargetHash..."
$files = Get-ChildItem -LiteralPath $SourceDir -Recurse -Filter "*.edt" -File
$group = @()

foreach ($f in $files) {
    if ($group.Count -ge 10) { break }
    # Quick text check to speed up
    $txt = [System.IO.File]::ReadAllText($f.FullName)
    if ($txt.Contains($TargetHash)) {
        try {
            $j = ConvertFrom-Json $txt
            if ($j.version.hash -eq $TargetHash) {
                $group += $j
                Write-Host "Found match: $($f.Name)"
            }
        }
        catch {}
    }
}

if ($group.Count -lt 2) {
    Write-Error "Need at least 2 files to compare. Found $($group.Count)."
}

$ref = $group[0]
Write-Host "Comparing $($group.Count) files against reference..."

# Compare Components
$sameData = $true
$sameLayouts = $true
$sameGroup = $true
$sameVersionId = $true

foreach ($j in $group) {
    # Compare Data (Serialized minified)
    $d1 = ConvertTo-Json $ref.data -Compress -Depth 100
    $d2 = ConvertTo-Json $j.data -Compress -Depth 100
    if ($d1 -ne $d2) { $sameData = $false; Write-Host "Data DIFF" }

    # Compare Layouts
    $l1 = ConvertTo-Json $ref.version.layouts -Compress -Depth 100
    $l2 = ConvertTo-Json $j.version.layouts -Compress -Depth 100
    if ($l1 -ne $l2) { $sameLayouts = $false; Write-Host "Layouts DIFF" }
    
    # Compare Group
    $g1 = ConvertTo-Json $ref.group -Compress -Depth 100
    $g2 = ConvertTo-Json $j.group -Compress -Depth 100
    if ($g1 -ne $g2) { $sameGroup = $false; Write-Host "Group DIFF" }
    
    # Compare Version ID
    if ($ref.version.id -ne $j.version.id) { $sameVersionId = $false; Write-Host "VersionID DIFF" }
}

Write-Host "--- Comparison Result ---"
Write-Host "Invariant Data: $sameData"
Write-Host "Invariant Layouts: $sameLayouts"
Write-Host "Invariant Group: $sameGroup"
Write-Host "Invariant VersionID: $sameVersionId"

# Based on invariants, try to hash ONLY the invariant parts
if ($sameData -and $sameLayouts) {
    Write-Host "Attempting Hash on Data + Layouts..."
    
    # Candidate 1: Canonical Data + Canonical Layouts concatenated
    # We need a predictable serialization.
    # Let's try: ConvertTo-Json -Compress (Assuming PS 5.1 is the reference implementation? Unlikely)
    # But let's try just "data" string if layouts are empty?
    
    $dRef = ConvertTo-Json $ref.data -Compress -Depth 100
    $lRef = ConvertTo-Json $ref.version.layouts -Compress -Depth 100
    
    # Can 1: MD5(DataMin + LayoutsMin)
    $h1 = Get-Md5Hex ($dRef + $lRef)
    Write-Host "Cand 1 (DataMin+LayoutsMin): $h1"
    
    # Can 2: MD5(DataMin + VersionID)?
    
    # Can 3: Is there a 'hash' inside layouts?
    
    # Check if REFERENCE HASH matches any simple transformation
    if ($h1 -eq $TargetHash) { Write-Host "MATCH FOUND! Data+Layouts" -ForegroundColor Green }
}

# Dump the Data object to inspect manually
$dumpPath = Join-Path $BasePath "20_outputs\audit\debug_data_dump.json"
Set-Content -Path $dumpPath -Value (ConvertTo-Json $ref.data -Depth 100)
Write-Host "Dumped reference data to $dumpPath"
