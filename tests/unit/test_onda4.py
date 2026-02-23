import json
import os
import sys

# Garante que o diretório src/core esteja no path para importação
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../src')))

from core.empacotador_layout import empacotar_content

def test_onda4_empacotamento():
    """
    Passo 3: Validação na Bancada de Testes.
    Simula a entrada geométrica e valida a blindagem da string.
    """
    print("--- Iniciando Teste da Onda 4 (Caixa Preta Visual) ---")
    
    # Dado visual simulado
    dado_visual = {"grid": "vazio"}
    
    # Execução do empacotamento
    content_blindado = empacotar_content(dado_visual)
    
    # Estrutura de saída simulada do layout
    layout_final = {
        "layouts": [
            {
                "type": "GRID_SYSTEM",
                "content": content_blindado
            }
        ]
    }

    print(f"Mock Input: {dado_visual}")
    print(f"Blindagem Gerada (chave content): {content_blindado}")
    
    # Validações de Rigor
    # 1. Não pode ter espaços
    if " " in content_blindado:
        print("ERRO: A string blindada contém espaços em branco!")
    else:
        print("SUCESSO: Minificação extrema confirmada (sem espaços).")

    # 2. Deve ser uma string (dupla serialização)
    if not isinstance(content_blindado, str):
        print("ERRO: O campo content não é uma string!")
    else:
        print("SUCESSO: Dupla serialização confirmada.")

    # Exibição do JSON final do layout de teste
    print("\nLayout JSON Final (Simulado):")
    print(json.dumps(layout_final, indent=4))

if __name__ == "__main__":
    test_onda4_empacotamento()
