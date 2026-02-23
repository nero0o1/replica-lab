"""
O Inspetor Rigoroso — Onda 5.
Garante a integridade léxica dos identificadores técnicos (crachás).
Aplica o padrão Fail-Fast para impedir a exportação de arquivos corrompidos.
"""

import re

# REGEX OBRIGATÓRIA (Passo 2)
# 1. Prefixos: TXT, RDB, CHK, CBB, DAT
# 2. Separador: _
# 3. Conteúdo: A-Z, 0-9 e _
IDENTIDICADOR_REGEX = re.compile(r'^(TXT|RDB|CHK|CBB|DAT)_[A-Z0-9_]+$')

def validar_identificador(nome: str):
    """
    Valida se um identificador técnico atende às normas estritas do MV Soul.
    
    Caso o identificador viole o padrão, levanta uma exceção fatal para
    interromper o fluxo de exportação (Circuit Breaker).
    
    Args:
        nome: Identificador a ser validado (ex: TXT_OBSERVACAO).
        
    Raises:
        ValueError: Se o nome estiver fora do padrão esperado.
    """
    if not nome:
        raise ValueError("ERRO CRÍTICO: Identificador técnico vazio não é permitido.")

    if not IDENTIDICADOR_REGEX.match(nome):
        raise ValueError(
            f"ERRO DE INTEGRIDADE: Identificador '{nome}' fora do padrão industrial.\n"
            f"Formato esperado: ^(TXT|RDB|CHK|CBB|DAT)_[A-Z0-9_]+$\n"
            f"Restrições: Apenas maiúsculas, números e sublinhados, sem espaços ou acentos."
        )

# Mock de uso para o Fluxo de Exportação
def assegurar_integridade_payload(payload: dict):
    """Varre o payload validando todos os identificadores técnicos."""
    # Exemplo simplificado de varredura
    for chave in payload.keys():
        if chave.startswith(("TXT_", "RDB_", "CHK_", "CBB_", "DAT_")):
            validar_identificador(chave)
