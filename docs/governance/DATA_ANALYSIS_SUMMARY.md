# DATA ANALYSIS SUMMARY (The Origin of Truth)
## Context: Titan Protocol v2.0

This document summarizes the insights derived from the forensic analysis of 700+ source documents (XML, JSON, Hex Dumps) that justify the current architecture.

### 1. Key Forensic Insights
- **The Binary Shift**: Discovered that 30% of legacy "text" files were actually serialized Java Objects (`ACED0005`). This necessitated the "Java Breaker" scrubber in `ImporterV2`.
- **Double Serialization (Matrioska)**: Analysis of internal Editor 3 packets revealed that layout content is not a nested object, but a stringified JSON blob. Bypassing this causes the "White Screen" failure in React.
- **Forensic ID Mapping**: Identified specific legacy IDs that control critical business logic:
    - **ID 21 (`acaoSql`)**: Mandatory raw text (No-Escape).
    - **ID 35 (`tipo_do_grafico`)**: Controls layout rendering for lists.
    - **ID 2 (`listas`)**: Nested table structures.

### 2. Canonical Model (Schema)
The analysis consolidated the following canonical schema for the `MvDocument` object:
- **Identity**: `Id`, `Name`, `Identifier` (Sanitized), `Version`, `Active`.
- **Governance**: `CreatedBy`, `VersionStatus`, `VersionHash` (Seal).
- **Structure**: `Fields` (ArrayList), `Groups` (ArrayList), `RawAssets` (for Image preservation).

### 3. Business Rules Derived from Data
- **The Migrador® Exception**: Historical data shows that records created by the "Migrador®" system account use a null-string MD5 hash (`d41d8cd98f00b204e9800998ecf8427e`) instead of the standard dynamic calculation.
- **Universal Boolean Table**: The MV engine uses fixed MD5 hashes for primitives to ensure cross-database compatibility:
    - `true`  -> `b326b5062b2f0e69046810717534cb09`
    - `false` -> `68934a3e9455fa72420237eb05902327`
    - `null`  -> `37a6259cc0c1dae299a7866489dff0bd`

---
*Generated based on Deep-Dive Forensics (Sources 1-700).*
