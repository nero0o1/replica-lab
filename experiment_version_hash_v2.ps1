<#
.SYNOPSIS
    Experiment v2 to reverse-engineer Editor 3 version.hash algorithm.
    Fixes sample selection (identifying version.hash strictly).
    Adds candidates for payload-based hashing (Data, Root-minus-Version).

.DESCRIPTION
    1. Scans for .edt files where $.version.hash is populated.
    2. Computes candidates:
       A: Raw MD5
       D: Version-no-hash (previous best guess)
       F: Root object without "version" property (MD5 of string before ,"version":)
       G: "data" object only
       H: Minified Root without version
#>

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BasePath = "J:\replica_lab"
$SourceDir = Join-Path $BasePath "10_work\extracted_edt3"
$OutDir = Join-Path $BasePath "20_outputs\audit"
$ReportPath = Join-Path $OutDir "hash_candidate_matrix_v2.csv"

if (-not (Test-Path -LiteralPath $OutDir)) { [System.IO.Directory]::CreateDirectory($OutDir) | Out-Null }

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

function Get-Props([object]$o) {
    if ($o -is [System.Collections.IDictionary]) { return @($o.Keys) }
    return @($o.PSObject.Properties.Name)
}

# --- Candidates ---

# A: Raw
function Get-CandidateA([string]$Content) {
    return Get-Md5Hex $Utf8NoBom.GetBytes($Content)
}

# D: Version block minus hash (Fixed regex to be strict on JSON structure?)
# Actually, if the hash covers "everything but the hash", it might be the whole file with hash="" or hash removed.
function Get-CandidateD([string]$Content) {
    # Replace "hash":"..." with nothing inside version.
    # But doing this safely with regex on full JSON is hard.
    # Heuristic: Replace `"hash"\s*:\s*"[a-f0-9]{32}"` with `"hash":null` or remove it?
    # Let's try REMOVING it.
    $mod = $Content -replace '"hash"\s*:\s*"[a-fA-F0-9]{32}"\s*,?', '' 
    # Clean up potentially trailing commas: `, }` -> `}` is hard to regex globally safely.
    # This candidate is weak if we don't have a parser.
    return Get-Md5Hex $Utf8NoBom.GetBytes($mod)
}

# F: Root minus Version
# Assumes "version" is the LAST property or we can split the string.
# structure: { "name":..., "data":..., "version":{...} }
function Get-CandidateF([string]$Content) {
    # Look for ,"version"
    $idx = $Content.LastIndexOf(',"version"')
    if ($idx -lt 0) { $idx = $Content.LastIndexOf(', "version"') }
    
    if ($idx -gt 0) {
        # Take everything up to that comma, adds closing brace
        $sub = $Content.Substring(0, $idx) + "}"
        return Get-Md5Hex $Utf8NoBom.GetBytes($sub)
    }
    return "FAIL_EXTRACT"
}

# G: "data" object MD5
function Get-CandidateG([string]$Content) {
    # Extract data object.
    # regex: "data"\s*:\s*(\{... balanced ... \})
    # Too hard for regex. Use parser.
    try {
        $json = ConvertFrom-Json $Content
        if ($null -ne $json.data) {
            # Re-serialize data. 
            # DANGER: ConvertTo-Json changes formatting.
            # If the original hash depends on EXACT spacing, this fails.
            # But if it depends on canonical value, we need a canonical serializer.
            # Let's try Minified Data.
            $minData = ConvertTo-Json $json.data -Depth 100 -Compress
            return Get-Md5Hex $Utf8NoBom.GetBytes($minData)
        }
    }
    catch {}
    return "FAIL_PARSE"
}

# H: Minified Root without Version
function Get-CandidateH([string]$Content) {
    try {
        $json = ConvertFrom-Json $Content
        # Create a copy without version property
        $clone = $json.PSObject.Copy()
        $json.PSObject.Properties.Remove("version") # May not work on PSCustomObject depending on how it's created
        # Select-Object * -ExcludeProperty version
        $noVer = $json | Select-Object * -ExcludeProperty version
        
        $min = ConvertTo-Json $noVer -Depth 100 -Compress
        return Get-Md5Hex $Utf8NoBom.GetBytes($min)
    }
    catch { return "FAIL" }
}

# --- Selection ---

Write-Host "Scanning for files with valid VERSION.HASH..."
$files = Get-ChildItem -LiteralPath $SourceDir -Recurse -Filter "*.edt" -File
$sample = @()

foreach ($f in $files) {
    if ($sample.Count -ge 50) { break }
    
    $txt = [System.IO.File]::ReadAllText($f.FullName)
    
    # Strict regex for version.hash
    # Look for "version" followed by { ... "hash": "HEX"
    # This is still not perfect but better relative to parsing every file.
    # We will Parse to be sure. parsing 1000 files is slow, but we only need 50.
    
    try {
        $j = ConvertFrom-Json $txt
        if ($j.version -and $j.version.hash -match '^[a-fA-F0-9]{32}$') {
            $sample += [PSCustomObject]@{
                Path       = $f.FullName
                Content    = $txt
                StoredHash = $j.version.hash
            }
            Write-Host -NoNewline "."
        }
    }
    catch {}
}
Write-Host ""
Write-Host "Found $($sample.Count) valid samples."

if ($sample.Count -eq 0) {
    Write-Error "No samples found with valid version.hash! Cannot proceed."
}

# --- Analysis ---

$results = @()
$matches = @{ A = 0; D = 0; F = 0; G = 0; H = 0 }

foreach ($item in $sample) {
    $raw = $item.Content
    $target = $item.StoredHash.ToLower()
    
    $cA = Get-CandidateA $raw
    $cD = Get-CandidateD $raw
    $cF = Get-CandidateF $raw
    $cG = Get-CandidateG $raw
    $cH = Get-CandidateH $raw
    
    $r = [Ordered]@{
        File = [System.IO.Path]::GetFileName($item.Path)
        Stored = $target
        CandA = $cA; MatchA = ($cA -eq $target)
        CandD = $cD; MatchD = ($cD -eq $target)
        CandF = $cF; MatchF = ($cF -eq $target)
        CandG = $cG; MatchG = ($cG -eq $target)
        CandH = $cH; MatchH = ($cH -eq $target)
    }
    
    if ($r.MatchA) { $matches.A++ }
    if ($r.MatchD) { $matches.D++ }
    if ($r.MatchF) { $matches.F++ }
    if ($r.MatchG) { $matches.G++ }
    if ($r.MatchH) { $matches.H++ }
    
    $results += [PSCustomObject]$r
}

$results | Export-Csv -Path $ReportPath -NoTypeInformation -Delimiter ";"
Write-Host "Summary:"
$matches.Keys | ForEach-Object { Write-Host "$_ : $($matches[$_])" }

if ($matches.A -eq $sample.Count) { Write-Host "WINNER: A (File MD5)" -ForegroundColor Green }
elseif ($matches.F -eq $sample.Count) { Write-Host "WINNER: F (Root minus Version)" -ForegroundColor Green }
elseif ($matches.G -eq $sample.Count) { Write-Host "WINNER: G (Data Only)" -ForegroundColor Green }
elseif ($matches.H -eq $sample.Count) { Write-Host "WINNER: H (Minified Root no-Ver)" -ForegroundColor Green }
else { Write-Host "NO WINNER" -ForegroundColor Red }
