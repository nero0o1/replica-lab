using module "j:\replica_lab\src\Core\CanonicalModel.ps1"
using module "j:\replica_lab\src\Core\RosettaStone_Clean.ps1"

Class DriverV3 {
    static [hashtable]$SecurityHashes = @{
        "true"  = "b326b5062b2f0e69046810717534cb09"
        "false" = "68934a3e9455fa72420237eb05902327"
        "null"  = "37a6259cc0c1dae299a7866489dff0bd"
        "empty" = "d41d8cd98f00b204e9800998ecf8427e"
    }
    [System.Collections.Generic.HashSet[string]]$UsedIdentifiers
    [System.Text.Encoding]$Utf8NoBom
    DriverV3() {
        $this.UsedIdentifiers = [System.Collections.Generic.HashSet[string]]::new()
        $this.Utf8NoBom = New-Object System.Text.UTF8Encoding $false
    }
    [void] Export([MvDocument]$doc, [string]$outputPath) {
        $this.UsedIdentifiers.Clear()
        $v3Doc = [ordered]@{
            "name"       = $doc.Name
            "identifier" = $this.GetUniqueAndSanitizedIdentifier($doc.Identifier)
            "type"       = "DOC"
            "group"      = $this.GetDocumentGroup()
            "data"       = $this.AssembleDocumentData($doc)
            "version"    = $this.AssembleVersionInfo($doc)
        }
        if ($v3Doc.version.layouts.Count -gt 0) {
            $layoutContent = $v3Doc.version.layouts[0].content
            $v3Doc.version.hash = $this.CalculateMd5($layoutContent, $null)
        }
        $jsonOutput = ConvertTo-Json $v3Doc -Depth 25
        $jsonOutput = $jsonOutput -replace '\\u0026', '&' -replace '\\u003c', '<' -replace '\\u003e', '>'
        $jsonOutput = $jsonOutput -replace '("(?:x|y|width|height)"):\s*(-?\\\d+)(?!\.)', '$1:$2.0'
        $jsonOutput = $jsonOutput -replace '("(?:x|y|width|height)"):\s*(-?\d+)(?!\.)', '$1:$2.0'
        [System.IO.File]::WriteAllText($outputPath, $jsonOutput, $this.Utf8NoBom)
    }
    [hashtable] GetDocumentGroup() {
        return [ordered]@{
            "id"           = 361 
            "name"         = "teste"
            "itemType"     = [RosettaStone]::ItemTypeMap['G_DOC']
            "keyTranslate" = $null
            "parentGroup"  = [ordered]@{
                "id"           = 95
                "name"         = "SES_Prontuario_integrado"
                "itemType"     = [RosettaStone]::ItemTypeMap['G_REP_DOC']
                "keyTranslate" = $null
                "parentGroup"  = [ordered]@{
                    "id"           = 11
                    "name"         = "RepositÃ³rio Local"
                    "itemType"     = [RosettaStone]::ItemTypeMap['R_REP_DOC']
                    "keyTranslate" = $null
                    "parentGroup"  = $null
                    "editable"     = $false
                }
                "editable"     = $true
            }
            "editable"     = $true
        }
    }
    [hashtable] AssembleDocumentData([MvDocument]$doc) {
        return [ordered]@{
            "id"                     = $doc.Id
            "identifier"             = $doc.Identifier
            "name"                   = $doc.Name
            "itemType"               = [RosettaStone]::ItemTypeMap['DOC']
            "propertyDocumentValues" = @() 
            "active"                 = $true
            "groupId"                = 361
        }
    }
    [hashtable] AssembleVersionInfo([MvDocument]$doc) {
        return [ordered]@{
            "id"                  = $doc.Id
            "versionStatus"       = "PUBLISHED"
            "vlVersion"           = 1
            "active"              = $true
            "published"           = $true
            "documentId"          = $doc.Id
            "documentIdentifier"  = $doc.Identifier
            "documentName"        = $doc.Name
            "documentProperties"  = $null
            "layoutPropertiesDTO" = $null
            "hash"                = $null
            "layouts"             = $this.SerializeLayouts($doc)
        }
    }
    [System.Collections.ArrayList] SerializeLayouts([MvDocument]$doc) {
        $layouts = [System.Collections.ArrayList]::new()
        $uiStructure = [ordered]@{
            "pageBody" = [ordered]@{
                "children" = $this.AssembleVisualMap($doc.Fields)
                "style"    = [ordered]@{ "border" = "none"; "width" = $doc.Width; "height" = $doc.Height }
                "type"     = "pageBody"
            }
        }
        $layoutContent = ConvertTo-Json $uiStructure -Depth 20 -Compress
        $layoutContent = $layoutContent -replace '("(?:x|y|width|height)"):\s*(-?\d+)(?!\.)', '$1:$2.0'
        [void]$layouts.Add([ordered]@{
                "description"              = $null
                "width"                    = $doc.Width
                "height"                   = $doc.Height
                "versionId"                = $doc.Id
                "content"                  = $layoutContent
                "layoutType"               = [ordered]@{ "id" = 1; "identifier" = "TELA"; "name" = "Tela" }
                "rules"                    = @() 
                "documentFooterIdentifier" = $null
                "documentHeaderIdentifier" = $null
                "ioFieldDTOS"              = $this.SerializeIoFields($doc.Fields)
            })
        return $layouts
    }
    [System.Collections.ArrayList] SerializeIoFields([System.Collections.Generic.List[MvField]]$fields) {
        $list = [System.Collections.ArrayList]::new()
        foreach ($f in $fields) {
            $v3Type = [RosettaStone]::GetVisualType($f.TypeId)
            $fObj = [ordered]@{
                "reprocessed"           = $false
                "active"                = $true
                "fieldParentId"         = 6 
                "fieldParentIdentifier" = "G_CAM"
                "name"                  = $f.Identifier
                "identifier"            = $f.Identifier
                "groupId"               = 6
                "hash"                  = $null 
                "id"                    = $f.Id
                "itemType"              = [RosettaStone]::ItemTypeMap['CAM']
                "visualizationType"     = [ordered]@{ 
                    "id"          = $v3Type.id_v3; 
                    "identifier"  = $v3Type.name.ToUpper();
                    "description" = $v3Type.label 
                }
                "fieldPropertyValues"   = $this.AssembleFieldPropertyValues($f)
                "fieldValueDTOS"        = $null
                "defaultTexts"          = $null
            }
            [void]$list.Add($fObj)
        }
        return $list
    }
    [System.Collections.ArrayList] AssembleFieldPropertyValues([MvField]$f) {
        $list = [System.Collections.ArrayList]::new()
        $propCounter = 10000 + ($f.Id % 1000)
        foreach ($propKey in $f.Properties.Keys) {
            $propId = [RosettaStone]::GetPropertyId($propKey)
            $meta = [RosettaStone]::GetPropertyMetadata($propId)
            $val = $f.Properties[$propKey]
            $propObj = [ordered]@{ 
                "id"       = $propCounter++
                "property" = [ordered]@{ 
                    "id"           = $propId
                    "identifier"   = $propKey
                    "description"  = if ($meta) { $meta.desc } else { $propKey }
                    "defaultValue" = $null
                    "keyTranslate" = if ($meta) { $meta.key } else { $null }
                } 
            }
            if ($propKey -eq "lista_valores" -and $val -is [array]) {
                $propObj.Add("fieldValues", $val)
                $propObj.Add("hash", $null)
            }
            else {
                $strValue = if ($null -eq $val) { $null }
                elseif ($val -is [bool]) { $val.ToString().ToLower() }
                else { $val.ToString() }
                $propObj.Add("value", $strValue)
                $propObj.Add("hash", $this.CalculateFieldHash($strValue, $f))
            }
            [void]$list.Add($propObj)
        }
        return $list
    }
    [hashtable] AssembleVisualMap([System.Collections.Generic.List[MvField]]$fields) {
        $map = [ordered]@{ }
        foreach ($f in $fields) {
            $v3Type = [RosettaStone]::GetVisualType($f.TypeId)
            $isLabel = ($v3Type.name -eq 'label')
            $inst = [ordered]@{
                "metadado"          = $f.Id
                "identifier"        = $f.Identifier
                "visualization"     = $v3Type.label
                "type"              = $v3Type.name
                "visualizationType" = $v3Type.name
                "name"              = $f.Identifier.ToLower()
                "style"             = [ordered]@{
                    "fontFamily" = "Arial"
                    "fontSize"   = "12px"
                    "color"      = "#000"
                    "lineHeight" = if ($isLabel) { 1.5 } else { 1.0 }
                    "zIndex"     = if ($f.Style.zIndex) { [int]$f.Style.zIndex } else { 1 }
                }
                "x"                 = [float]$f.Style.x
                "y"                 = [float]$f.Style.y
                "width"             = [float]$f.Style.width
                "height"            = [float]$f.Style.height
                "id"                = $f.Identifier
            }
            $map["$($f.Identifier)"] = $inst
        }
        return $map
    }
    [string] CalculateFieldHash([string]$text,[MvField]$field) {
        if ($field -and $field.CreatedBy -eq 'MigradorÂ®') { return [DriverV3]::SecurityHashes["empty"] }
        if ($null -eq $text) { return [DriverV3]::SecurityHashes["null"] }
        if ($text -eq "") { return [DriverV3]::SecurityHashes["empty"] }
        $lookupKey = $text.ToLower()
        if ($lookupKey -eq "true" -or $lookupKey -eq "false") { return [DriverV3]::SecurityHashes[$lookupKey] }
        $md5 = [System.Security.Cryptography.MD5]::Create()
        try {
            $bytes = $this.Utf8NoBom.GetBytes($text)
            $hashBytes = $md5.ComputeHash($bytes)
            $sb = [System.Text.StringBuilder]::new()
            foreach ($b in $hashBytes) { [void]$sb.AppendFormat("{0:x2}", $b) }
            return $sb.ToString()
        }
        finally { $md5.Dispose() }
    }
    [string] CalculateMd5([string]$text, [MvField]$field) {
        if ($null -eq $text) { return $null }
        return $this.CalculateFieldHash($text, $field)
    }
    [string] GetUniqueAndSanitizedIdentifier([string]$rawId) {
        $base = $this.SanitizeToUpperSnakeCase($rawId)
        $final = $base; $counter = 1
        while ($this.UsedIdentifiers.Contains($final)) {
            $final = "${base}_$counter"; $counter++
        }
        [void]$this.UsedIdentifiers.Add($final)
        return $final
    }
    [string] SanitizeToUpperSnakeCase([string]$textVal) {
        if ([string]::IsNullOrWhiteSpace($textVal)) { return "UNTITLED" }
        $normalized = $textVal.Normalize([System.Text.NormalizationForm]::FormD)
        $sbString = [System.Text.StringBuilder]::new()
        foreach ($c in $normalized.ToCharArray()) {
            if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
                [void]$sbString.Append($c)
            }
        }
        $cleanString = $sbString.ToString().ToUpper() -replace '[^A-Z0-9]', '_' -replace '_+', '_'
        return $cleanString.Trim('_')
    }
}
