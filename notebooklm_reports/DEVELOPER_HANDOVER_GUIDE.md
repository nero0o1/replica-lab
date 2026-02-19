# Developer Handover Guide: Editor MV Hybrid

## 1. Quick Start
To run the migration pipeline and verify structural integrity:

### Mass Migration
```powershell
# Runs on J:\replica_lab\mv_zips_edt_2
powershell -File J:\replica_lab\src\Tools\mass_migrator.ps1
```

### Logical Verification
```powershell
# Verifies metadata priority and LayoutString generation
powershell -File J:\replica_lab\test_structural_final.ps1
```

## 2. Extending the System
When adding a new component type or property:

1. **Rosetta Stone**: Add the new mapping to `src/Core/RosettaStone.ps1`.
   - `static [System.Collections.IDictionary] $Map`: For properties.
   - `static [System.Collections.IDictionary] $LegacyToModernTypeMap`: For visual types.
2. **Canonical Model**: If the new data doesn't fit in the existing `MvField` properties bag, add a specific typed property to `MvField` classes in `src/Core/CanonicalModel.ps1`.
3. **Drivers**:
   - `DriverV2.ps1`: Implement the XML generation logic (respecting bug compatibility).
   - `DriverV3.ps1`: Implement the JSON serialization logic (following schema conventions).

## 3. Dealing with "Bug Compatibility"
The legacy editor is sensitive. If a generated XML fails to open:
- Check if `CD_CAMPO` is repeated inside `<item tableName='EDITOR_CAMPO_PROP_VAL'>`.
- Verify that numeric properties are stored in `<LO_VALOR>` as strings.
- Ensure the XML root is just `<editor>` (the legacy parser often chokes on `<?xml ...?>` declarations).

## 4. Pathing and Modules
**CRITICAL**: Due to PowerShell 5.1 class loading limitations, all `using module` calls in production scripts should use **absolute paths** to avoid `TypeNotFound` errors during execution from different working directories.

## 5. Directory Structure
- `src/Core/`: Central logic and models.
- `src/Drivers/`: Write logic (Export).
- `src/Importers/`: Read logic (Import).
- `src/Tools/`: Operational scripts (Mass Migrator).
- `20_outputs/`: All generated artifacts and test results.
