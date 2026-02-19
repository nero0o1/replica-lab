# Fire Test: Forensic Comparison (Phase 10) - HARDENED

# 1. Setup Environment (Absolute Paths)
$BaseDir = "J:\replica_lab"
. "$BaseDir\src\Core\CanonicalModel.ps1"
. "$BaseDir\src\Core\RosettaStone.ps1"
. "$BaseDir\src\Importers\ImporterV2.ps1"
. "$BaseDir\src\Drivers\DriverV2.ps1"
. "$BaseDir\src\Drivers\DriverV3.ps1"

$originalV2 = "$BaseDir\tempfile0.txt"
$genV2 = "$BaseDir\20_outputs\fire_test_legacy.edt"
$genV3 = "$BaseDir\20_outputs\fire_test_modern.json"

if (-not (Test-Path "$BaseDir\20_outputs")) { New-Item -ItemType Directory -Path "$BaseDir\20_outputs" -Force }

Write-Host ">>> PHASE 1: IMPORTING ORIGINAL BINARY SOURCE <<<" -ForegroundColor Cyan
try {
    $importer = [ImporterV2]::new($originalV2)
    $doc = $importer.Import()
    Write-Host "Original Stats:" -ForegroundColor Green
    Write-Host "- Document: $($doc.Name) (ID: $($doc.Id))"
    Write-Host "- Fields Detected: $($doc.Fields.Count)"
}
catch {
    Write-Host "[FATAL ERROR] Import failed: $_" -ForegroundColor Red
    exit
}

Write-Host "`n>>> PHASE 2: GENERATING LEGACY MODEL (BINARY MOCK) <<<" -ForegroundColor Cyan
try {
    $dv2 = [DriverV2]::new($genV2)
    $dv2.Export($doc, $true) # true = Use Binary Header ACED0005
    $genBytes = [System.IO.File]::ReadAllBytes($genV2)
    if ($genBytes[0] -eq 0xAC -and $genBytes[1] -eq 0xED) {
        Write-Host "[SUCCESS] Generated legacy file has the ACED0005 Java Magic Number." -ForegroundColor Green
    }
    else {
        Write-Host "[FAILURE] Missing Binary Magic Number." -ForegroundColor Red
    }
}
catch {
    Write-Host "[ERROR] Legacy generation failed: $_" -ForegroundColor Red
}

Write-Host "`n>>> PHASE 3: GENERATING MODERN MODEL (MATRIOSKA) <<<" -ForegroundColor Cyan
try {
    $dv3 = [DriverV3]::new($genV3)
    $dv3.Export($doc)
    $json = Get-Content $genV3 -Raw | ConvertFrom-Json
    if ($json.layouts[0].content -is [string]) {
        Write-Host "[SUCCESS] layout.content is a Double-Serialized string." -ForegroundColor Green
        # Verify parseability
        $inner = $json.layouts[0].content | ConvertFrom-Json
        if ($inner.pageBody) { Write-Host "[SUCCESS] Double-Parse verified." -ForegroundColor Green }
    }
    else {
        Write-Host "[FAILURE] layout.content type mismatch." -ForegroundColor Red
    }
}
catch {
    Write-Host "[ERROR] Modern generation failed: $_" -ForegroundColor Red
}

Write-Host "`n>>> PHASE 4: FORENSIC PROPERTY COMPARISON <<<" -ForegroundColor Cyan
if ($doc.Fields.Count -gt 0) {
    $sampleField = $doc.Fields[0]
    Write-Host "Field: $($sampleField.Name) ($($sampleField.Identifier))" -ForegroundColor Yellow
    foreach ($key in $sampleField.Properties.Keys) {
        Write-Host "  - Property [$key]: $($sampleField.Properties[$key])"
    }
}

Write-Host "`n>>> FIRE TEST COMPLETE <<<" -ForegroundColor Cyan
