# Guia de Validação: A Pista de Testes

Este documento descreve como validar o comportamento do motor de tradução de forma simples e direta, focando nos resultados visíveis.

## 🟢 Caso de Teste 01: O Caminho Feliz (Happy Path)
**Objetivo**: Validar se uma tradução perfeita é gerada com todos os selos de segurança.

**Procedimento**:
1. Envie uma propriedade legada com ID `15` e valor `"255"`.
2. Envie um identificador técnico configurado como `TXT_RESUMO_CLINICO`.

**Resultado Esperado**:
- O sistema deve gerar um arquivo JSON.
- O campo `tamanho` deve ser um número inteiro `255` (sem aspas).
- Deve existir uma chave `"hash"` com o lacre MD5 correspondente.
- Os dados visuais dentro de `"content"` devem estar em uma única linha densa (minificação).

---

## 🔴 Caso de Teste 02: O Caminho de Erro (Unhappy Path)
**Objetivo**: Validar se o sistema bloqueia tentativas de corrupção.

**Procedimento**:
1. Envie um identificador técnico fora do padrão, como `txt_entrada` (letras minúsculas).
2. Tente iniciar o processo de exportação.

**Resultado Esperado**:
- O sistema **não deve** gerar o arquivo JSON.
- O processo deve ser interrompido imediatamente (Fail-Fast).
- O sistema deve exibir uma mensagem de erro fatal informando: `ValueError: Identificador 'txt_entrada' fora do padrão industrial`.

---

## 🛠️ Como Executar a Pista de Testes Automática
Para rodar todos os testes de engenharia de uma só vez, execute o comando abaixo no terminal da raiz do projeto:

```bash
python run_all_tests.py
```
