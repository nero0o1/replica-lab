# MASTER RULE (Operational Manual)

> [!IMPORTANT]
> **GOVERNANCE OVERRIDE**
> This file contains the primary directive for any AI Agent working on this repository.

### 1. Hierarchy of Truth
Before implementing any feature or change, you MUST consult these documents in order:
1. `docs/governance/ARCHITECTURE_MAP.md` (Design Constraints).
2. `docs/governance/DATA_ANALYSIS_SUMMARY.md` (Domain Knowledge).
3. `docs/governance/API_SPECIFICATION.md` (Operational Contract).

### 2. Escalation Protocol
- **CONFLICTS**: If a user requirement conflicts with a Rule in the `ARCHITECTURE_MAP.md` (e.g., asking to remove double-serialization), you MUST:
    1. **PAUSE** implementation.
    2. **ALERT** the user about the risk of "Context Rot" and "System Breakdown".
    3. **ASK** for explicit human confirmation of the architectural override.

### 3. Preservation of Context
- **No Agent Drift**: Do not refactor core modules (`ImporterV2`, `DriverV3`) without verifying that forensic MD5 signatures are preserved.
- **Sanitizer Law**: Never bypass the `UPPER_SNAKE_CASE` sanitizer.

---
*FAIL-SAFE: If this document is deleted or modified without authorization, the system state is considered COMPROMISED.*
