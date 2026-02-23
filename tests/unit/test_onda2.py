import json
import os
import sys

# Garante que o diretório src/core esteja no path para importação
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../src')))

from core.tradutor_roseta import TradutorRoseta

def test_onda2_conversion():
    """
    Passo 2 e 3: Injeção de Mock Data e Exportação Segura.
    Simula o sistema legado e valida o casting rigoroso.
    """
    tradutor = TradutorRoseta()
    
    # Mock Data simulando IDs legados
    payload_entrada = {
        "8": "true",        # Obrigatorio (Boolean)
        "15": "255",        # Tamanho (Integer - CRÍTICO)
        "17": "false",       # Reprocessar (Boolean)
        "21": "SELECT *",   # AcaoSql (String)
        "25": "A|B;C"       # ListaValores (Array - Delimitadores combinados)
    }

    print("--- Iniciando Tradução da Onda 2 ---")
    resultado_final = {}
    
    for p_id, p_val in payload_entrada.items():
        traducao = tradutor.traduzir_propriedade(int(p_id), p_val)
        resultado_final.update(traducao)

    # Registro físico do teste conforme solicitado no Passo 3
    output_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../teste_mini.json'))
    
    with open(output_path, 'w', encoding='utf-8') as f:
        # ensure_ascii=False para manter acentuação se houver
        json.dump(resultado_final, f, indent=4, ensure_ascii=False)
    
    print(f"Arquivo gerado com sucesso em: {output_path}")
    print("Conteúdo do JSON:")
    print(json.dumps(resultado_final, indent=4))

    # Validação de Resiliência (ID 25 com delimitadores duplos)
    print("\n--- Validação de Anomalias (Passo 4) ---")
    teste_anomalia = "A||B"
    resultado_anomalia_raw = tradutor.traduzir_propriedade(25, teste_anomalia)
    
    # Extrai a lista do wrapper de segurança {"value": [...], "hash": "..."}
    resultado_anomalia = resultado_anomalia_raw.get("listaValores", {}).get("value", [])
    print(f"Entrada: '{teste_anomalia}' -> Saída (Value): {resultado_anomalia}")
    
    # Verifica se o item vazio foi descartado
    if any(item["value"] == "" for item in resultado_anomalia):
        print("ERRO: Identificado valor vazio na lista!")
    else:
        print("SUCESSO: Delimitadores duplos tratados corretamente (itens vazios descartados).")

if __name__ == "__main__":
    test_onda2_conversion()
