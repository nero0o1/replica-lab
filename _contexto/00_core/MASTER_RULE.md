# MASTER RULE - Leis Inegociáveis do Ecossistema Réplica (Paradigma ACE)

## 1. O Oráculo Legado (_base_de_dados)
- A pasta `./_base_de_dados` é **ESTRITAMENTE READ-ONLY**.
- Toda operação de I/O deve ser feita em modo Somente Leitura.
- Proibido gerar arquivos de cache ou temporários nesta pasta.

## 2. Governança de Código e Dados
- **Case Sensitivity**: Identificadores técnicos devem seguir rigorosamente `UPPER_SNAKE_CASE` (ex: `CD_PROPRIEDADE`). 
- **Integridade**: Proibido alterar lógicas de hashes MD5 ou sanitização sem aprovação explícita via QA.
- **SQL Sanitization**: Nunca usar comentários curtos (`--`) em strings que serão convertidas para JSON Flattened. Use `/* ... */`.

## 3. Protocolo de Execução Agêntica
- **Inicialização**: Todo agente deve ler `00_CORE/MASTER_RULE.md` e `00_CORE/ACTIVE_PLAN.md`.
- **Just-in-Time (JIT)**: Carregue playbooks de `01_ECOSYSTEMS` e regras de `02_SEMANTICS` apenas quando necessário para a tarefa.
- **Isolamento de Dúvidas**: Se encontrar anomalias (A), conflitos (B) ou ambiguidades (C), **PARE** e use o fluxo `./_qa_agentes/PENDING_APPROVAL/`.
- **Soberania de Domínios**: Proibido unificar `CD_PROPRIEDADE` com `CD_TIPO_VISUALIZACAO`. Use dicionários duplos no `CanonicalModel`.

## 4. Estilo de Comunicação
- Responda como um Especialista em Contexto Agêntico (ACE).
- Mantenha a documentação atualizada em tempo real (Memória RAM do projeto).
