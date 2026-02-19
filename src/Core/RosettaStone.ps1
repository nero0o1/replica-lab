class RosettaStone {
    # Structural Truth Mapping (Property IDs)
    static [System.Collections.IDictionary] $Map = @{
        1  = @{ Identifier = "tamanho"; Type = "Integer" }
        2  = @{ Identifier = "lista_valores"; Type = "Array" }
        3  = @{ Identifier = "mascara"; Type = "String" }
        4  = @{ Identifier = "acao"; Type = "String" }
        5  = @{ Identifier = "usado_em"; Type = "String" }
        7  = @{ Identifier = "editavel"; Type = "Boolean" }
        8  = @{ Identifier = "obrigatorio"; Type = "Boolean" }
        9  = @{ Identifier = "valor_inicial"; Type = "String" }
        10 = @{ Identifier = "criado_por"; Type = "String" }
        13 = @{ Identifier = "acao_texto_padrao"; Type = "String" }
        14 = @{ Identifier = "texto_padrao"; Type = "String" }
        15 = @{ Identifier = "parametros_texto_padrao"; Type = "String" }
        17 = @{ Identifier = "reprocessar"; Type = "Boolean" }
        18 = @{ Identifier = "lista_icones"; Type = "Array" }
        21 = @{ Identifier = "acaoSql"; Type = "String" }
        22 = @{ Identifier = "regras_usadas"; Type = "String" }
        23 = @{ Identifier = "voz"; Type = "Boolean" }
        31 = @{ Identifier = "descricaoApi"; Type = "String" }
        35 = @{ Identifier = "tipo_do_grafico"; Type = "String" }
    }

    # Visual Type Mapping (CD_TIPO_VISUALIZACAO)
    static [System.Collections.IDictionary] $LegacyToModernTypeMap = @{
        1  = @{ Id = 1; Identifier = "TEXT" }
        2  = @{ Id = 2; Identifier = "TEXTAREA" }
        3  = @{ Id = 3; Identifier = "COMBOBOX" }
        4  = @{ Id = 4; Identifier = "CHECKBOX" }
        6  = @{ Id = 6; Identifier = "RADIOBUTTON" }
        7  = @{ Id = 6; Identifier = "RADIOBUTTON" }
        9  = @{ Id = 9; Identifier = "DATE" }
        11 = @{ Id = 9; Identifier = "DATE" }
        12 = @{ Id = 10; Identifier = "IMAGE" }
        13 = @{ Id = 1; Identifier = "TEXT" }
        20 = @{ Id = 2; Identifier = "TEXTAREA" }
    }

    # Reverse Map
    static [System.Collections.IDictionary] $RevMap = @{
        "tamanho"                 = 1
        "lista_valores"           = 2
        "mascara"                 = 3
        "acao"                    = 4
        "usado_em"                = 5
        "editavel"                = 7
        "obrigatorio"             = 8
        "valor_inicial"           = 9
        "criado_por"              = 10
        "acao_texto_padrao"       = 13
        "texto_padrao"            = 14
        "parametros_texto_padrao" = 15
        "reprocessar"             = 17
        "lista_icones"            = 18
        "acaoSql"                 = 21
        "regras_usadas"           = 22
        "voz"                     = 23
        "expor_para_api"          = 29
        "hint"                    = 30
        "descricao_api"           = 31
        "descricaoApi"            = 31
        "importado"               = 33
        "migrado"                 = 34
        "tipo_do_grafico"         = 35
        "requisicao_api"          = 36
        "cascata_de_regra"        = 38
    }
    
    static [int] GetId([string]$identifier) {
        if ([RosettaStone]::RevMap.Contains($identifier)) {
            return [RosettaStone]::RevMap[$identifier]
        }
        throw "Unknown Identifier: $identifier"
    }
    
    static [string] GetIdentifier([int]$id) {
        if ([RosettaStone]::Map.Contains($id)) {
            return [RosettaStone]::Map[$id].Identifier
        }
        return "UNKNOWN_PROPERTY_$id"
    }
    
    static [string] GetType([int]$id) {
        if ([RosettaStone]::Map.Contains($id)) {
            return [RosettaStone]::Map[$id].Type
        }
        return "String"
    }

    static [hashtable] GetModernType([int]$legacyId) {
        if ([RosettaStone]::LegacyToModernTypeMap.Contains($legacyId)) {
            return [RosettaStone]::LegacyToModernTypeMap[$legacyId]
        }
        return @{ Id = $legacyId; Identifier = "UNKNOWN_($legacyId)" }
    }
}
