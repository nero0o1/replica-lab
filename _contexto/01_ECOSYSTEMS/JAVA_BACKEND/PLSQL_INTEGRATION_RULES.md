# PLSQL INTEGRATION RULES - Regras de Integração Oracle SmartDB

Este documento detalha como o backend Java deve lidar com a lógica implícita do banco de dados Oracle para mimetizar o comportamento do Editor 2.

## 1. Coerção de Tipos e Constraints
| Tipo Oracle | Constraint | Mapeamento Java |
| :--- | :--- | :--- |
| `VARCHAR2(4000)` | Truncagem em 4000 caracteres (Barreira VT-3). | `String` |
| `LONG RAW` | Blobs legados. Requer extração via `MvLegacyPayload`. | `byte[]` / `Base64` |
| `NUMBER(1,0)` | Marcador booleano de flag. | `boolean` (0=false, 1=true) |
| `CLOB` | Scripts SQL de ações (ID 4/21). | `String` |

## 2. Injeção de Variáveis de Sessão (SmartDB Context)
O motor deve substituir as macros `&<PAR_...>` por tokens seguros `{{SYSTEM_VAR:...}}` antes da execução para prevenir injeção de SQL.
- `&<PAR_CD_ATENDIMENTO>`: Contexto de atendimento (data-context-atend).
- `&<PAR_CD_PACIENTE>`: Isolamento clínico mandatório.
- `&<PAR_USUARIO_LOGADO>`: Fins de log e auditoria (Forensics).

## 3. Protocolo de Quarentena e Blindagem
- **OPAQUE_SCRIPT**: Quando o `RuleLexer` identifica `DECLARE`, `BEGIN`, `CURSOR` ou loops complexos:
    - Suspender tradução automática.
    - Aplicar `data-quarantined="true"`.
    - Blindar a carga via Base64 (A carga torna-se imune a aspas e caracteres de controle).
- **Shielding Phase**: Capturar estado -> Escapamento Rigoroso (Double Backslash) -> Base64 Encoding.

## 4. Orquestração de Gatilhos (Event Loop)
Paridade síncrona com o sistema MV:
1. `init()`: Registro de dependências e snapshoting inicial (`data-initial-state`).
2. `ON_LOAD`: Execução de regras de abertura.
3. `Interaction Layer`: Aguardando entrada (onChange, click).
4. `Update Loop`: Aplicação de regras em cascata respeitando o `cascata_de_regra` (ID 38).
