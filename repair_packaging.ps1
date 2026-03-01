# repair_packaging.ps1
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$SourceDir = "j:\replica_lab\sanitized_output"
$OutputDir = "j:\replica_lab\flow_forms_ready"
$TempDir = "j:\replica_lab\temp_repack"
$EditorVersion = "2025.1.0-RC9"

# Helper function defined BEFORE usage
function Get-PayloadFile($Path) {
    # Look for .json first
    $file = Get-ChildItem -Path $Path -Filter "*.json" -File | Select-Object -First 1
    if ($null -eq $file) {
        # Look for ANYTHING that isn't a directory
        $file = Get-ChildItem -Path $Path -File | Select-Object -First 1
    }
    return $file
}

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force }
if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force }

$zips = Get-ChildItem -Path $SourceDir -Filter "*.zip"

foreach ($zip in $zips) {
    Write-Host "Processing $($zip.Name)..."
    $baseName = $zip.BaseName
    
    # 1. Expand existing zip
    $unzipDir = Join-Path $TempDir "$baseName-unzip"
    if (Test-Path $unzipDir) { Remove-Item -Recurse -Force $unzipDir }
    New-Item -ItemType Directory -Path $unzipDir
    Expand-Archive -Path $zip.FullName -DestinationPath $unzipDir -Force
    
    # 2. Prepare staging area for Flow Forms
    $staging = Join-Path $TempDir "$baseName-staging"
    if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
    New-Item -ItemType Directory -Path $staging
    
    # 3. Create 1.editor.version.edt
    $versionFile = Join-Path $staging "1.editor.version.edt"
    [System.IO.File]::WriteAllText($versionFile, $EditorVersion, $Utf8NoBom)
    
    # 4. Handle Payload
    $sourceFile = Get-PayloadFile $unzipDir
    if ($sourceFile) {
        $targetName = ""
        if ($baseName -like "*CABECALHO*") {
            $targetName = "3.headers_$baseName.edt"
        }
        elseif ($baseName -like "*RODAPE*") {
            $targetName = "4.footers_$baseName.edt"
        }
        else {
            $targetName = "5.documents_$baseName.edt"
        }
        
        Copy-Item -Path $sourceFile.FullName -Destination (Join-Path $staging $targetName)
        Write-Host "  Success: Repackaged $($sourceFile.Name) as $targetName"
    }
    else {
        Write-Host "  Error: No source file found in $($zip.Name)"
    }
    
    # 5. Compress
    $destZip = Join-Path $OutputDir "$baseName.zip"
    if (Test-Path $destZip) { Remove-Item $destZip }
    # Use -Confirm:$false to avoid prompts if any
    Compress-Archive -Path "$staging\*" -DestinationPath $destZip
    
    Write-Host "  Done: $baseName.zip"
}
