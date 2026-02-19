# ARCHITECTURE MAP (PROTOCOL TITAN v2.0)
## Status: THE ABSOLUTE TRUTH

This document defines the inviolable boundaries and structural integrity rules for the MV Hybrid Core project.

### 1. Directory Structure and Responsibilities

| Directory | Responsibility | Import Rules |
| :--- | :--- | :--- |
| `j:/replica_lab/src/Core/` | **Canonical Model & Rosetta Stone**. The "Source of Truth". | **Strict**: Must NOT import from Drivers or Importers. |
| `j:/replica_lab/src/Importers/`| **Input Logic**. Consumes V2 (XML/Binary) and populates Core. | Only imports from `Core`. |
| `j:/replica_lab/src/Drivers/` | **Output Logic**. Consumes Core and generates V2 or V3 targets. | Only imports from `Core`. |
| `j:/replica_lab/20_outputs/` | **Artifacts**. Validated migration results. | Read-only for audits. |

### 2. Forbidden Data Flows
- **NO CIRCULAR DEPENDENCIES**: Importers must never know about Drivers.
- **NO BYPASS**: Drivers must never read raw files directly; they always consume the `MvDocument` canonical model.
- **NO FRONTEND SECRETS**: All cryptographic hashing (MD5) MUST remain in the backend (Driver Layer).

### 3. Design Invariants (Inviolable Rules)
1. **The Binary Buffer Law**: Any `.edt` or `.txt` file starting with `ACED0005` MUST be treated as a Java Binary Stream, not a text file.
2. **Matrioska Requirement**: The `layouts.content` field in V3 MUST be stringified JSON (Double Serialization).
3. **SQL Sanctity**: Under no circumstances shall `&`, `<`, or `>` be escaped in SQL action fields (IDs 4, 21).
4. **ID Sanitization**: All identifiers MUST be converted to `UPPER_SNAKE_CASE` during the ingestion phase.
5. **Static Hash Precedence**: Primitives (`true`, `false`, `null`) MUST use the static MD5 lookup table.

### 4. Technology Stack
- **Engine**: PowerShell 5.1 / 7.2 Core.
- **Serialization**: JSON (UTF-8) / XML (Oracle-Compliant).
- **Encoding**: Strict UTF-8 without BOM for all output artifacts.
- **Hashing**: MD5 (Compliance requirement for legacy integrity checks).

---
*Authorized by: Senior Software Architect (Antigravity)*
