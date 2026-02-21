# 09 Oracle Shadow Logic & SmartDB Integration

## 1. Executive Summary
This document details the implicit logic residing in the Oracle database layer that dictates the behavioral state of the MV Editor UI. These patterns are critical for mimetizing legacy behavior in standalone web environments.

## 2. Oracle Data Types vs. JS Emitter
The conversion from Oracle primitives to JavaScript must follow strict coercion rules to avoid "Logic Drift":

| Oracle Type | Logic Constraint | Emitter Mapping |
| :--- | :--- | :--- |
| `VARCHAR2(4000)` | Standard field. Truncation at 4000 chars. | `string` |
| `LONG RAW` | Used for legacy blobs. High memory cost. | `Uint8Array` / `base64` |
| `NUMBER(1,0)` | Usually acts as a boolean flag. | `boolean` (0=false, 1=true) |
| `CLOB` | Used for SQL actions (ID 4/21). | `string` (Quarantined if > 2KB) |

## 3. The Variable Injection Pattern (`SmartDB`)
Legacy Oracle SmartDB behaviors use the `&<PAR_NAME>` macro for session injection.

### 3.1. Critical Vectors
- `&<PAR_CD_ATENDIMENTO>`: Injected during `ON_LOAD`.
- `&<PAR_USUARIO_LOGADO>`: Security context.
- `&<PAR_CD_PACIENTE>`: Patient isolation (HIPAA/LGPD critical).

> [!WARNING]
> **PII Disclosure Risk**: In a web environment, these variables must be resolved server-side. The `VanillaWebEmitter` must never expose raw SQL containing these macros to the browser console.

## 6. OPAQUE_SCRIPT: Fail-State Enforcement
When a PL/SQL block is identified as `OPAQUE_SCRIPT` (Keywords: `DECLARE`, `BEGIN`, `CURSOR`), the Emitter enforces a Safety Sandbox:

### 6.1 UI Fallback Rules
- **Quarantine Tag**: The HTML component MUST include `data-quarantined="true"`.
- **Visual Alert**: Injected `title` attribute: `"Automated Logic Transfer Quarantined: This field depends on complex PL/SQL that requires manual review in the MV Core."`
- **Logic State**: The field enters **STRICT READ-ONLY** mode if the rule intent was `ENABLE`/`DISABLE`, as the state cannot be determined safely client-side.
- **CSS Enforcement**:
```css
[data-quarantined="true"] {
    border-left: 4px solid #f39c12 !important;
    background-color: rgba(243, 156, 18, 0.05) !important;
    cursor: help;
}
```

## 4. Trigger Implicit Hierarchy
The MV runtime executes triggers in a determined sequence that must be replicated in JS:
1. `ON_LOAD`: Initial visibility/enable state.
2. `FETCH_SQL`: Population of ComboBoxes.
3. `ON_CHANGE`: Recursive cascaded rules.
4. `ON_SAVE`: Final validation/block.

## 5. Shadow Reentrancy (Property 38)
- **Attribute**: `cascata_de_regra`.
- **Logic**: If `false`, the rule is terminal. If `true`, the rule triggers a change event on the target, potentially starting a cascade.
- **Confidence**: 95% (Verified via `REGRAS_MV.md`).
