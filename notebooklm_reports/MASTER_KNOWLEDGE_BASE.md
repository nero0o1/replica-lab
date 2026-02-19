# MASTER KNOWLEDGE BASE: Editor MV Forensic & Hybrid Architecture

> [!IMPORTANT]
> This document is the **Ultimate Source of Truth** for the Editor MV Hybrid project. It contains consolidated technical details from all forensic audits (05_A through 05_F) designed for deep analysis via NotebookLM.

---

## 1. Project Mission & Architecture
The project addresses the transition from a **Legacy Delphi Editor (V2)** to a **Modern Web Editor (V3)**.

### 1.1 Dual-Driver Strategy
To handle the transition, the system uses a **Hybrid Core** with:
- **ImporterV2**: Parses XML files (ROWSET/ROW) and normalizes them into a `CanonicalModel`.
- **ImporterV3**: Parses JSON files and loads them into the same `CanonicalModel`.
- **DriverV2**: Generates legacy-compatible XML, replicating necessary "bug features" and redundancies.
- **DriverV3**: Generates modern JSON with advanced features (Grid, Chart, SHA256 hashing).

---

## 2. Structural Truth: The Rosetta Stone
The most critical element is the mapping between the numeric legacy IDs and the modern textual identifiers.

### 2.1 Visualization Types (CD_TIPO_VISUALIZACAO)
| Visual Type | V2 ID | V3 ID | V3 Identifier | Notes |
| :--- | :---: | :---: | :--- | :--- |
| **Texto** | 1 | 1 | `TEXT` | Default alphanumeric. |
| **Caixa de Texto** | 2 | 2 | `TEXTAREA` | Multi-line text. |
| **ComboBox** | 3 | 3 | `COMBOBOX` | Single selection list. |
| **CheckBox** | 4 | 4 | `CHECKBOX` | **Verified**: Native in both. |
| **Marcação Imagem**| - | 5 | `IMAGEMARKER` | V3 Exclusive. |
| **Radio Button** | 7 | 6 | `RADIOBUTTON` | **SHIFT**: 7 -> 6. |
| **Botão** | 10 | 7 | `BUTTON` | **SHIFT**: 10 -> 7. |
| **Código Barras** | - | 8 | `BARCODE` | V3 Exclusive (Prop: 19, 20). |
| **Data** | 11 | 9 | `DATE` | **SHIFT**: 11 -> 9. Oracle Format. |
| **Imagem** | 12 | 10 | `IMAGE` | **SHIFT**: 12 -> 10. |
| **Texto Formatado** | - | 12 | `FORMATTEDTEXT`| V3 Exclusive. |
| **Gráfico (Chart)** | - | 26 | `CHART` | V3 Exclusive (Prop: 26). |
| **Hyperlink** | - | 28 | `HYPERLINK` | V3 Exclusive. |
| **Tabela (Grid)** | - | 35 | `GRID` | V3 Exclusive. |
| **Audiometria** | - | 36 | `AUDIOMETRY` | V3 Exclusive. |

### 2.2 Property Dictionary (CD_PROPRIEDADE)
| ID | Key (V3) | Type | Forensic Importance |
| :--- | :--- | :--- | :--- |
| 1 | `tamanho` | Int | Max length. |
| 2 | `lista_valores`| Array | **GAP FIX**: Tabela aninhada, não pipe-string. |
| 3 | `mascara` | Str | Determines subtypes (CPF, CEP). **Never** force to Number. |
| 8 | `obrigatorio` | Bool | V2 uses `true/false` string, DriverV2 filters per version. |
| 21 | `acaoSql` | Str | **GAP FIX**: Código SQL puro para eventos. |
| 35 | `tipo_do_grafico`| Str | **GAP FIX**: Especificação do componente de gráfico/grid. |
| 38 | `cascata_de_regra`| Bool | Rule propagation logic. |

---

## 3. Data Integrity & Security (The Hash Algorithm)
Editor 3 uses a strict hash-based integrity check to prevent manual modification of files.

### 3.1 Version Hash (MD5)
Generated for the entire document using:
1.  **Normalization**: All bools converted to `true/false`, dates to `YYYY-MM-DD`, nulls to `null`.
2.  **Concatenation**: Strategic properties are joined in a fixed order.
3.  **Hashing**: `MD5` (32 characters, lowercase).

### 3.2 Field Integrity
Each field has an individual `hash`. If the properties change and the hash is not updated, the modern editor rejects the component as "Corrupted".

---

## 4. Forensic Anatomy: Core Differences

### 4.1 Serialization Formats
- **V2 (XML)**: Uses `<ROWSET><ROW>` structure. Highly redundant.
    - **Critical Requirement**: Field ID (`CD_CAMPO`) must be repeated in every property row.
    - **Hierarchy**: Defined at the end of the file in `<hierarchy><group>`.
- **V3 (JSON)**: Focused on rendering.
    - **Groups**: Fields are nested inside `groups` with coordinated `row/col` values.
    - **Pages**: Explicit `pages` array for multi-page forms.

### 4.2 Layout Engineering
- **V2**: Strict grid-based indexing (`NR_LINHA`, `NR_COLUNA`).
- **V3**: Serialized string `layout: "X,Y,W,H"` where X/Y are coordinate values.
- **Mapping Formula**: `DriverV3` calculates the string by multiplying grid indices by a scale factor or absolute pixel values (Forensic discovery: V2 uses ~20px units per grid cell).

---

### 5.1 GAPs Forenses & "Bloqueios" Binários
| GAP | Descrição | Regra de Ouro |
| :--- | :--- | :--- |
| **ACED0005** | Objeto Java Serializado | **Fato**: O arquivo `.edt` V2 é um binário Java (Magic Number). Requer Binary Scrubbing. |
| **Matrioska** | V3 Layout Content | **Fato**: `layouts.content` é uma String JSON escapada (Double Serialization). |
| **Hashes** | V3 Integridade | **Fato**: `true`=b326..., `0`=cfcd..., `false`=6893... |
| **Lista V2** | complex_list | **Fato**: ID 2 não é pipe-string, é tabela aninhada no XML/Binário. |

---

## 6. Directory Map (Source of Artifacts)
- **Anatomy**: [05_E](file:///C:/Users/timne/.gemini/antigravity/brain/49f5768f-7e9d-44f0-8b97-1e886e3f9874/05_E_Anatomia_Detalhada_e_Layouts.md)
- **IDs & Rosetta**: [05_F](file:///C:/Users/timne/.gemini/antigravity/brain/49f5768f-7e9d-44f0-8b97-1e886e3f9874/05_F_Anatomia_Comparada_Integral.md)
- **Properties**: [05_B](file:///C:/Users/timne/.gemini/antigravity/brain/49f5768f-7e9d-44f0-8b97-1e886e3f9874/05_B_Dicionario_Mestre_de_Propriedades.md)
- **Migration Results**: [Walkthrough](file:///C:/Users/timne/.gemini/antigravity/brain/49f5768f-7e9d-44f0-8b97-1e886e3f9874/walkthrough.md)
