# Fire Test: Phase 11 forensic verification (V12.1) - HARDENED

# --- 1. SETUP ---
$BaseDir = "J:\replica_lab"
# Helper for Hashing
function Get-MD5($c) { 
    if ($null -eq $c) { return "37a6259cc0c1dae299a7866489dff0bd" }
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($c.ToString())
    return [BitConverter]::ToString($md5.ComputeHash($bytes)).Replace("-", "").ToLower() 
}

# Load Classes
. "$BaseDir\src\Core\RosettaStone.ps1"
. "$BaseDir\src\Core\CanonicalModel.ps1"
. "$BaseDir\src\Importers\ImporterV2.ps1"
. "$BaseDir\src\Drivers\DriverV3.ps1"

# --- 2. TEST DATA ---
$testDoc = [MvDocument]::new()
$testDoc.Name = "Teste Clinico Forense"
$testDoc.Id = 9999
$testDoc.Version = 1
$testDoc.CreatedBy = "SES50002"

# SQL Field (Sanctity Test)
$fSql = [MvField]::new()
$fSql.Name = "Ação SQL Especial"
$fSql.Identifier = "acao_sql_especial"
$fSql.SetTypeFromLegacy(1)
$fSql.SetProperty("acaoSql", "&<PAR_CD_ATENDIMENTO>")
$testDoc.AddField($fSql)

# Boolean Field (Hash Table Test)
$fBool = [MvField]::new()
$fBool.Name = "Obrigatorio"
$fBool.Identifier = "obrigatorio"
$fBool.SetTypeFromLegacy(4)
$fBool.SetProperty("obrigatorio", $true)
$testDoc.AddField($fBool)

# --- 3. EXECUTION ---
Write-Host ">>> PHASE 11 VERIFICATION START <<<" -ForegroundColor Cyan

$outV3 = "$BaseDir\20_outputs\fire_test_v12.json"
$dv3 = [DriverV3]::new($outV3)
$dv3.Export($testDoc)

# --- 4. ASSERTIONS ---
Write-Host "`n>>> VALIDATING OUTPUT <<<" -ForegroundColor Cyan
$jsonRaw = Get-Content $outV3 -Raw
$jsonObj = $jsonRaw | ConvertFrom-Json

# 1. Sanitizer Check (UPPER_SNAKE_CASE)
$fIdent = $jsonObj.fields[0].identifier
if ($fIdent -eq "ACAO_SQL_ESPECIAL") {
    Write-Host "[OK] Sanitizer verified: ACAO_SQL_ESPECIAL" -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Sanitizer failed: $fIdent" -ForegroundColor Red
}

# 2. SQL No-Escape Check
if ($jsonRaw -match '&<PAR_CD_ATENDIMENTO>') {
    Write-Host "[OK] SQL Sanctity verified: &<PAR_... is raw." -ForegroundColor Green
}
else {
    Write-Host "[FAIL] SQL Sanctity failed: Escaped content detected." -ForegroundColor Red
}

# 3. Hybrid Hash Check (Static)
$boolProp = $jsonObj.fields[1].fieldPropertyValues | Where-Object { $_.property.identifier -eq 'obrigatorio' }
if ($boolProp.hash -eq "b326b5062b2f0e69046810717534cb09") {
    Write-Host "[OK] Static Hash verified (true -> b326...)." -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Static Hash failed: $($boolProp.hash)" -ForegroundColor Red
}

# 4. Version Seal Check (Global)
$layoutHash = Get-MD5($jsonObj.layouts[0].content)
if ($jsonObj.version.hash -eq $layoutHash) {
    Write-Host "[OK] Version Seal (Global Hash) verified." -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Version Seal failed." -ForegroundColor Red
}

# 5. Migrador® Exception
$testDoc.CreatedBy = "Migrador®"
$outMig = "$BaseDir\20_outputs\fire_test_v12_migrador.json"
$dv3m = [DriverV3]::new($outMig)
$dv3m.Export($testDoc)
$jsonMig = Get-Content $outMig -Raw | ConvertFrom-Json
$migPropHash = $jsonMig.fields[1].fieldPropertyValues[0].hash
if ($migPropHash -eq "d41d8cd98f00b204e9800998ecf8427e") {
    Write-Host "[OK] Migrador® Exception verified (Empty MD5 hash)." -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Migrador® Exception failed: $migPropHash" -ForegroundColor Red
}

Write-Host "`n>>> PHASE 11 COMPLETE <<<" -ForegroundColor Cyan
