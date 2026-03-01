using module "j:\replica_lab\src\Core\CanonicalModel.ps1"
using module "j:\replica_lab\src\Core\RosettaStone.ps1"
using module "j:\replica_lab\src\Drivers\DriverV3.ps1"

# CONFIGURAÇÃO DE AMBIENTE ROLLOUT FIDELIDADE 100%
$ErrorActionPreference = "Stop"

# 1. SETUP DE DIRETÓRIOS
$identifier = "COMBO_REPLICA_V1"
$flatBuildPath = "j:\replica_lab\flat_build"
$outputPath = "j:\replica_lab\output"

if (Test-Path $flatBuildPath) { Remove-Item $flatBuildPath -Recurse -Force }
if (!(Test-Path $outputPath)) { New-Item -Path $outputPath -ItemType Directory -Force }
New-Item -Path $flatBuildPath -ItemType Directory -Force

# 2. MOCK DO DOCUMENTO (SITUADO CONFORME FORENSICS)
$doc = [MvDocument]::new()
$doc.Id = 999141 # ID Alto para evitar conflitos iniciais
$doc.Version = 999141
$doc.Name = "combo teste replica"
$doc.Identifier = "COMBO_REPLICA_V1"
$doc.Width = 900
$doc.Height = 2000

# Campo ComboBox (Fforense parity)
$field = [MvField]::new()
$field.Id = 3253
$field.SetIdentifier("COMBOBOX")
$field.TypeId = 3
$field.CreatedBy = "Antigravity"
$field.Style = @{ x = 647; y = 334; width = 80; height = 28; zIndex = 1 }
$field.AddProperty("lista_valores", @("Opção 1", "Opção 2"))
$field.AddProperty("obrigatorio", $true)
$field.AddProperty("cascata_regra", "true")
$field.AddProperty("editavel", "true")

$doc.AddField($field)

# 3. EXPORTAÇÃO (ISO-NAMING N3)
$driver = [DriverV3]::new()
$driver.Export($doc, "$flatBuildPath\5.documents.edt")

# 4. VERSÃO (ISO-NAMING - EDITOR III)
"2025.1.0-RC9" | Out-File -FilePath "$flatBuildPath\1.editor.version.edt" -NoNewline -Encoding ascii

# 5. GERAÇÃO DO ZIP PLANO (NO-FOLDERS)
$zipFile = "$outputPath\COMBO_TESTE0.zip"
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($flatBuildPath, $zipFile, [System.IO.Compression.CompressionLevel]::NoCompression, $false)

# 6. MÉTRICAS FINAIS
$size = (Get-Item $zipFile).Length
$hash = Get-FileHash $zipFile -Algorithm MD5

Write-Host "--- ROLLOUT FIDELIDADE CONCLUÍDO ---"
Write-Host "Arquivo: $($zipFile)"
Write-Host "Tamanho: $size bytes"
Write-Host "MD5 Final: $($hash.Hash)"
Write-Host "Estrutura: Matrioska Root -> ioFieldDTOS"
Write-Host "------------------------------------"
