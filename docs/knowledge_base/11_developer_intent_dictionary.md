# 11 Developer Intent Dictionary (CD_PROPRIEDADE)

## 1. Intent Mapping Matrix
This dictionary documents the *raison d'être* of each property, identifying engineering workarounds in the legacy system.

| ID | JSON Key | Intent / "Why it exists" | Confidence |
| :--- | :--- | :--- | :--- |
| 1 | `tamanho` | Maximum length constraint (Oracle VARCHAR limits). | 100% |
| 2 | `lista_valores` | Domain of possible values for ComboBox/Radio selection. | 100% |
| 3 | `mascara` | Input validation and formatting pattern (Regex/Mask). | 100% |
| 4 | `acao` | SQL/PLSQL trigger for dynamic behavior or data retrieval. | 100% |
| 5 | `usado_em` | Meta-counter for layout/document cross-references. | 100% |
| 7 | `editavel` | Runtime boolean flag for input locking (Permissioning). | 100% |
| 8 | `obrigatorio` | Integrity constraint for mandatory form submission. | 100% |
| 9 | `valor_inicial` | Default state instantiation for fresh records. | 100% |
| 10 | `criado_por` | Audit trail for artifact ownership (User Login). | 100% |
| 13 | `acao_texto_padrao`| SQL-driven dynamic label/text generation. | 100% |
| 14 | `texto_padrao` | Static or pre-calculated display content. | 100% |
| 15 | `parametros_texto_padrao`| String interpolation tokens for dynamic labels. | 100% |
| 17 | `reprocessar` | UI refresh trigger for dependency chains. | 100% |
| 22 | `regras_usadas` | Main hub for Composite Pattern logic trees. | 100% |
| 24 | `criado_em` | Temporal data for record creation audit. | 100% |
| 30 | `hint` | UX tooltip/assistive text (ARIA-label precursor). | 100% |
| 31 | `descricao_api` | Technical mapping key for external system integrations. | 100% |
| 33 | `importado` | Boolean flag for external data source origin. | 100% |
| 34 | `migrado` | Status tracker for E2 -> E3 transition progress. | 100% |
| 38 | `cascata_de_regra`| The terminal/non-terminal flag for rule propagation. | 100% |
| 41 | `max_do_grafico` | Upper bound constraint for visualization scales. | 100% |
| 52 | `lista_valores_v3`| Specialized modern domain mapping for Editor 3. | 100% |

## 2. The Behavioral Gaps
### 2.1. Property 22 (Rules) vs Property 4 (Action)
- **Discovery**: Prop 4 is **IMMEDIATE** (SQL Execute). Prop 22 is **DEFERRED** (Logic Tree).
- **Web Mapping**: Prop 4 becomes an `async fetch`. Prop 22 becomes the `rule_lexer` JS output.

### 2.2. Property 9 (Initial Value)
- **Anomaly**: Often contains `NULL` or `' '`. In the Emitter, whitespace `' '` must be preserved as it may trigger SQL `IS NOT NULL` conditions in downstream rules.

## 3. Dark Matter: The "Invisible" Properties
Properties > 1000 (if found in logs) are typically **Vendor Extensions** or **Legacy Scars**:
- **ID 1001/1004**: Persistence/Printing hooks. Rarely used but critical for "Save-and-Close" workflows.

> [!NOTE]
> This dictionary is a living document. Confidence levels should be updated as more `.edt` files are ingested by the Batch Engine.
