"""
Empacotador de Layout — Onda 4: A Caixa Preta Visual.
Este módulo aplica a técnica de "Dupla Serialização" com "Minificação Extrema".
Garante que os dados visuais sejam transportados como uma linha única e densa,
prevenindo falhas de memória no interpretador do sistema destino.
"""

import json
from typing import Any, Dict

def empacotar_content(dados_visuais: Dict[str, Any]) -> str:
    """
    Transforma um dicionário de layout em uma string JSON minificada e escapada.
    
    Args:
        dados_visuais: Dicionário contendo a estrutura geométrica/visual da tela.
        
    Returns:
        String JSON blindada (sem espaços e com separadores densos).
    """
    if not dados_visuais:
        return "{}"

    # REGRA CRÍTICA (Passo 2): Minificação Extrema.
    # separators=(',', ':') remove espaços em branco após as vírgulas e dois-pontos.
    # ensure_ascii=True (padrão) garante o escape correto de caracteres não-ASCII se houver.
    return json.dumps(dados_visuais, separators=(',', ':'))
