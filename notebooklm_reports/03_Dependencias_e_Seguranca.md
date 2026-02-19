# 03 - Dependências e Segurança

Autor: Agente Antigravity (via NotebookLM)
Data: 2026-02-18

## 1. Dependências Externas
Este projeto foi desenhado para **Zero-Dependency** externo. Não requer `npm`, `pip`, ou módulos PowerShell de terceiros.

### Frameworks Nativos Utilizados
1. **System.Security.Cryptography**: 
   - Necessário para acesso às classes `MD5` usadas na assinatura digital dos arquivos.
2. **System.Text**: 
   - Utilizado para manipulação eficiente de Strings (`StringBuilder`) na geração de XML.
   - Utilizado para controle estrito de `UTF8Encoding($false)` (UTF-8 sem BOM), requisito obrigatório do sistema legado.
3. **Microsoft.PowerShell.Utility**: 
   - Cmdlets nativos `ConvertFrom-Json` e `ConvertTo-Json`.

## 2. Segurança e Integridade

### A. Assinatura Digital (Hashing)
O Editor 3 exige que os arquivos sejam "assinados" para garantir que não foram corrompidos ou alterados manualmente de forma inválida.

**Algoritmo de Hash**:
- **Tipo**: MD5 (Message Digest 5).
- **Alvo**: O objeto `data` dentro do JSON.
- **Processo**:
  1. O objeto `data` é isolado.
  2. É serializado para JSON Minificado (sem espaços).
  3. O hash MD5 é calculado sobre os bytes UTF-8 dessa string.
  4. O resultado (Hex 32 chars) é gravado em `version.hash`.

**Risco Identificado**: MD5 é considerado criptograficamente fraco para segurança moderna, mas é mantido aqui por **compatibilidade estrita** com o sistema legado (Editor 3).

### B. Sanitização de Entrada
- **Prefixos**: O sistema recusa a criação de campos que não sigam o padrão de nomenclatura MV (`TXT_`, `CBB_`, etc.).
- **Tipagem Forte**: O sistema recusa valores de tipo incorreto (ex: String em campo Boolean) através da validação na classe `CanonicalProperty`.

## 3. Configurações de Ambiente
Não há arquivos `.env` ou segredos hardcoded.
- O sistema assume execução local com acesso de leitura/escrita na pasta `J:\replica_lab`.
- Caminhos são relativos ou passados como argumento para os scripts.
