# using module "..\Core\CanonicalModel.ps1"
# using module "..\Core\RosettaStone.ps1"

class ImporterV3 {
    [string] $InputPath

    ImporterV3([string]$inputPath) {
        $this.InputPath = $inputPath
    }

    [object] Import() {
        if (-not (Test-Path $this.InputPath)) {
            throw "File not found: $($this.InputPath)"
        }

        $jsonContent = Get-Content -Path $this.InputPath -Raw -Encoding UTF8
        $json = ConvertFrom-Json $jsonContent

        $doc = [MvDocument]::new()
        
        # 1. Identity
        $doc.Name = $json.name
        $doc.Identifier = $json.identifier
        $doc.VersionStatus = $json.versionStatus
        $doc.Version = $json.version
        
        if ($json.data) {
            $doc.Id = $json.data.id
            $doc.Active = $json.data.active
        }
        
        # 2. Fields
        if ($json.fields) {
            foreach ($fJson in $json.fields) {
                $this.ParseField($doc, $fJson)
            }
        }

        # 3. Groups (Hierarchy)
        # TODO: Recursive parse of $json.groups
        
        return $doc
    }

    [void] ParseField($doc, [object]$fJson) {
        $f = [MvField]::new()
        $f.Name = $fJson.name
        $f.Identifier = $fJson.identifier
        
        # Type Logic
        if ($fJson.visualizationType) {
            # In V3 import, we might assume ID is correct or map back
            # Ideally Canonical Model should store both. 
            # If we only have Modern ID, we might need Reverse Map to get Legacy ID?
            # For now, let's assume we can map back if needed or store Modern ID.
            $f.TypeIdModern = $fJson.visualizationType.id
            $f.TypeIdentifier = $fJson.visualizationType.identifier
            
            # Simple Reverse Map for Legacy ID (Heuristic)
            # This is tricky because 1:1 isn't always true. 
            # But usually Modern ID X maps to Legacy ID X, except for the Shifted ones (6->7, 9->11, 10->12).
            # We will implement a basic reverse lookup in RosettaStone or here later.
            $f.IdLegacy = $fJson.visualizationType.id # Placeholder default
            if ($f.TypeIdModern -eq 6) { $f.IdLegacy = 7 }
            if ($f.TypeIdModern -eq 9) { $f.IdLegacy = 11 }
            if ($f.TypeIdModern -eq 10) { $f.IdLegacy = 12 }
        }

        # Properties
        if ($fJson.fieldPropertyValues) {
            foreach ($propVal in $fJson.fieldPropertyValues) {
                $key = $propVal.property.identifier
                $val = $propVal.value
                
                # V3 Dates are usually ISO 8601 Strings, keep as string or converting to Date?
                # Canonical Model implies Typed Objects.
                # If string looks like Date, parse it? Or rely on Property definition?
                # For now, keep generic.
                
                $f.SetProperty($key, $val)
            }
        }

        $doc.AddField($f)
    }
}
