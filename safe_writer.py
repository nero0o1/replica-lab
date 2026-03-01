import os

rosetta_stone = r"""<#
    .SYNOPSIS
    ROSETTA STONE - O Ponto Único de Verdade da Camada Semântica.
    Fase 1: Soberania da Camada Core.
#>

Class RosettaStone {
    static [hashtable] $PropertyMap = @{
        1  = @{ name = 'tamanho'; desc = 'Tamanho'; key = 'document.property.size' }
        2  = @{ name = 'lista_valores'; desc = 'Lista de valores'; key = 'document.property.value.list' }
        3  = @{ name = 'mascara'; desc = 'Máscara'; key = 'document.property.mask' }
        4  = @{ name = 'acao'; desc = 'Ação'; key = 'document.property.action' }
        5  = @{ name = 'usado_em'; desc = 'Usado Em'; key = 'document.property.used.in' }
        7  = @{ name = 'editavel'; desc = 'Editável'; key = 'document.property.editable' }
        8  = @{ name = 'obrigatorio'; desc = 'Obrigatório'; key = 'document.property.required' }
        9  = @{ name = 'valor_inicial'; desc = 'Valor Inicial'; key = 'document.property.initial.value' }
        10 = @{ name = 'criado_por'; desc = 'Criado Por'; key = 'document.property.created.by' }
        13 = @{ name = 'acao_texto_padrao'; desc = 'Ação de texto padrão'; key = 'document.property.default.text.action' }
        14 = @{ name = 'texto_padrao'; desc = 'Texto padrão'; key = 'document.property.default.text' }
        15 = @{ name = 'parametros_texto_padrao'; desc = 'Parâmetros de texto padrão'; key = 'document.property.default.text.parameters' }
        17 = @{ name = 'reprocessar'; desc = 'Reprocessar ação'; key = 'document.property.reprocessed.action' }
        19 = @{ name = 'barcode_type'; desc = 'Tipo de código de barras'; key = 'document.property.barcode.type' }
        20 = @{ name = 'show_barcode_label'; desc = 'Mostrar descrição de código de barras'; key = 'document.property.show.barcode.label' }
        21 = @{ name = 'acao_sql'; desc = 'Ação SQL'; key = 'document.property.sql.action' }
        22 = @{ name = 'regras_usadas'; desc = 'Regra(s)'; key = 'document.property.rules' }
        24 = @{ name = 'criado_em'; desc = 'Criado Em'; key = 'document.property.created.in' }
        25 = @{ name = 'ultima_publicacao_por'; desc = 'Última Publicação Por'; key = 'document.property.last.post.by' }
        26 = @{ name = 'publicado_em'; desc = 'Publicado Em'; key = 'document.property.publicated.in' }
        29 = @{ name = 'expor_para_api'; desc = 'Expor para API'; key = 'document.property.export.api' }
        30 = @{ name = 'hint'; desc = 'Hint'; key = 'document.property.hiny' }
        31 = @{ name = 'descricao_api'; desc = 'Descrição API'; key = 'document.property.description.api' }
        33 = @{ name = 'importado'; desc = 'Importado'; key = 'document.property.imported' }
        34 = @{ name = 'migrado'; desc = 'Migrado'; key = 'document.property.migrated' }
        36 = @{ name = 'requisicao_api'; desc = 'Requisição API'; key = 'document.property.request.api' }
        38 = @{ name = 'cascata_regra'; desc = 'Cascatear regra'; key = 'document.property.rule.cascade' }
        43 = @{ name = 'executar_regra_campo_oculto'; desc = 'Executar regra com campo oculto'; key = 'document.property.execute.rule.hidden.field' }
    }
    static [hashtable] $ItemTypeMap = @{
        'DOC'       = @{ id = 13; identifier = 'DOC'; description = 'Documento'; permissionModifyGroup = $true }
        'CAM'       = @{ id = 8; identifier = 'CAM'; description = 'Campo'; permissionModifyGroup = $true }
        'G_DOC'     = @{ id = 29; identifier = 'G_DOC'; description = 'Grupo dos Documentos'; permissionModifyGroup = $true }
        'G_REP_DOC' = @{ id = 10; identifier = 'G_REP_DOC'; description = 'Grupo dos Repositório dos Documentos'; permissionModifyGroup = $true }
        'R_REP_DOC' = @{ id = 9; identifier = 'R_REP_DOC'; description = 'Raiz dos Repositórios dos Documentos'; permissionModifyGroup = $false }
        'G_CAM'     = @{ id = 6; identifier = 'G_CAM'; description = 'Grupo dos Campos'; permissionModifyGroup = $true }
        'R_REP_CAM' = @{ id = 3; identifier = 'R_REP_CAM'; description = 'Raiz dos Repositórios dos Campos'; permissionModifyGroup = $false }
    }
    static [hashtable] $GroupMap = @{
        'R_REP_CAM' = 1
        'G_CAM'     = 6
        'G_DOC'     = 361
    }
    static [hashtable] $VisualTypeMap = @{
        1  = @{ name = 'text'; id_v3 = 1; label = 'Texto' }
        2  = @{ name = 'textarea'; id_v3 = 2; label = 'Caixa de Texto' }
        3  = @{ name = 'combobox'; id_v3 = 3; label = 'ComboBox' }
        4  = @{ name = 'checkbox'; id_v3 = 4; label = 'CheckBox' }
        7  = @{ name = 'radiobutton'; id_v3 = 6; label = 'Radio Button' }
        10 = @{ name = 'button'; id_v3 = 7; label = 'Botão' }
        11 = @{ name = 'date'; id_v3 = 9; label = 'Data' }
        12 = @{ name = 'image'; id_v3 = 10; label = 'Imagem' }
        14 = @{ name = 'label'; id_v3 = 2; label = 'Label' } 
        35 = @{ name = 'grid'; id_v3 = 35; label = 'Tabela Interativa' }
    }
    static [string] GetPropertyName([int]$id) {
        if ([RosettaStone]::PropertyMap.ContainsKey($id)) { return [RosettaStone]::PropertyMap[$id].name }
        return "PROP_UNKNOWN_$id"
    }
    static [hashtable] GetPropertyMetadata([int]$id) {
        if ([RosettaStone]::PropertyMap.ContainsKey($id)) { return [RosettaStone]::PropertyMap[$id] }
        return $null
    }
    static [hashtable] GetVisualType([int]$idV2) {
        if ([RosettaStone]::VisualTypeMap.ContainsKey($idV2)) { return [RosettaStone]::VisualTypeMap[$idV2] }
        return @{ name = "unknown"; id_v3 = 0; label = "Unknown" }
    }
    static [int] GetPropertyId([string]$name) {
        foreach ($key in [RosettaStone]::PropertyMap.Keys) {
            if ([RosettaStone]::PropertyMap[$key].name -eq $name) { return $key }
        }
        return 0
    }
}"""

driver_v3 = r"""using module "j:\replica_lab\src\Core\CanonicalModel.ps1"
using module "j:\replica_lab\src\Core\RosettaStone.ps1"

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
                    "name"         = "Repositório Local"
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
    [string] CalculateFieldHash([string]$text, [MvField]$field) {
        if ($field -and $field.CreatedBy -eq 'Migrador®') { return [DriverV3]::SecurityHashes["empty"] }
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
}"""

with open(r"j:\replica_lab\src\Core\RosettaStone.ps1", "w", encoding="utf-8") as f:
    f.write(rosetta_stone)

with open(r"j:\replica_lab\src\Drivers\DriverV3.ps1", "w", encoding="utf-8") as f:
    f.write(driver_v3)

print("SUCCESS")
