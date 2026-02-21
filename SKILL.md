---
name: Antigravity Reconstruction Skill
description: Instructions for reconstructing MV Editor documents from external sources and unifying legacy/modern schemas.
---

# The Antigravity Compendium: System Reconstruction Skill

This skill empowers autonomous agents to reconstruct, unify, and "de-trivialize" the MV Editor ecosystem (Editor II Flow and Editor III).

## 1. Unified Schema Pipeline (Normalization)

Agents must follow this pipeline to move any artifact into the **Canonical Model**:

1.  **Ingestion**:
    - **Editor II (XML)**: Parse the hierarchical tags, extracting `CD_PROPRIEDADE` values.
    - **Editor III (JSON)**: Parse the object graph, resolving semantic identifiers back to their numeric roots.
2.  **Property Resolution (CSS-Less Logic)**:
    - If `DS_CLASSE_CSS` is null in `PAGU_OBJETO_EDITOR`, the agent must rely solely on the `CD_PROPRIEDADE` dictionary.
    - **Clinical Mapping**: All properties must be translated to their clinical utility names (see Forensic Glossary).
3.  **Validation (VT-3)**:
    - Calculate MD5 hashes over the normalized structure.
    - Verify character limits (e.g., Prop 1 `tamanho`) before final serialization.

## 2. External Document Mapping (PDF/Word -> Labels)

To ingest external documents:

1.  **Block Extraction**: Convert Word/PDF text blocks into `MvField` objects.
2.  **Type Mapping**: Assign `CD_PROPRIEDADE = 1` (Label / Static Text) to all initial blocks.
3.  **Spatial Integrity**: Apply the **Crucible Formula** for coordinate transposition:
    - `X_points = (X_pixels / 96) * 72` (Standard PDF Points)
    - `Y_points = (Y_pixels / 96) * 72`
4.  **Skeleton Generation**: Save as a metadata-only artifacts with identifiers matching the source document structure.

## 3. Scripted Component Injection (The Placeholder Engine)

Agents use Python/Java scripts to "bring to life" static skeletons:

1.  **Pattern ID**: Locate Labels with specific semantic markers (e.g., `[ ]`, `( )`, `_________`).
2.  **Replacement**:
    - `[ ]` ➔ Inject `CHECKBOX` (CHB_ prefix).
    - `( )` ➔ Inject `RADIOBUTTON` (RDB_ prefix).
    - `_________` ➔ Inject `TEXT` (TXT_ prefix).
3.  **Persistence**: Update `PAGU_OBJETO_EDITOR` with the new component IDs and set `SN_EDITAVEL = 'S'`.

## 4. Forensic Glossary: De-Trivializing the System

Use these clinical names instead of technical IDs to maintain mission-critical clarity:

| Technical ID/Key | Clinical Utility Name | Forensic Purpose |
| :--- | :--- | :--- |
| **ID 38 / cascata_regra** | `LoopPreventionBit` | Prevents recursive UI crashes during decision-making. |
| **ID 7 / editavel** | `ClinicalLock` | Ensures data sovereignty after medical signature. |
| **ID 8 / obrigatorio** | `IntegrityCheckpoint` | Guards against incomplete patient records. |
| **ID 4 / acao** | `DynamicContextFetch` | Injects real-time patient data into the form. |
| **PAGU_METADADO_P** | `ClinicalMemoryTable` | Where the history of clinical decisions resides. |

## 5. Automated Validation (VT-3 Audit)

After any reconstruction, the agent MUST run:
`python tests/reconstruction_audit.py --file [ARTIFATO]`

This ensures:
- **Hash Stability**: MD5 chain is intact.
- **Field Sovereignty**: No labels were lost during component injection.
- **Constraint Compliance**: All `tamanho` limits are respected.
