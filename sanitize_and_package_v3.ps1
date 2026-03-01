# sanitize_and_package_v3.ps1
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Updated Source Dirs to point to the latest unzipped temp areas
$SourceDirs = @(
    "j:\replica_lab\temp_repack\APAC_REV_2026-unzip",
    "j:\replica_lab\temp_repack\AIH_SES_REV_2026-unzip",
    "j:\replica_lab\temp_repack\ficha_ambulatorial_1_REV_2026-unzip"
)

$OutputDir = "j:\replica_lab\flow_forms_ready"
$TempPackArea = "j:\replica_lab\temp_pack_v3"
$EditorVersion = "2025.1.0-RC9"

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force }

function Sanitize-For-Import($node) {
    if ($null -eq $node) { return }

    if ($node -is [System.Array]) {
        foreach ($item in $node) { Sanitize-For-Import $item }
        return
    }

    if ($node -isnot [System.Management.Automation.PSCustomObject]) { return }

    $props = $node.PSObject.Properties

    # [REGRA DE SANITIZAÇÃO DE EXPORTAÇÃO MV FLOW FORMS]
    
    # 1. Anular Chaves Primárias
    $pkFields = @("code", "documentId", "versionId", "layoutId", "id")
    foreach ($field in $pkFields) {
        if ($props[$field]) {
            $node.$field = $null
        }
    }

    # 2. Neutralizar Localização de Pasta
    if ($props["groupId"]) {
        $node.groupId = $null
    }
    if ($props["group"]) {
        # Check if it's a deep object or just a primitive
        if ($node.group -is [System.Management.Automation.PSCustomObject]) {
            if ($node.group.PSObject.Properties["id"]) {
                $node.group.id = $null
            }
        }
    }

    # 3. Sanitização de Metadados
    if ($props["propertyDocumentValues"]) {
        # Removing the whole block as requested to let Flow Forms reconstruct it
        $props.Remove("propertyDocumentValues")
    }

    # Recurse through all properties to find nested PKs (e.g. inside layouts or versions)
    foreach ($p in $props) {
        try {
            $val = $p.Value
            if ($val -is [System.Management.Automation.PSCustomObject] -or $val -is [System.Array]) {
                Sanitize-For-Import $val
            }
        }
        catch {}
    }
}

foreach ($dir in $SourceDirs) {
    if (-not (Test-Path $dir)) { 
        Write-Host "Warning: Directory not found $dir"
        continue 
    }
    
    $jsonFile = Join-Path $dir "document.json"
    if (-not (Test-Path $jsonFile)) { continue }
    
    Write-Host "Processing $jsonFile..."
    $content = Get-Content -Raw -LiteralPath $jsonFile | ConvertFrom-Json
    
    # Clean it
    Sanitize-For-Import $content
    
    # Use the folder name to derive the zip name for consistency
    $baseName = (Split-Path $dir -Leaf).Replace("-unzip", "")
    
    # Staging
    $staging = Join-Path $TempPackArea $baseName
    if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
    New-Item -ItemType Directory -Path $staging -Force
    
    # 1. Version Manifesto
    $versionFile = Join-Path $staging "1.editor.version.edt"
    [System.IO.File]::WriteAllText($versionFile, $EditorVersion, $Utf8NoBom)
    
    # 2. Payload
    $payloadFile = Join-Path $staging "5.documents_$baseName.edt"
    # depth 100 for deep MV structure
    $cleanJson = $content | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($payloadFile, $cleanJson, $Utf8NoBom)
    
    # Final ZIP
    $destZip = Join-Path $OutputDir "$baseName.zip"
    if (Test-Path $destZip) { Remove-Item $destZip }
    Compress-Archive -Path "$staging\*" -DestinationPath $destZip
    
    Write-Host "  ✅ Ready: $baseName.zip"
}
