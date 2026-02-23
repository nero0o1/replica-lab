import sys
import os

# Garante que o diretório src esteja no path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../src')))

from core.inspetor_regras import validar_identificador

def runner_test_onda5():
    """
    Bancada de Testes Locais para a Onda 5.
    Valida o comportamento de sucesso (silencioso) e o Fail-Fast (exceção).
    """
    print("--- Iniciando Bancada de Testes: Onda 5 (O Inspetor) ---")

    test_cases_sucesso = [
        "TXT_NOME_PACIENTE",
        "DAT_NASCIMENTO",
        "CHK_ALERGICO",
        "CBB_SETOR_HOSPITALAR",
        "RDB_SANGUINEO_AB_POS"
    ]

    test_cases_falha = [
        ("txt_minusc_errado", "Letras minúsculas"),
        ("TXT_AÇÃO", "Caracteres acentuados"),
        ("TXT-HIFEN-ERRADO", "Uso de hífen"),
        ("TXT ESPACO", "Uso de espaço"),
        ("CAM_PREFIXO_INVALIDO", "Prefixo não autorizado"),
        ("", "Identificador vazio")
    ]

    # 1. Validando Sucessos
    print("\nExecutando casos de SUCESSO:")
    for id_ok in test_cases_sucesso:
        try:
            validar_identificador(id_ok)
            print(f"  [OK] '{id_ok}' aprovado.")
        except ValueError as e:
            print(f"  [ERRO INESPERADO] '{id_ok}' falhou: {e}")

    # 2. Validando Falhas (Esperamos Exceções)
    print("\nExecutando casos de FALHA (Fail-Fast):")
    for id_fail, motivo in test_cases_falha:
        try:
            validar_identificador(id_fail)
            print(f"  [FALHA NO TESTE] '{id_fail}' ({motivo}) deveria ter gerado exceção!")
        except ValueError as e:
            print(f"  [SUCESSO NO TESTE] '{id_fail}' ({motivo}) bloqueado corretamente.")
            print(f"  Mensagem gerada: {str(e).splitlines()[0]}")

if __name__ == "__main__":
    runner_test_onda5()
