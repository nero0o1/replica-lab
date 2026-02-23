"""
Etiquetas Semânticas — Módulo Central de Tradução de Propriedades.

Este módulo elimina o uso de "magic numbers" no código, substituindo-os por 
etiquetas nominais descritivas. Todo ID numérico de propriedade do domínio MV 
deve ser referenciado EXCLUSIVAMENTE por sua etiqueta semântica.

Origem: RosettaStone.ps1 (PowerShell) — replicado em Python para paridade sistêmica.
"""

from enum import IntEnum
from typing import Dict, Optional


class PropId(IntEnum):
    """Enum de IDs de Propriedade com nomes semânticos.
    
    Cada membro mapeia o ID numérico legado para uma constante nomeada.
    Uso: PropId.OBRIGATORIO em vez de 8.
    """
    TAMANHO               = 1
    LISTA_VALORES         = 2
    MASCARA               = 3
    ACAO                  = 4
    USADO_EM              = 5
    EDITAVEL              = 7
    OBRIGATORIO           = 8
    VALOR_INICIAL         = 9
    CRIADO_POR            = 10
    ACAO_TEXTO_PADRAO     = 13
    TEXTO_PADRAO          = 14
    PARAMETROS_TEXTO_PADRAO = 15
    REPROCESSAR           = 17
    LISTA_ICONES          = 18
    ACAO_SQL              = 21
    REGRAS_USADAS         = 22
    VOZ                   = 23
    EXPOR_PARA_API        = 29
    HINT                  = 30
    DESCRICAO_API         = 31
    IMPORTADO             = 33
    MIGRADO               = 34
    TIPO_DO_GRAFICO       = 35
    REQUISICAO_API        = 36
    CASCATA_DE_REGRA      = 38


# Dicionário bidirecional: ID ↔ Identificador textual (etiqueta)
ID_PARA_ETIQUETA: Dict[int, str] = {
    PropId.TAMANHO:                "tamanho",
    PropId.LISTA_VALORES:          "lista_valores",
    PropId.MASCARA:                "mascara",
    PropId.ACAO:                   "acao",
    PropId.USADO_EM:               "usado_em",
    PropId.EDITAVEL:               "editavel",
    PropId.OBRIGATORIO:            "obrigatorio",
    PropId.VALOR_INICIAL:          "valor_inicial",
    PropId.CRIADO_POR:             "criado_por",
    PropId.ACAO_TEXTO_PADRAO:      "acao_texto_padrao",
    PropId.TEXTO_PADRAO:           "texto_padrao",
    PropId.PARAMETROS_TEXTO_PADRAO: "parametros_texto_padrao",
    PropId.REPROCESSAR:            "reprocessar",
    PropId.LISTA_ICONES:           "lista_icones",
    PropId.ACAO_SQL:               "acaoSql",
    PropId.REGRAS_USADAS:          "regras_usadas",
    PropId.VOZ:                    "voz",
    PropId.EXPOR_PARA_API:         "expor_para_api",
    PropId.HINT:                   "hint",
    PropId.DESCRICAO_API:          "descricaoApi",
    PropId.IMPORTADO:              "importado",
    PropId.MIGRADO:                "migrado",
    PropId.TIPO_DO_GRAFICO:        "tipo_do_grafico",
    PropId.REQUISICAO_API:         "requisicao_api",
    PropId.CASCATA_DE_REGRA:       "cascata_de_regra"}

ETIQUETA_PARA_ID: Dict[str, int] = {v: k for k, v in ID_PARA_ETIQUETA.items()}


# Tipo esperado de cada propriedade
TIPO_PROPRIEDADE: Dict[int, str] = {
    PropId.TAMANHO:                "Integer",
    PropId.LISTA_VALORES:          "Array",
    PropId.MASCARA:                "String",
    PropId.ACAO:                   "String",
    PropId.USADO_EM:               "String",
    PropId.EDITAVEL:               "Boolean",
    PropId.OBRIGATORIO:            "Boolean",
    PropId.VALOR_INICIAL:          "String",
    PropId.CRIADO_POR:             "String",
    PropId.ACAO_TEXTO_PADRAO:      "String",
    PropId.TEXTO_PADRAO:           "String",
    PropId.PARAMETROS_TEXTO_PADRAO: "String",
    PropId.REPROCESSAR:            "Boolean",
    PropId.LISTA_ICONES:           "Array",
    PropId.ACAO_SQL:               "String",
    PropId.REGRAS_USADAS:          "String",
    PropId.VOZ:                    "Boolean",
    PropId.DESCRICAO_API:          "String",
    PropId.TIPO_DO_GRAFICO:        "String"}


def obter_etiqueta(prop_id: int) -> str:
    """Traduz um ID numérico legado para sua etiqueta semântica.
    
    Args:
        prop_id: O ID numérico da propriedade (ex: 8).
        
    Returns:
        A etiqueta nominal (ex: "obrigatorio"). Retorna "UNKNOWN_PROPERTY_{id}"
        se o mapeamento não existir.
    """
    return ID_PARA_ETIQUETA.get(prop_id, f"UNKNOWN_PROPERTY_{prop_id}")


def obter_id(etiqueta: str) -> Optional[int]:
    """Traduz uma etiqueta semântica para seu ID numérico legado.
    
    Args:
        etiqueta: A etiqueta nominal (ex: "obrigatorio").

    Returns:
        O ID numérico (ex: 8), ou None se a etiqueta é desconhecida.
    """
    return ETIQUETA_PARA_ID.get(etiqueta)
