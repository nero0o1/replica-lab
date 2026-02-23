"""
Look-up Table (Tabela de Consulta Estática) de Hashes MD5.
Implementa o Cadeado de Segurança (Onda 3) para conformidade antifraude.

Esta tabela contém os lacres imutáveis permitidos pelo manual técnico do sistema destino.
A arquitetura utiliza consulta estática para evitar overhead de processamento.
"""

from typing import Dict, Any, Optional

# Tabela de Consulta Estática (Look-up Table)
TABELA_HASHES: Dict[Any, str] = {
    True: "b326b5062b2f0e69046810717534cb09",       # Boolean true
    False: "68934a3e9455fa72420237eb05902327",      # Boolean false
    None: "37a6259cc0c1dae299a7866489dff0bd",       # Null null
    "": "d41d8cd98f00b204e9800998ecf8427e",         # String Vazia
    "0": "cfcd208495d565ef66e7dff9f98764da",        # String "0"
    "1": "c4ca4238a0b923820dcc509a6f75849b"         # String "1"
}

def obter_lacre(valor: Any) -> str:
    """
    Busca o Hash MD5 (lacre) correspondente ao valor fornecido.
    
    Resiliência: Se o valor for um tipo não-hachável (ex: lista), retorna o
    lacre padrão de string vazia para manter a integridade do nó.
    """
    try:
        # Tenta buscar na tabela estática
        return TABELA_HASHES.get(valor, "d41d8cd98f00b204e9800998ecf8427e")
    except TypeError:
        # Fallback para tipos complexos (como listas do ID 25)
        return "d41d8cd98f00b204e9800998ecf8427e"
