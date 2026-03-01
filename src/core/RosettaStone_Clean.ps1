Class RosettaStone {
    static [hashtable] $PropertyMap = @{
        1  = @{ name = 'tamanho'; desc = 'Tamanho'; key = 'document.property.size' }
        2  = @{ name = 'lista_valores'; desc = 'Lista de valores'; key = 'document.property.value.list' }
        3  = @{ name = 'mascara'; desc = 'MÃ¡scara'; key = 'document.property.mask' }
        4  = @{ name = 'acao'; desc = 'AÃ§Ã£o'; key = 'document.property.action' }
        5  = @{ name = 'usado_em'; desc = 'Usado Em'; key = 'document.property.used.in' }
        7  = @{ name = 'editavel'; desc = 'EditÃ¡vel'; key = 'document.property.editable' }
        8  = @{ name = 'obrigatorio'; desc = 'ObrigatÃ³rio'; key = 'document.property.required' }
        9  = @{ name = 'valor_inicial'; desc = 'Valor Inicial'; key = 'document.property.initial.value' }
        10 = @{ name = 'criado_por'; desc = 'Criado Por'; key = 'document.property.created.by' }
        13 = @{ name = 'acao_texto_padrao'; desc = 'AÃ§Ã£o de texto padrÃ£o'; key = 'document.property.default.text.action' }
        14 = @{ name = 'texto_padrao'; desc = 'Texto padrÃ£o'; key = 'document.property.default.text' }
        15 = @{ name = 'parametros_texto_padrao'; desc = 'ParÃ¢metros de texto padrÃ£o'; key = 'document.property.default.text.parameters' }
        17 = @{ name = 'reprocessar'; desc = 'Reprocessar aÃ§Ã£o'; key = 'document.property.reprocessed.action' }
        19 = @{ name = 'barcode_type'; desc = 'Tipo de cÃ³digo de barras'; key = 'document.property.barcode.type' }
        20 = @{ name = 'show_barcode_label'; desc = 'Mostrar descriÃ§Ã£o de cÃ³digo de barras'; key = 'document.property.show.barcode.label' }
        21 = @{ name = 'acao_sql'; desc = 'AÃ§Ã£o SQL'; key = 'document.property.sql.action' }
        22 = @{ name = 'regras_usadas'; desc = 'Regra(s)'; key = 'document.property.rules' }
        24 = @{ name = 'criado_em'; desc = 'Criado Em'; key = 'document.property.created.in' }
        25 = @{ name = 'ultima_publicacao_por'; desc = 'Ãšltima PublicaÃ§Ã£o Por'; key = 'document.property.last.post.by' }
        26 = @{ name = 'publicado_em'; desc = 'Publicado Em'; key = 'document.property.publicated.in' }
        29 = @{ name = 'expor_para_api'; desc = 'Expor para API'; key = 'document.property.export.api' }
        30 = @{ name = 'hint'; desc = 'Hint'; key = 'document.property.hiny' }
        31 = @{ name = 'descricao_api'; desc = 'DescriÃ§Ã£o API'; key = 'document.property.description.api' }
        33 = @{ name = 'importado'; desc = 'Importado'; key = 'document.property.imported' }
        34 = @{ name = 'migrado'; desc = 'Migrado'; key = 'document.property.migrated' }
        36 = @{ name = 'requisicao_api'; desc = 'RequisiÃ§Ã£o API'; key = 'document.property.request.api' }
        38 = @{ name = 'cascata_regra'; desc = 'Cascatear regra'; key = 'document.property.rule.cascade' }
        43 = @{ name = 'executar_regra_campo_oculto'; desc = 'Executar regra com campo oculto'; key = 'document.property.execute.rule.hidden.field' }
    }
    static [hashtable] $ItemTypeMap = @{
        'DOC'       = @{ id = 13; identifier = 'DOC'; description = 'Documento'; permissionModifyGroup = $true }
        'CAM'       = @{ id = 8; identifier = 'CAM'; description = 'Campo'; permissionModifyGroup = $true }
        'G_DOC'     = @{ id = 29; identifier = 'G_DOC'; description = 'Grupo dos Documentos'; permissionModifyGroup = $true }
        'G_REP_DOC' = @{ id = 10; identifier = 'G_REP_DOC'; description = 'Grupo dos RepositÃ³rio dos Documentos'; permissionModifyGroup = $true }
        'R_REP_DOC' = @{ id = 9; identifier = 'R_REP_DOC'; description = 'Raiz dos RepositÃ³rios dos Documentos'; permissionModifyGroup = $false }
        'G_CAM'     = @{ id = 6; identifier = 'G_CAM'; description = 'Grupo dos Campos'; permissionModifyGroup = $true }
        'R_REP_CAM' = @{ id = 3; identifier = 'R_REP_CAM'; description = 'Raiz dos RepositÃ³rios dos Campos'; permissionModifyGroup = $false }
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
        10 = @{ name = 'button'; id_v3 = 7; label = 'BotÃ£o' }
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
}
