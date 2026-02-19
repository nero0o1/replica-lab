using module "J:\replica_lab\src\Core\RosettaStone.ps1"
using module "J:\replica_lab\src\Core\CanonicalModel.ps1"
using module "J:\replica_lab\src\Drivers\DriverV3.ps1"

Write-Host "--- TEST: Final Structural Truth & Layout ---" -ForegroundColor Cyan

# Define a test document
$doc = [MvDocument]::new()
$doc.Name = "Final Structural Test"
$doc.Id = 9999

# Field 1: Misleading Name + Correct ID
$f1 = [MvField]::new()
$f1.Name = "TXT_RADIO"
$f1.SetTypeFromLegacy(7) # Radio
$f1.X = 15; $f1.Y = 30; $f1.Width = 150; $f1.Height = 25
$doc.AddField($f1)

# Field 2: Boolean Property
$f2 = [MvField]::new()
$f2.Name = "EDITABLE_FIELD"
$f2.SetTypeFromLegacy(1) # Text
$f2.SetProperty("editavel", $true)
$f2.X = 15; $f2.Y = 60; $f2.Width = 100; $f2.Height = 20
$doc.AddField($f2)

# Export
$outputPath = "J:\replica_lab\20_outputs\final_structural_test.json"
$driver = [DriverV3]::new($outputPath)
$driver.Export($doc)

# Verify
$json = Get-Content $outputPath | ConvertFrom-Json
$field1 = $json.fields[0]
$field2 = $json.fields[1]

Write-Host "Field 1 (Radio) ID: $($field1.visualizationType.id)"
Write-Host "Field 1 Layout: $($field1.layout)"
Write-Host "Field 2 (Boolean) value: $($field2.fieldPropertyValues[0].value)"

# Logic Check
$success = $true

if ($field1.visualizationType.id -eq 6) {
    Write-Host "[OK] Mapping 7 -> 6 works." -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Mapping 7 -> 6 failed." -ForegroundColor Red
    $success = $false
}

if ($field1.layout -eq "15,30,150,25") {
    Write-Host "[OK] Layout serialization works." -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Layout string mismatch: $($field1.layout)" -ForegroundColor Red
    $success = $false
}

if ($field2.fieldPropertyValues[0].value -eq $true) {
    Write-Host "[OK] Boolean property preserved." -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Boolean property failed." -ForegroundColor Red
    $success = $false
}

if ($success) {
    Write-Host "--- PHASE 6 VERIFIED SUCCESSFULLY ---" -ForegroundColor Green
}
else {
    exit 1
}
