class LoaderV3 {
    
    # Import Editor 3 JSON to CanonicalForm
    static [CanonicalForm] Import([string]$filePath) {
        
        if (-not (Test-Path -LiteralPath $filePath)) { throw "File not found: $filePath" }
        
        $jsonContent = [System.IO.File]::ReadAllText($filePath)
        $json = ConvertFrom-Json $jsonContent
        
        # Basic Validation
        if (-not $json.data) { throw "Invalid Editor 3 File: Missing 'data' object." }
        
        # Create Form
        # Use filename as name fallback? Or data.name?
        $formName = if ($json.data.name) { $json.data.name } else { [System.IO.Path]::GetFileNameWithoutExtension($filePath) }
        $formId = if ($json.data.identifier) { $json.data.identifier } else { "UNKNOWN_ID" }
        
        $form = [CanonicalForm]::new($formName, $formId)
        
        # Process Fields
        if ($json.data.propertyDocumentValues) {
            foreach ($fData in $json.data.propertyDocumentValues) {
                
                # Create Field
                # Validation Warning: If Identifier doesn't start with prefix, Constructor will throw.
                # We should catch and rebrand? Or fail fast?
                # User Requirement: "Se o usuário criar... sistema deve forçar".
                # For import, we might need lenient mode?
                # Let's try strict. If it fails, we know usage is invalid.
                
                try {
                    $field = [CanonicalField]::new($fData.identifier)
                }
                catch {
                    Write-Warning "Skipping invalid field '$($fData.identifier)': $_"
                    continue
                }
                
                # Process Properties
                if ($fData.propertyValues) {
                    foreach ($pData in $fData.propertyValues) {
                        try {
                            # Resolve ID from Identifier
                            # e.g. "obrigatorio" -> 8
                            $propId = [RosettaStone]::GetId($pData.identifier)
                            
                            # Add Property (CanonicalField will convert types if needed)
                            $field.AddProperty($propId, $pData.value)
                            
                        }
                        catch {
                            Write-Warning "Skipping property '$($pData.identifier)' on field '$($fData.identifier)': $_"
                        }
                    }
                }
                
                $form.AddField($field)
            }
        }
        
        return $form
    }
}
