# Protocolo P-11 Definitivo v2.0 (QCS-Ω)

Este protocolo define as diretrizes de governança, segurança e integridade para operações agênticas no ecossistema Réplica MV.

## 1. Classificação de Risco (Níveis de Criticidade)

| Nível | Impacto | Descrição | Exemplo |
| :--- | :--- | :--- | :--- |
| **N0** | Trivial | Mudanças cosméticas, comentários ou documentação não-crítica. | Refatoração de nomes de variáveis locais. |
| **N1** | Baixo | Alterações funcionais em componentes isolados sem persistência. | Ajuste de padding em componente UI. |
| **N2** | Médio | Alterações em esquemas de dados, lógica de negócio ou conversores. | Modificação no AST do Transpiler. |
| **N3** | Crítico | Operações que afetam integridade clínica, hashes ou banco (Oracle). | Alteração na `Shadow Logic` ou engine de Hash. |

## 2. Estrutura A-G (Abstração à Governança)

- **A - Arquitetura**: Respeito à Árvore Semântica e isolamento de módulos.
- **B - Binário**: Integridade de blobs Jasper e Java Serialized.
- **C - Criptografia**: Manutenção estrita de hashes MD5 e verificações de paridade.
- **D - Dados**: Proteção de metadados de auditoria e sanitização de IDs.
- **E - Execução**: Validação via VT-3 antes de qualquer commit ou output.
- **F - Forensics**: Registro de anomalias encontradas no legado.
- **G - Governança**: Roteamento de contexto centralizado no `MASTER.md`.

## 3. Mecanismos SEC-LLM e CAL-Σ

### SEC-LLM (Security for LLM)
- **Proibição de Alucinação Clínica**: O agente deve abster-se de gerar ou "corrigir" fórmulas clínicas sem especificação exata.
- **Sanitização SQL**: Bloqueio de comandos DML (`INSERT`, `UPDATE`, `DELETE`) em metadados de formulário, exceto onde explicitamente documentado como necessário.

### CAL-Σ (Self-consistency)
- Antes de entregar uma solução complexa, o agente deve executar uma rodada interna de "auto-questionamento" para verificar se a saída viola qualquer restrição de segurança clínica listada no projeto.
