"""
TEST RUNNER CENTRALIZADO — Etapa 5.
Este script executa toda a esteira de testes automatizados do motor de tradução,
garantindo que as Ondas 2, 4 e 5 estejam integradas e operacionais.
"""

import subprocess
import sys
import os

def executar_teste(nome, comando):
    print(f"\n>>> Executando: {nome}...")
    try:
        # Executa o comando e captura a saída
        resultado = subprocess.run(
            comando, 
            shell=True, 
            capture_output=True, 
            text=True,
            cwd=os.path.abspath(os.path.dirname(__file__))
        )
        
        if resultado.returncode == 0:
            print(f"  [SUCESSO] {nome} passou.")
            return True
        else:
            print(f"  [FALHA] {nome} encontrou erros.")
            print(f"  Saída de Erro:\n{resultado.stdout}\n{resultado.stderr}")
            return False
    except Exception as e:
        print(f"  [ERRO CRÍTICO] Falha ao tentar rodar {nome}: {e}")
        return False

def run_pipeline():
    print("="*60)
    print("INICIANDO PISTA DE TESTES - PROJETO RÉPLICA MV")
    print("="*60)
    
    testes = [
        ("Onda 2: Tradutor & Casting", "python tests/unit/test_onda2.py"),
        ("Onda 4: Empacotamento Visual", "python tests/unit/test_onda4.py"),
        ("Onda 5: Inspetor de Crachás", "python tests/unit/test_onda5.py")
    ]
    
    sucessos = 0
    for nome, cmd in testes:
        if executar_teste(nome, cmd):
            sucessos += 1
            
    print("\n" + "="*60)
    print(f"RESULTADO FINAL: {sucessos}/{len(testes)} Testes Aprovados.")
    print("="*60)
    
    if sucessos == len(testes):
        print("SISTEMA PRONTO PARA EXPORTAÇÃO (DEPENDABILIDADE GARANTIDA).")
        sys.exit(0)
    else:
        print("SISTEMA BLOQUEADO. CORRIJA AS FALHAS ANTES DA EXPORTAÇÃO.")
        sys.exit(1)

if __name__ == "__main__":
    run_pipeline()
