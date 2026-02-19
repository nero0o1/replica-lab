# Verification Script: Phase 10 (Binary & Matrioska)

# Import Core Classes
. "$PSScriptRoot\src\Core\CanonicalModel.ps1"
. "$PSScriptRoot\src\Core\RosettaStone.ps1"
. "$PSScriptRoot\src\Importers\ImporterV2.ps1"
. "$PSScriptRoot\src\Drivers\DriverV3.ps1"

$testFileV2 = "J:\replica_lab\tempfile0.txt"
$testOutputV3 = "J:\replica_lab\20_outputs\v10_test_output.json"

Write-Host "--- TEST 1: Binary Scrubbing (V2) ---" -ForegroundColor Yellow
try {
    $importer = [ImporterV2]::new($testFileV2)
    $doc = $importer.Import()
    Write-Host "[SUCCESS] File tempfile0.txt parsed correctly despite binary header." -ForegroundColor Green
    Write-Host "Document ID: $($doc.Id)"
    Write-Host "Field Count: $($doc.Fields.Count)"
}
catch {
    Write-Host "[FAILURE] Binary scrubbing failed: $_" -ForegroundColor Red
}

Write-Host "`n--- TEST 2: Matrioska Serialization (V3) ---" -ForegroundColor Yellow
try {
    # Add a mock field to verify layout stringification
    if ($null -eq $doc) { throw "Skipping Test 2 as Test 1 failed." }
    
    $driver = [DriverV3]::new($testOutputV3)
    $driver.Export($doc)
    
    # Load the generated JSON and verify 'content' is a string
    $json = Get-Content $testOutputV3 -Raw | ConvertFrom-Json
    $layout = $json.layouts[0]
    
    if ($layout.content -is [string]) {
        Write-Host "[SUCCESS] layout.content is a STRING (Double Serialization confirmed)." -ForegroundColor Green
        
        # Verify it can be parsed back to an object
        $innerJson = $layout.content | ConvertFrom-Json
        if ($innerJson.pageBody) {
            Write-Host "[SUCCESS] layout.content parsed correctly into pageBody." -ForegroundColor Green
        }
        else {
            Write-Host "[FAILURE] Inner JSON missing pageBody." -ForegroundColor Red
        }
    }
    else {
        Write-Host "[FAILURE] layout.content is NOT a string. White screen risk detected." -ForegroundColor Red
    }
}
catch {
    Write-Host "[FAILURE] Matrioska test failed: $_" -ForegroundColor Red
}

Write-Host "`n--- TEST 3: Forensic IDs (RosettaStone) ---" -ForegroundColor Yellow
try {
    $acaoSqlId = [RosettaStone]::GetId("acaoSql")
    $chartId = [RosettaStone]::GetId("tipo_do_grafico")
    
    if ($acaoSqlId -eq 21 -and $chartId -eq 35) {
        Write-Host "[SUCCESS] Forensic IDs correctly mapped (21=acaoSql, 35=tipo_do_grafico)." -ForegroundColor Green
    }
    else {
        Write-Host "[FAILURE] Forensic ID mismatch: acaoSql=$acaoSqlId, chart=$chartId" -ForegroundColor Red
    }
}
catch {
    Write-Host "[FAILURE] RosettaStone lookup failed: $_" -ForegroundColor Red
}

Write-Host "`nVerification Completed." -ForegroundColor Cyan
