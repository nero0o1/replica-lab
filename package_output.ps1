$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$OutputDir = "j:\replica_lab\sanitized_output"
$EditorVersion = "2025.1.0-RC9"

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir }

function Zip-Document($sourceJsonPath, $identifier) {
    $tempPackDir = Join-Path "j:\replica_lab" "temp_pack"
    if (Test-Path $tempPackDir) { Remove-Item -Recurse -Force $tempPackDir }
    New-Item -ItemType Directory -Path $tempPackDir
    
    # [REGRA DE COMPACTAÇÃO FLOW FORMS]
    # 1. Manifesto de Versão (Obrigatório)
    $versionFile = Join-Path $tempPackDir "1.editor.version.edt"
    [System.IO.File]::WriteAllText($versionFile, $EditorVersion, $Utf8NoBom)
    
    # 2. Payload Principal com prefixos de ordem de injeção
    $fileName = ""
    if ($identifier -like "*CABECALHO*" -or $sourceJsonPath -like "*header*") {
        $fileName = "3.headers_$identifier.edt"
    }
    elseif ($identifier -like "*RODAPE*" -or $sourceJsonPath -like "*footer*") {
        $fileName = "4.footers_$identifier.edt"
    }
    else {
        # O padrão para documentos é o prefixo 5.
        $fileName = "5.documents_$identifier.edt"
    }

    Copy-Item -Path $sourceJsonPath -Destination (Join-Path $tempPackDir $fileName)
    
    $destZip = Join-Path $OutputDir "$identifier.zip"
    if (Test-Path $destZip) { Remove-Item $destZip }
    
    # Compress all contents of temp_pack ensuring no .json extensions inside
    Compress-Archive -Path "$tempPackDir\*" -DestinationPath $destZip
    Write-Host "Created $destZip with Flow Forms signature (Version: $EditorVersion)"
}

# 1. APAC
$apacJson = "j:\replica_lab\temp_unzip_apac\document.json"
if (Test-Path $apacJson) {
    Zip-Document $apacJson "APAC_REV_2026"
}

# 2. AIH_SES
$aihJson = "j:\replica_lab\temp_unzip_aih_ses\document.json"
if (Test-Path $aihJson) {
    Zip-Document $aihJson "AIH_SES_REV_2026"
}

# 3. ficha_ambulatorial_1
$fichaJson = "j:\replica_lab\temp_unzip_ficha\document.json"
if (Test-Path $fichaJson) {
    Zip-Document $fichaJson "ficha_ambulatorial_1_REV_2026"
}

# 4. Header (Cabeçalho SES GO)
# Check for local files if temp dirs are missing
$headerFile = Get-ChildItem -Path "j:\replica_lab\temp_unzip_apac" -Filter "*CABECALHO_SES_GO*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
if ($headerFile) {
    Zip-Document $headerFile "CABECALHO_SES_GO_ANTIGRAVITY"
}
