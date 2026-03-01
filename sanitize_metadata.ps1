
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
        if ($props[$field]) {
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

    # Rule 1: propertyDocumentValues
    if ($props["propertyDocumentValues"]) {
        $pdv = $node.propertyDocumentValues
        if ($pdv -is [System.Array]) {
            foreach ($item in $pdv) {
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

    # Rule 1: fieldPropertyValues
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

    # Recurse
    foreach ($p in $props) {
        try {
            $val = $p.Value
            if ($val -is [System.Management.Automation.PSCustomObject] -or $val -is [System.Array]) {
                Sanitize-Node $val
            }
        }
        catch {}
    }
}

function Process-File($filePath) {
    try {
        Write-Host "Processing $filePath..."
        $content = Get-Content -Raw -LiteralPath $filePath
        if ([string]::IsNullOrWhiteSpace($content)) { return }
        $json = $content | ConvertFrom-Json -Depth 100

        # Rule 2
        $revIds = @("APAC", "AIH_SES", "ficha_ambulatorial_1")
        if ($json.identifier -in $revIds) {
            $json.identifier += "_REV_2026"
        }
        if ($json.name -like "*Cabeçalho SES GO*") {
            $json.name = "Cabeçalho SES GO (ANTIGRAVITY)"
        }
        if ($json.PSObject.Properties["data"]) {
            if ($json.data.identifier -in $revIds) {
                $json.data.identifier += "_REV_2026"
            }
            if ($json.data.name -like "*Cabeçalho SES GO*") {
                $json.data.name = "Cabeçalho SES GO (ANTIGRAVITY)"
            }
        }

        Sanitize-Node $json

        $dir = [System.IO.Path]::GetDirectoryName($filePath)
        $outPath = $filePath
        if ($json.type -eq "DOC") {
            $outPath = Join-Path $dir "document.json"
        }

        $outJson = $json | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($outPath, $outJson, $Utf8NoBom)
        
        if ($outPath -ne $filePath) {
            Remove-Item -LiteralPath $filePath
        }
        Write-Host "  Success: $outPath"
    }
    catch {
        $err = $_.ToString()
        Write-Host "  Error processing $filePath : $err"
    }
}

# START
$dirs = @("j:\replica_lab\temp_unzip_apac", "j:\replica_lab\temp_unzip_aih_ses", "j:\replica_lab\temp_unzip_ficha")
foreach ($d in $dirs) {
    if (Test-Path $d) {
        $files = Get-ChildItem -Path $d -Filter "*.edt"
        foreach ($f in $files) {
            Process-File $f.FullName
        }
    }
}
