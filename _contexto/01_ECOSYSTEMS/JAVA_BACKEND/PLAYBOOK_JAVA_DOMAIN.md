# PLAYBOOK JAVA DOMAIN - Engenharia de Domínio e Persistência

## 1. Princípios de Modelo e Persistência (Oracle SmartDB)
- **Modelo Canônico (AST)**: Toda leitura do Oracle deve ser convertida para a AST antes de qualquer manipulação. 
- **Two-Dictionary Rule (Mandatório)**: O motor deve separar estritamente `CD_PROPRIEDADE` (Identidade de Atributo) de `CD_TIPO_VISUALIZACAO` (Identidade de Componente). Proibido unificar ou inferir dados cruzados entre estas tabelas.
- **IDs Temporários (Negative ID Paradox)**: Use IDs negativos (ex: `-1001`) para componentes criados em memória. O "de-para" para IDs reais da `SEQ_MAP_EDITOR_MV` deve ocorrer apenas no commit final.
- **Vault Pattern (Jasper Preservation)**: O binário `LO_REL_COMPILADO` (JasperReports) é intocável. Deve ser capturado via `MvLegacyPayload` e reinjetado integralmente na saída para manter a paridade com motores de impressão.

## 2. Regras de Sincronização e Write-back
- **Conversão de Tipos**: O `DriverV2` reconverte dados modernos para o legado.
- **Booleanos**:
    - Propriedades Técnicas (Editável, Obrigatório): Usar `true`/`false`.
    - Domínio Clínico (ex: `SN_ATIVO`): Usar `'S'` ou `'N'`.
- **Sanitização de Hash**: Validar o Root Hash (`ID_INTERNO + IDENTIFICADOR_TECNICO + ID_TIPO_VISUAL`) no momento da ingestão. Se houver discrepância, acionar bloqueio VT-3.

## 3. Lógica de Negócio e Triggers PL/SQL
- **Injeção de Macros**: Resolver macros `&<PAR_...>` (CD_ATENDIMENTO, CD_PACIENTE) server-side. Nunca expor SQL bruto com macros ao frontend.
- **Hierarquia de Execução**: Seguir rigorosamente `ON_LOAD` -> `FETCH_SQL` -> `ON_CHANGE` -> `ON_SAVE`.
- **Reprocessamento (ID 17)**: Gatilho mandatório para reciclagem assíncrona de regras.

## 4. Auditoria de Soberania (VT-3)
- **Schema**: Validar tags mandatórias (`CD_DOCUMENTO`, `NM_IDENTIFICADOR`).
- **Behavioral**: Árvore AST deve ser idêntica na ida e volta.
- **Security**: Recalcular hashes e validar paridade bit-a-bit.
- **Hard Limits**: Bloquear strings > 4000 caracteres para campos Oracle VARCHAR2.
