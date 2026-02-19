<#
.SYNOPSIS
    Crack the hashing algorithm by trying specific JSON serializations of the 'data' object.
    Target: 38dc8cb8e8eb9111af8491cdab02b492
#>

$Target = "38dc8cb8e8eb9111af8491cdab02b492"
$JsonFile = "J:\replica_lab\20_outputs\audit\debug_data_dump.json"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-Md5([string]$s) {
    $bytes = $Utf8NoBom.GetBytes($s)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $h = $md5.ComputeHash($bytes)
    return ([BitConverter]::ToString($h).Replace("-", "").ToLower())
}

# Load the object (PowerShell deserializes it)
$data = Get-Content $JsonFile -Raw | ConvertFrom-Json

Write-Host "Target: $Target"

# Candidate 1: PowerShell Default ConvertTo-Json (2 spaces? 4 spaces?)
$c1 = ConvertTo-Json $data -Depth 100
$h1 = Get-Md5 $c1
Write-Host "Cand 1 (PS Default): $h1"
if ($h1 -eq $Target) { Write-Host "WINNER 1"; exit }

# Candidate 2: PS Default + CRLF -> LF
$c2 = $c1 -replace "`r`n", "`n"
$h2 = Get-Md5 $c2
Write-Host "Cand 2 (PS LF): $h2"
if ($h2 -eq $Target) { Write-Host "WINNER 2"; exit }

# Candidate 3: Compress (Minified)
$c3 = ConvertTo-Json $data -Depth 100 -Compress
$h3 = Get-Md5 $c3
Write-Host "Cand 3 (Minified): $h3"
if ($h3 -eq $Target) { Write-Host "WINNER 3"; exit }

# Candidate 4: Custom Serializer (No spaces, sorted keys?)
# PS ConvertTo-Json preserves order (mostly).
# Let's try to mimic a standard "Newtonsoft" compact: {"key":"val","key2":1}
# This is what -Compress usually does.
# But what if nulls are removed? Or empty strings?

# Candidate 5: Data + Group
# Need to load the original full file for this.
# Assuming we don't have it here easily, we skip complex composites.

# Candidate 6:  Check if hash matches "identifier" + "propertyValues" serialized
# Inspect properties
$props = $data.propertyDocumentValues
# Try hash of JUST properties
$c6 = ConvertTo-Json $props -Compress -Depth 100
$h6 = Get-Md5 $c6
Write-Host "Cand 6 (Props Only): $h6"
if ($h6 -eq $Target) { Write-Host "WINNER 6"; exit }

# Candidate 7: Explicit spacing (e.g. key : val)
# Hard to script with ConvertTo-Json.

# What if it's UTF-16?
function Get-Md5Wide([string]$s) {
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($s)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $h = $md5.ComputeHash($bytes)
    return ([BitConverter]::ToString($h).Replace("-", "").ToLower())
}
$h7 = Get-Md5Wide $c1
Write-Host "Cand 7 (Reference UTF16): $h7"

# Summary
Write-Host "No brute force match found yet."
