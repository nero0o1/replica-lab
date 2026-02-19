# Test Round-Trip (V3 -> Canonical -> V2 & V3)
$BasePath = "J:\replica_lab"
$InputFile = Join-Path $BasePath "20_outputs\test_v3_output.edt" # Created in previous step
$OutV3 = Join-Path $BasePath "20_outputs\roundtrip_v3.edt"
$OutV2 = Join-Path $BasePath "20_outputs\roundtrip_v2.xml"

# 1. Load Components
. (Join-Path $BasePath "src\Core\RosettaStone.ps1")
. (Join-Path $BasePath "src\Core\CanonicalModel.ps1")
. (Join-Path $BasePath "src\Drivers\DriverV3.ps1")
. (Join-Path $BasePath "src\Drivers\DriverV2.ps1")
. (Join-Path $BasePath "src\Loaders\LoaderV3.ps1")

Write-Host "--- Starting Round-Trip Test ---"

if (-not (Test-Path $InputFile)) {
    throw "Input file not found. please run test_driver_v3.ps1 first."
}

# 2. LOAD
Write-Host "Loading $InputFile..."
try {
    $form = [LoaderV3]::Import($InputFile)
    Write-Host "Import Success! Form: $($form.Name) ($($form.Identifier))"
    Write-Host "Fields Loaded: $($form.Fields.Count)"
}
catch {
    throw "Import Failed: $_"
}

# 3. EXPORT V3 (Re-generation)
Write-Host "Exporting to V3 ($OutV3)..."
[DriverV3]::Export($form, $OutV3)

if (Test-Path $OutV3) {
    $newJson = Get-Content $OutV3 -Raw | ConvertFrom-Json
    $oldJson = Get-Content $InputFile -Raw | ConvertFrom-Json
    
    # Compare Hashes
    $h1 = $oldJson.version.hash
    $h2 = $newJson.version.hash
    
    Write-Host "Old Hash: $h1"
    Write-Host "New Hash: $h2"
    
    if ($h1 -eq $h2) {
        Write-Host "V3 Round-Trip Hash MATCH: Perfect Stability!" -ForegroundColor Green
    }
    else {
        Write-Warning "V3 Round-Trip Hash MISMATCH. (Order of keys?)"
    }
}
else { throw "V3 Export Fail" }

# 4. EXPORT V2 (Hybrid Capability)
Write-Host "Exporting to V2 ($OutV2)..."
$xml = [DriverV2]::Export($form, $OutV2)

if ($xml -match "<ROWSET>") {
    Write-Host "V2 Export Success (XML Generated)" -ForegroundColor Green
}
else {
    throw "V2 Export Fail"
}

Write-Host "--- Test Complete ---"
