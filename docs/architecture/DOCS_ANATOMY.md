# DOCS ANATOMY: Technical Biopsy (Titan v2.0)

This document provides the definitive anatomy of the project entities and business logic inferred from the forensic implementation of Phases 1-11.

## 1. Mapeamento de Entidades

### 1.1 `MvDocument` (The Container)
- **Campos**:
    - `Id` (Int, Mandatório): Identificador único global (V2 CD_DOCUMENTO / V3 data.id).
    - `Name` (String, Mandatório): Nome descritivo (DS_DOCUMENTO).
    - `Identifier` (String, Mandatório): Identificador técnico em `UPPER_SNAKE_CASE`.
    - `Active` (Bool, Mandatório): Status operacional.
    - `CreatedBy` (String): Autor do artefato (Gatilho para exceção de hash).
    - `VersionHash` (String): Selo de integridade (MD5 do layout).
- **Relações**: Depende de `MvField` (1:N) e `MvGroup` (1:N).

### 1.2 `MvField` (The Logic)
- **Campos**:
    - `IdLegacy` (Int): Referência cruzada para banco V2.
    - `Identifier` (String): Forçado para `UPPER_SNAKE_CASE`.
    - `TypeIdModern` (Int): Mapeamento via `RosettaStone`.
    - `Properties` (IDictionary): Bag de propriedades tipadas.
- **Validação**: Identificadores são higienizados via regex `[^A-Z0-9_]` -> `_`.

### 1.3 `RosettaStone` (The Mapper)
- **Campos**: Mapeia IDs Legados (1, 4, 21, 35) para Identificadores Modernos.
- **Regra Crítica**: Mapeamento fixo de IDs de Visualização para garantir que Checkboxes (4) e Ações SQL (21) mantenham comportamento binário.

## 2. Regras de Negócio Hardcoded (Escondidas)

| Regra | Lógica | Impacto |
| :--- | :--- | :--- |
| **Exceção Migrador®** | Se autor == "Migrador®", hash = `d41d8...` | Ignora o cálculo MD5 dinâmico para evitar quebras em registros legados. |
| **Santuário SQL** | Pós-processamento remove escapes `\u0026` | Garante que o Editor 3 React não quebre scripts SQL que usam variables `&<PAR_...>`. |
| **Matrioska Seal** | Global Hash em `version.hash` | O documento é rejeitado se o MD5 do layout não bater bit-a-bit. |
| **Static Hash Table** | Bools/Nulls usam hashes fixos | Impede o "Agent Drift" de tentar usar MD5(String("true")) que geraria hash errado no Oracle. |

## 3. Relações de Dependência (Cadeia de Ingestão)
1. `ImporterV2` -> detecta `ACED0005` -> extrai XML.
2. `CanonicalModel` -> sanitiza nomes -> popula objetos.
3. `RosettaStone` -> resolve tipos e identificadores de propriedade.
4. `DriverV3` -> minifica layout -> calcula hashes -> gera JSON final.

---
*Documento gerado via Inspeção Estática de Código (Titan v2.0).*
