# CONFIGURAÇÃO DE AMBIENTE
$ErrorActionPreference = "Stop"
Import-Module "j:\replica_lab\src\Core\CanonicalModel.ps1"
Import-Module "j:\replica_lab\src\Core\RosettaStone.ps1"
Import-Module "j:\replica_lab\src\Drivers\DriverV3.ps1"

# 1. CLEANUP WORKDIR
$identifier = "COMBO_TESTE0"
$buildPath = "j:\replica_lab\temp_build"
$outputPath = "j:\replica_lab\output"

if (Test-Path $buildPath) { Remove-Item -Path $buildPath -Recurse -Force }
if (!(Test-Path $outputPath)) { New-Item -Path $outputPath -ItemType Directory -Force }

New-Item -Path "$buildPath\documents", "$buildPath\editor_versao", "$buildPath\headers", "$buildPath\footers" -ItemType Directory -Force

# 2. INSTANCIAÇÃO DO MODELO CANÔNICO (MOCK COMBO_TESTE0)
$doc = [MvDocument]::new()
$doc.Name = "COMBO_TESTE0"
$doc.Identifier = "COMBO_TESTE0"
$doc.Width = 800
$doc.Height = 1100

# Adicionando o ComboBox da amostra forense
$field = [MvField]::new()
$field.Id = 3253
$field.SetIdentifier("COMBOBOX")
$field.TypeId = 3 # ID V2 para ComboBox
$field.CreatedBy = "Antigravity"
$field.Style = @{
    x      = 647
    y      = 334
    width  = 80
    height = 28
    zIndex = 1
}
$field.AddProperty("lista_valores", @("Opção 1", "Opção 2"))
$field.AddProperty("editavel", $true)

$doc.AddField($field)

# 3. EXECUÇÃO DO DRIVER V3
$driver = [DriverV3]::new()
$jsonTarget = "$buildPath\documents\$($doc.Identifier).json"
$driver.Export($doc, $jsonTarget)

# 4. MATERIALIZAÇÃO DO VERSION.EDT (Sincronia Forense)
"2025.1.0-RC9" | Out-File -FilePath "$buildPath\editor_versao\version.edt" -NoNewline -Encoding ascii

# 5. EMPACOTAMENTO RELATIVO (ZIP NA RAIZ)
$zipFile = "$outputPath\$($doc.Identifier).zip"
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($buildPath, $zipFile, [System.IO.Compression.CompressionLevel]::NoCompression, $false)

# 6. LOG DE CONCLUSÃO E HASH
$fileSize = (Get-Item $zipFile).Length
$md5 = [System.Security.Cryptography.MD5]::Create()
$bytes = [System.IO.File]::ReadAllBytes($zipFile)
$hashBytes = $md5.ComputeHash($bytes)
$sb = [System.Text.StringBuilder]::new()
foreach ($b in $hashBytes) { [void]$sb.Append($b.ToString("x2")) }
$globalHash = $sb.ToString()

Write-Host "--- LOG DE CONCLUSÃO REPLICA ---"
Write-Host "Documento: $($doc.Identifier)"
Write-Host "Tamanho: $fileSize bytes"
Write-Host "MD5 Global: $globalHash"
Write-Host "Caminho: $zipFile"
Write-Host "--------------------------------"
