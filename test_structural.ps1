using module "J:\replica_lab\src\Core\CanonicalModel.ps1"
using module "J:\replica_lab\src\Core\RosettaStone.ps1"
using module "J:\replica_lab\src\Drivers\DriverV3.ps1"

Write-Host "--- TEST: Structural Truth ---" -ForegroundColor Cyan

# 1. Create a "Misleading" Field (Name implies Text, but ID is Radio)
# V2 ID 7 = Radio (Maps to Modern 6)
$f = [MvField]::new()
$f.Name = "TXT_OPCAO_RADIO" # Prefix implies TEXT (1)
$f.Identifier = "TXT_OPCAO_RADIO"
$f.SetTypeFromLegacy(7) # Hardcoded Legacy ID for Radio

# Layout coordinates
$f.X = 10
$f.Y = 20
$f.Width = 200
$f.Height = 30

$doc = [MvDocument]::new()
$doc.Name = "Structural Test"
$doc.AddField($f)

# 2. Export to V3
$driver = [DriverV3]::new("J:\replica_lab\20_outputs\structural_test.json")
$driver.Export($doc)

# 3. Verify Output
$json = Get-Content "J:\replica_lab\20_outputs\structural_test.json" | ConvertFrom-Json
$field = $json.fields[0]

Write-Host "Field Name: $($field.name)"
Write-Host "VisualizationType ID: $($field.visualizationType.id)"
Write-Host "VisualizationType Identifier: $($field.visualizationType.identifier)"
Write-Host "Layout String: $($field.layout)"

if ($field.visualizationType.id -eq 6 -and $field.visualizationType.identifier -eq "RADIOBUTTON") {
    Write-Host "[SUCCESS] VisualType took precedence over Name prefix." -ForegroundColor Green
}
else {
    Write-Host "[FAILURE] VisualType mapping failed." -ForegroundColor Red
}

if ($field.layout -eq "10,20,200,30") {
    Write-Host "[SUCCESS] Layout string correctly serialized." -ForegroundColor Green
}
else {
    Write-Host "[FAILURE] Layout string mismatch: $($field.layout)" -ForegroundColor Red
}
