# Test Core Implementation
$BasePath = "J:\replica_lab"
. (Join-Path $BasePath "src\Core\RosettaStone.ps1")
. (Join-Path $BasePath "src\Core\CanonicalModel.ps1")

Write-Host "--- Test 1: Rosetta Stone Mapping ---"
$idObg = [RosettaStone]::GetId("obrigatorio")
Write-Host "ID for 'obrigatorio': $idObg (Expected 8)"
if ($idObg -ne 8) { throw "Rosetta Fail" }

$typeLista = [RosettaStone]::GetType(2)
Write-Host "Type for ID 2: $typeLista (Expected Array)"
if ($typeLista -ne "Array") { throw "Rosetta Type Fail" }

Write-Host "--- Test 2: Field Validation ---"
try {
    $fBad = [CanonicalField]::new("NomePaciente")
    Write-Error "Validation FAIL: Should have rejected 'NomePaciente'"
}
catch {
    Write-Host "Validation OK: Rejected 'NomePaciente' -> $_" -ForegroundColor Green
}

$fGood = [CanonicalField]::new("TXT_NOME_PACIENTE")
Write-Host "Created Field: $($fGood.Identifier)"

Write-Host "--- Test 3: Property Type Validation ---"
# Add Boolean Property (ID 8)
$fGood.AddProperty(8, $true)
Write-Host "Added Property 8 (True)"

try {
    # Try adding String to Boolean (Strict check or conversion?)
    # Our code converts "S" to true. Let's try "Invalid"
    $fGood.AddProperty(8, "NotABool")
    Write-Error "Type Validation FAIL: Should have rejected 'NotABool' for ID 8"
}
catch {
    Write-Host "Type Validation OK: Rejected 'NotABool' for Boolean ID 8 -> $_" -ForegroundColor Green
}

Write-Host "--- Core Tests Passed ---"
