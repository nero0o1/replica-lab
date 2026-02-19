# Test Driver V3
$BasePath = "J:\replica_lab"
$OutFile = Join-Path $BasePath "20_outputs\test_v3_output.edt"

# 1. Load Core & Driver
. (Join-Path $BasePath "src\Core\RosettaStone.ps1")
. (Join-Path $BasePath "src\Core\CanonicalModel.ps1")
. (Join-Path $BasePath "src\Drivers\DriverV3.ps1")

# 2. Build Canonical Form
Write-Host "Building Canonical Form..."
try {
    $form = [CanonicalForm]::new("Teste Clinico", "TST_CLINICO_01")
    Write-Host "Form Created."

    # Field 1: TXT_NOME (Obrigatorio)
    Write-Host "Creating TXT_NOME..."
    $f1 = [CanonicalField]::new("TXT_NOME")
    Write-Host "Adding Property 8..."
    $f1.AddProperty(8, $true) # Obrigatorio = True
    Write-Host "Adding Property 1..."
    $f1.AddProperty(1, 50)    # Tamanho = 50
    $form.AddField($f1)
}
catch {
    Write-Error "Failed building form: $_"
    exit 1
}

# Field 2: CBB_SEXO (Com Lista)
$f2 = [CanonicalField]::new("CBB_SEXO")
$lista = @(
    @{ "label" = "Masculino"; "value" = "M" },
    @{ "label" = "Feminino"; "value" = "F" }
)
# ID 2 = Lista de Valores (Array)
$f2.AddProperty(2, $lista)
$form.AddField($f2)

# 3. Export
Write-Host "Exporting to $OutFile..."
[DriverV3]::Export($form, $OutFile)

# 4. Verify
if (Test-Path $OutFile) {
    Write-Host "File Created!" -ForegroundColor Green
    $content = Get-Content $OutFile -Raw
    $json = ConvertFrom-Json $content
    
    # Check Hash
    $hash = $json.version.hash
    Write-Host "Version Hash: $hash"
    
    if (-not $hash) { throw "Hash is Missing!" }
    if ($hash.Length -ne 32) { throw "Hash looks invalid (len!=32)" }
    
    # Check Property Hash
    $propHash = $json.data.propertyDocumentValues[0].propertyValues[0].hash
    Write-Host "Property Hash (Boolean): $propHash"
    if (-not $propHash) { throw "Property Hash Missing" }

    # Check Array
    $arr = $json.data.propertyDocumentValues[1].propertyValues[0].value
    Write-Host "Array Elements: $($arr.Count)"
    if ($arr.Count -ne 2) { throw "Array serialization fail" }
    
}
else {
    throw "File NOT created."
}
