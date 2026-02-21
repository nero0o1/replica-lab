# Deconstruction: Flow (Editor II) ➔ Soul (Editor III) Metadata

This report details the "Dark Matter" evolution of form metadata within the MV ecosystem, focusing on the transition from the legacy "Flow" engine to the modern "Soul" engine.

## 1. The CSS-Less Resolution Trap
In the legacy `PAGU_OBJETO_EDITOR` table, the `DS_CLASSE_CSS` field often remains NULL.

- **Forensic Discovery**: When `DS_CLASSE_CSS` is NULL, the Editor II runtime ignores external styling and applies the "Hardcoded Primitive Style" associated with the `CD_TIPO_VISUALIZACAO`.
- **System De-Trivialization**:
    - **TEXT (1)** ➔ `MV-System-Input-Classic` (Gray border, 1px, #CCCCCC).
    - **CHECKBOX (4)** ➔ `MV-System-Toggle-Small`.
- **Reconstruction Rule**: If `DS_CLASSE_CSS` is NULL, the transpilador MUST NOT attempt to search for CSS classes; instead, it should inject the native Editor III semantic equivalent (e.g., `theme: "classic"`).

## 2. Dynamic Table Parity (The Abismo)
Editor II tables (`CD_TIPO_VISUALIZACAO = 35/GRID`) have severe rendering limitations:
- **Legacy Limitation**: No support for "Flex-Grow" or "Auto-Fill". Every column has a fixed width in pixels defined in the `LO_REL_COMPILADO`.
- **Soul Evolution**: Supports percentage-based `flex` columns.
- **Conversion Strategy**: To maintain **Parity Stability**, tables converted from Word/PDF or II ➔ III must default to **Fixed Width (px)** to avoid "Layout Explosion" during medical printing.

## 3. External Mapping Matrix (Word/PDF ➔ MV Labels)

All external content starts its life as a "Label Skeleton".

### 3.1. Crucible Formula (Points Matrix)
External coordinates (standard 72 DPI for PDF / 96 DPI for screen) must be normalized to **MV Virtual Points**:
- $MV\_X = (Source\_X / Source\_DPI) * 96$
- $MV\_Y = (Source\_Y / Source\_DPI) * 96$

### 3.2. Label Character Limits
External text blocks must be sliced to respect Oracle `VARCHAR2(4000)` limits in the `PAGU_METADADO_P` table.
- **Protocol**: If a Word block > 4000 chars, the agent must split it into multiple `MvField` labels positioned sequentially.

## 4. The Placeholder Engine (Pattern Skeletons)
To convert a static Label document into an active form, agents look for these "Clinical Intent Patterns":

| Pattern | Detected Intent | Replacement Component |
| :--- | :--- | :--- |
| `[ ]` | Boolean Toggle | `CHECKBOX` |
| `( )` | Option Selection | `RADIOBUTTON` |
| `__________` (Underscore line) | Free Text Entry | `TEXT (TXT_)` |
| `[__/__/____]` | Temporal Entry | `DATE (DT_)` |

### 5. Integrity Guardians (MD5 & VT-3)
Any scripted injection into the JSON `content` string must trigger a re-calculation of the `version.hash`.
- **MD5 Logic**: `hash = MD5(Minified(PropertyDocumentValues + Layouts))`.
- **Validation**: If the hash is not updated, the Editor III (Soul) will refuse to open the document, citing "Integrity Corruption".
