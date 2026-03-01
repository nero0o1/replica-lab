# CONFIGURAÇÃO DE AMBIENTE ROLLOUT PLANO (N3)
$ErrorActionPreference = "Stop"
Import-Module "j:\replica_lab\src\Core\CanonicalModel.ps1"
Import-Module "j:\replica_lab\src\Core\RosettaStone.ps1"
Import-Module "j:\replica_lab\src\Drivers\DriverV3.ps1"

# 1. SETUP DE DIRETÓRIOS
$identifier = "COMBO_TESTE0"
$flatBuildPath = "j:\replica_lab\flat_build"
$outputPath = "j:\replica_lab\output"

if (Test-Path $flatBuildPath) { Remove-Item $flatBuildPath -Recurse -Force }
if (!(Test-Path $outputPath)) { New-Item -Path $outputPath -ItemType Directory -Force }
New-Item -Path $flatBuildPath -ItemType Directory -Force

# 2. MOCK DO DOCUMENTO (COMBO_TESTE0)
$doc = [MvDocument]::new()
$doc.Name = "COMBO_TESTE0"
$doc.Identifier = "COMBO_TESTE0"

# Componente ComboBox (Fforense parity)
$field = [MvField]::new()
$field.Id = 3253
$field.SetIdentifier("COMBOBOX")
$field.TypeId = 3
$field.CreatedBy = "Antigravity"
$field.Style = @{ x = 647; y = 334; width = 80; height = 28; zIndex = 1 }
$field.AddProperty("lista_valores", @("Opção 1", "Opção 2"))
$doc.AddField($field)

# 3. EXPORTAÇÃO (ISO-NAMING)
$driver = [DriverV3]::new()
$driver.Export($doc, "$flatBuildPath\5.documents.edt")

# 4. VERSÃO (ISO-NAMING - EDITOR III)
"2025.1.0-RC9" | Out-File -FilePath "$flatBuildPath\1.editor.version.edt" -NoNewline -Encoding ascii

# 5. GERAÇÃO DO ZIP PLANO (NO-FOLDERS)
$zipFile = "$outputPath\$identifier.zip"
if (Test-Path $zipFile) { Remove-Item $zipFile -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
# $false no terceiro parâmetro de CreateFromDirectory garante a raiz plana (sem a pasta pai)
[System.IO.Compression.ZipFile]::CreateFromDirectory($flatBuildPath, $zipFile, [System.IO.Compression.CompressionLevel]::NoCompression, $false)

# 6. MÉTRICAS FINAIS
$size = (Get-Item $zipFile).Length
$hash = Get-FileHash $zipFile -Algorithm MD5

Write-Host "--- ROLLOUT PLANO CONCLUÍDO ---"
Write-Host "Arquivo: $($zipFile)"
Write-Host "Tamanho: $size bytes"
Write-Host "MD5 Final: $($hash.Hash)"
Write-Host "Estrutura: 1.version.edt, 5.documents.edt [PLANO]"
Write-Host "-------------------------------"
