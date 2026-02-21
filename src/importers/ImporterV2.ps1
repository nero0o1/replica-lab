# using module "..\Core\CanonicalModel.ps1"
# using module "..\Core\RosettaStone.ps1"

class ImporterV2 {
    [string] $InputPath

    ImporterV2([string]$inputPath) {
        $this.InputPath = $inputPath
    }

    [object] Import() {
        if (-not (Test-Path $this.InputPath)) {
            throw "File not found: $($this.InputPath)"
        }
        # 0. Java Breaker: Binary Scrubbing (Jasper Serialization ACED0005)
        $bytes = [System.IO.File]::ReadAllBytes($this.InputPath)
        $content = ""
        
        # Java Magic Number: AC ED 00 05
        if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xAC -and $bytes[1] -eq 0xED -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x05) {
            Write-Host "Java Breaker Protocol: ACED0005 detected." -ForegroundColor Yellow
            
            # Step 1: Find XML chunks (<editor>...)
            $stringStream = [System.Text.Encoding]::UTF8.GetString($bytes)
            $xmlStart = $stringStream.IndexOf("<editor")
            if ($xmlStart -ge 0) {
                $content = $stringStream.Substring($xmlStart)
            }
            else {
                # Heuristic: Search for Jasper specific tags if <editor> is missing
                $jasperStart = $stringStream.IndexOf("<text")
                if ($jasperStart -ge 0) { $content = $stringStream.Substring($jasperStart) }
                else { throw "Java Breaker Error: ACED0005 header present but no usable XML markers found." }
            }

            # Step 2: Scrub for Image Blobs (JPG/PNG) - TODO: Implement in detail if specific blobs needed
            # For now, we rely on the XML scrub which usually contains the truth.
        }
        else {
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        }

        # Load XML
        [xml]$xml = [xml]$content

        $doc = [MvDocument]::new()
        
        # 1. Parse Document Identity
        $docItem = $xml.editor.item | Where-Object { $_.tableName -eq 'EDITOR_DOCUMENTO' }
        if (-not $docItem) { throw "Invalid V2 XML: Missing EDITOR_DOCUMENTO" }

        $docRow = $docItem.data.ROWSET.ROW
        $doc.Id = [int]$docRow.CD_DOCUMENTO
        $doc.Name = $docRow.DS_DOCUMENTO
        $doc.Identifier = [MvDocument]::SanitizeIdentifier($doc.Name)
        $doc.CreatedBy = $docRow.CD_USUARIO_CRIACAO # Extract User
        
        # 2. Parse Version Info
        $versionItem = $docItem.children.association | Where-Object { $_.childTableName -eq 'EDITOR_VERSAO_DOCUMENTO' } | Select-Object -ExpandProperty item
        if ($versionItem) {
            $verRow = $versionItem.data.ROWSET.ROW
            $doc.Version = [int]$verRow.VL_VERSAO
            $doc.Active = ($verRow.SN_ATIVO -eq 'S')
            
            # 3. Parse Fields (via Layout)
            $layoutItem = $versionItem.children.association | Where-Object { $_.childTableName -eq 'EDITOR_LAYOUT' } | Select-Object -ExpandProperty item
            if ($layoutItem) {
                $layoutCampoAssocList = @($layoutItem.children.association | Where-Object { $_.childTableName -eq 'EDITOR_LAYOUT_CAMPO' })
                foreach ($layoutCampoAssoc in $layoutCampoAssocList) {
                    if ($null -ne $layoutCampoAssoc.item) {
                        foreach ($layoutCampoItem in $layoutCampoAssoc.item) {
                            $this.ParseField($doc, $layoutCampoItem)
                        }
                    }
                }
            }
        }

        return $doc
    }

    [void] ParseField($doc, [System.Xml.XmlElement]$layoutItem) {
        $layoutRow = $layoutItem.data.ROWSET.ROW
        $fieldAssoc = $layoutItem.children.association | Where-Object { $_.childTableName -eq 'EDITOR_CAMPO' }
        if (-not $fieldAssoc) { return }
        
        $fieldItem = $fieldAssoc.item
        $fieldRow = $fieldItem.data.ROWSET.ROW
        
        $f = [MvField]::new()
        $f.IdLegacy = [int]$fieldRow.CD_CAMPO
        $f.Name = $fieldRow.DS_CAMPO
        # Law: UPPER_SNAKE_CASE Sanitization
        $f.Identifier = [MvDocument]::SanitizeIdentifier($fieldRow.DS_IDENTIFICADOR)
        if ([string]::IsNullOrWhiteSpace($f.Identifier)) { $f.Identifier = [MvDocument]::SanitizeIdentifier($f.Name) }
        
        $f.SetTypeFromLegacy([int]$fieldRow.CD_TIPO_VISUALIZACAO)

        $f.X = [int]$layoutRow.NR_COLUNA
        $f.Y = [int]$layoutRow.NR_LINHA
        $f.Width = [int]$layoutRow.NR_LARGURA
        $f.Height = [int]$layoutRow.NR_ALTURA
        
        $propAssoc = $fieldItem.children.association | Where-Object { $_.childTableName -eq 'EDITOR_CAMPO_PROP_VAL' }
        if ($propAssoc) {
            foreach ($propItem in $propAssoc.item) {
                $propRow = $propItem.data.ROWSET.ROW
                # Scrub for type mismatch
                if ($null -ne $propRow.CD_TIPO_VISUALIZACAO -and [int]$propRow.CD_TIPO_VISUALIZACAO -ne $f.TypeIdLegacy) { continue }
                
                $propId = [int]$propRow.CD_PROPRIEDADE
                $propIdentifier = [RosettaStone]::GetIdentifier($propId)
                $targetType = [RosettaStone]::GetType($propId)
                $typedVal = $this.ConvertValueFromV2($propRow.LO_VALOR, $targetType)
                
                $f.SetProperty($propIdentifier, $typedVal)
            }
        }
        $doc.AddField($f)
    }

    [object] ConvertValueFromV2([string]$val, [string]$targetType) {
        if ([string]::IsNullOrWhiteSpace($val)) { return $null }
        switch ($targetType) {
            "Boolean" { return ($val -eq 'S' -or $val -eq 's' -or $val -eq 'true' -or $val -eq 'True') }
            "Integer" { return [int]$val }
            "Date" { return [DateTime]::ParseExact($val, @("dd/MM/yy", "dd/MM/yyyy"), [System.Globalization.CultureInfo]::InvariantCulture) }
            "Array" { return $val }
            Default { return $val }
        }
    }
}
