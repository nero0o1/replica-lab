# API SPECIFICATION (The Contract)
## Protocol: Titan v2.0

### 1. Command Line Interface (CLI Engine)
The core backend is currently invoked via the `MigrationCore` PowerShell suite.

#### `ImporterV2.ps1`
- **Input**: Path to `.edt` or `.txt` (Legacy V2).
- **Validation**: Checks for `ACED0005` or XML structure.
- **Output**: Returns `[MvDocument]` Object.

#### `DriverV3.ps1`
- **Input**: `[MvDocument]` Object.
- **Action**: Performs MD5 hashing, Matrioska serialization, and Version Sealing.
- **Output**: `.json` file (V3 Modern compliant).

### 2. Data Contract (V3 JSON Schema Highlights)
| Field | Type | Rule |
| :--- | :--- | :--- |
| `identifier` | String | Must be `UPPER_SNAKE_CASE`. |
| `version.hash` | MD5 String | Computed from `layouts[0].content`. |
| `fields[].fieldPropertyValues[].hash` | MD5 String | Hybrid (Static for Bools/Null, Dynamic for Text). |
| `layouts[0].content` | String (JSON) | Minified JSON string (Double Serialized). |

### 3. Error Handling
- **`[FATAL ERROR] Original file not found`**: Exit Code 1.
- **`[FAIL] Java Breaker Protocol Violation`**: ACED0005 found but no XML payload extracted.
- **`[WARNING] Hash Mismatch`**: Integrity check failed (Integridade Violada).

---
*Future Objective: Expose these methods via REST API (/api/v1/convert).*
