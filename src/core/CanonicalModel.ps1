using module "J:\replica_lab\src\Core\RosettaStone.ps1"

# Class: MvDocument
# Represents the Canonical Model (Superset) of a document.
class MvDocument {
    # Identity
    [int] $Id               # V2 CD_DOCUMENTO / V3 data.id
    [string] $Name          # V2 DS_DOCUMENTO / V3 name
    [string] $Identifier    # V3 identifier (Generated from Name if missing in V2)
    [string] $VersionStatus # V3 Only: PUBLISHED/DRAFT
    [int] $Version          # V2/V3 Version Number
    [bool] $Active          # V2 SN_ATIVO / V3 active

    # Security & Forensic Integrity
    [System.Collections.IDictionary] $SecurityBlobs = @{} # C2PA, jumbf, assertions
    [System.Collections.IDictionary] $RawAssets = @{} # Base64 images, logotypes
    [string] $CreatedBy                                  # CD_USUARIO_CRIACAO / criado_por
    [string] $VersionHash                                # version.hash (Seal)

    # Content
    [System.Collections.ArrayList] $Fields = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList] $Groups = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList] $Pages = [System.Collections.ArrayList]::new()

    # Methods
    MvDocument() {
        $this.VersionStatus = "DRAFT" # Default
        $this.Active = $true
    }

    static [string] SanitizeIdentifier([string]$id) {
        if ([string]::IsNullOrWhiteSpace($id)) { return "UNNAMED_OBJ" }
        # Rule: UPPER_SNAKE_CASE
        $sanitized = $id.ToUpper().Trim()
        $sanitized = $sanitized -replace '[^A-Z0-9_]', '_'
        $sanitized = $sanitized -replace '_+', '_'
        return $sanitized.Trim('_')
    }

    [void] AddField([MvField]$field) {
        # Force Sanitization on entry
        $field.Identifier = [MvDocument]::SanitizeIdentifier($field.Identifier)
        $this.Fields.Add($field)
    }
}

# Class: MvField
# Represents a single field definition, abstracting V2/V3 differences.
class MvField {
    # Core Identity
    [int] $IdLegacy         # V2 CD_CAMPO
    [string] $Name          # V2 DS_CAMPO / V3 name
    [string] $Identifier    # V2 DS_IDENTIFICADOR / V3 identifier
    
    # Typing
    [int] $TypeIdLegacy     # V2 CD_TIPO_VISUALIZACAO (1, 2, 3, 4, 7, 11, 12, etc.)
    [int] $TypeIdModern     # V3 visualizationType.id (Calculated via RosettaStone)
    [string] $TypeIdentifier # V3 visualizationType.identifier (Calculated)
    
    # Layout (Coordinates)
    [int] $X
    [int] $Y
    [int] $Width
    [int] $Height

    # Properties (The Bag of Holding)
    # Key: Property Identifier (e.g., 'tamanho', 'mascara')
    # Value: Typed Object (int, string, bool)
    [System.Collections.IDictionary] $Properties = @{}

    # Constructor
    MvField() {
    }

    # Helper to set type based on Legacy ID
    [void] SetTypeFromLegacy([int]$legacyId) {
        $this.TypeIdLegacy = $legacyId
        # Use RosettaStone to map to Modern Type
        try {
            $modernMap = [RosettaStone]::GetModernType($legacyId)
            $this.TypeIdModern = $modernMap.Id
            $this.TypeIdentifier = $modernMap.Identifier
        }
        catch {
            $this.TypeIdModern = $legacyId
            $this.TypeIdentifier = "UNKNOWN_($legacyId)"
        }
    }

    # Helper to set property safely
    [void] SetProperty([string]$key, [object]$value) {
        $this.Properties[$key] = $value
    }
    
    [object] GetProperty([string]$key) {
        if ($this.Properties.Contains($key)) {
            return $this.Properties[$key]
        }
        return $null
    }
}

# Class: MvGroup
# Represents a layout container (V2 Hierarchy or V3 Group)
class MvGroup {
    [string] $Name
    [string] $Type          # V2: G_CAM, G_CAB_ROD / V3: Group type
    [System.Collections.ArrayList] $Children = [System.Collections.ArrayList]::new() # Can be MvFieldRef or MvGroup
}
