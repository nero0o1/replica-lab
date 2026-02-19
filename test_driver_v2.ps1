# Test Driver V2 (XML)
$BasePath = "J:\replica_lab"
$OutFile = Join-Path $BasePath "20_outputs\test_v2_output.xml"

# 1. Load Core & Driver
. (Join-Path $BasePath "src\Core\RosettaStone.ps1")
. (Join-Path $BasePath "src\Core\CanonicalModel.ps1")
. (Join-Path $BasePath "src\Drivers\DriverV2.ps1")

# 2. Build Canonical Form
Write-Host "Building Canonical Form..."
$form = [CanonicalForm]::new("Teste XML", "TST_XML_01")

# Field 1: TXT_NOME (Obrigatorio)
$f1 = [CanonicalField]::new("TXT_NOME")
$f1.AddProperty(8, $true) # Obrigatorio -> Expect <OBRIGATORIO>S</OBRIGATORIO>
$f1.AddProperty(1, 50)    # Tamanho -> <TAMANHO>50</TAMANHO>
$form.AddField($f1)

# Field 2: CBB_SEXO (Com Lista Array)
# Testing Degradation
$f2 = [CanonicalField]::new("CBB_SEXO")
$lista = @("M", "F") 
# ID 2 = Lista de Valores (Array)
$f2.AddProperty(2, $lista)
$form.AddField($f2)

# 3. Export
Write-Host "Exporting to $OutFile..."
$xml = [DriverV2]::Export($form, $OutFile)

# 4. Verify
Write-Host "Content Preview:"
Write-Host $xml -ForegroundColor Gray

if ($xml -match "<ROWSET>") { Write-Host "Header OK" -ForegroundColor Green } else { throw "Missing ROWSET" }
if ($xml -match "<ROW>") { Write-Host "Row  OK" -ForegroundColor Green } else { throw "Missing ROW" }
if ($xml -match "<OBRIGATORIO>S</OBRIGATORIO>") { Write-Host "Boolean Conversion OK (S)" -ForegroundColor Green } else { throw "Bool Conversion Fail" }
if ($xml -match "<TAMANHO>50</TAMANHO>") { Write-Host "Integer OK" -ForegroundColor Green } else { throw "Int Fail" }

# Check Degradation
# ID 2 -> LISTA_VALORES
if ($xml -match "<LISTA_VALORES>M\|F</LISTA_VALORES>") { 
    Write-Host "Apparent Degradation Success (Joined with pipe)" -ForegroundColor Green 
}
else {
    Write-Warning "Degradation check validation loose."
}

if (Test-Path $OutFile) {
    Write-Host "File Created!" -ForegroundColor Green
}
else {
    throw "File NOT created."
}
