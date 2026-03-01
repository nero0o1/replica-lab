
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Sanitize-Node($node) {
    if ($null -eq $node) { return }

    if ($node -is [System.Array]) {
        foreach ($item in $node) {
            Sanitize-Node $item
        }
        return
    }

    if ($node -isnot [System.Management.Automation.PSCustomObject]) { return }

    $props = $node.PSObject.Properties
    
    # Rule 3: Reset Persistence
    $resetFields = @("id", "uuid", "cdDocumento", "cdEditorDocumento")
    foreach ($field in $resetFields) {
        $p = $props[$field]
        if ($p) {
            $node.$field = $null
        }
    }

    # Rule 4: Remove legacy audit
    $removeFields = @("dtCriacao", "cdUsuarioCriacao")
    foreach ($field in $removeFields) {
        if ($props[$field]) {
            $props.Remove($field)
        }
    }

    # Rule 1: Normalização de Propriedades em propertyDocumentValues
    if ($props["propertyDocumentValues"]) {
        $pdv = $node.propertyDocumentValues
        if ($pdv -is [System.Array]) {
            foreach ($item in $pdv) {
                # Check if property object is missing or null
                if ($null -eq $item.property) {
                    if ($item.PSObject.Properties["cdPropriedade"]) {
                        $cd = $item.cdPropriedade
                        $item | Add-Member -MemberType NoteProperty -Name "property" -Value ([PSCustomObject]@{ id = $cd })
                    }
                }
                
                # Global Action: Injetar "imported": true em cada nó de propriedade
                if ($item.property -ne $null) {
                    if (-not $item.property.PSObject.Properties["imported"]) {
                        $item.property | Add-Member -MemberType NoteProperty -Name "imported" -Value $true
                    }
                    else {
                        $item.property.imported = $true
                    }
                }
            }
        }
    }

    # Rule 1: fieldPropertyValues (standard for fields inside version/layouts)
    if ($props["fieldPropertyValues"]) {
        $fpv = $node.fieldPropertyValues
        if ($fpv -is [System.Array]) {
            foreach ($item in $fpv) {
                if ($null -eq $item.property) {
                    if ($item.PSObject.Properties["cdPropriedade"]) {
                        $cd = $item.cdPropriedade
                        $item | Add-Member -MemberType NoteProperty -Name "property" -Value ([PSCustomObject]@{ id = $cd })
                    }
                }
                if ($item.property -ne $null) {
                    if (-not $item.property.PSObject.Properties["imported"]) {
                        $item.property | Add-Member -MemberType NoteProperty -Name "imported" -Value $true
                    }
                    else {
                        $item.property.imported = $true
                    }
                }
            }
        }
    }

    # Recurse through all properties
    foreach ($p in $props) {
        try {
            $val = $p.Value
            if ($val -is [System.Management.Automation.PSCustomObject] -or $val -is [System.Array]) {
                Sanitize-Node $val
            }
        }
        catch {
            # Some properties might be inaccessible
        }
    }
}

function Process-File($filePath) {
    try {
        Write-Host "Processing $filePath..."
        $content = Get-Content -Raw -LiteralPath $filePath
        if ([string]::IsNullOrWhiteSpace($content)) { 
            Write-Host "  Empty file skipped."
            return 
        }
        $json = $content | ConvertFrom-Json
        if ($null -eq $json) {
            Write-Host "  Failed to parse JSON."
            return
        }

        # Rule 2: Disambiguate identifiers
        $revIds = @("APAC", "AIH_SES", "ficha_ambulatorial_1")
        if ($json.identifier -in $revIds) {
            $json.identifier += "_REV_2026"
            Write-Host "  Renamed identifier to $($json.identifier)"
        }
        
        # Name rename (Cabeçalho SES GO)
        if ($json.name -like "*Cabeçalho SES GO*") {
            $json.name = "Cabeçalho SES GO (ANTIGRAVITY)"
            Write-Host "  Renamed name to $($json.name)"
        }

        # Also check inside data node if it exists (common for MV objects)
        if ($json.PSObject.Properties["data"]) {
            if ($json.data.identifier -in $revIds) {
                $json.data.identifier += "_REV_2026"
            }
            if ($json.data.name -like "*Cabeçalho SES GO*") {
                $json.data.name = "Cabeçalho SES GO (ANTIGRAVITY)"
            }
        }

        Sanitize-Node $json

        # Prepare Output Path
        $dir = [System.IO.Path]::GetDirectoryName($filePath)
        $outPath = $filePath
        
        # Rule 5: Atomic Packaging - rename to document.json if it's a DOC (or actually any leaf object)
        # But specifically the main document file should be document.json
        if ($json.type -eq "DOC") {
            $outPath = Join-Path $dir "document.json"
            Write-Host "  Targeting document.json"
        }

        # Convert back (PS 5.1 doesn't have -Depth for ConvertTo-Json but usually defaults to 2)
        # MV metadata can be very deep. We must use a technique to handle depth.
        # However, for now, let's try standard.
        $outJson = $json | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($outPath, $outJson, $Utf8NoBom)
        
        if ($outPath -ne $filePath) {
            Remove-Item -LiteralPath $filePath
        }
        Write-Host "  Success: $outPath"
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)"
    }
}

# START
$dirs = @("j:\replica_lab\temp_unzip_apac", "j:\replica_lab\temp_unzip_aih_ses", "j:\replica_lab\temp_unzip_ficha")

foreach ($d in $dirs) {
    if (Test-Path $d) {
        Get-ChildItem -Path $d -Filter "*.edt" | ForEach-Object { Process-File $_.FullName }
    }
}
