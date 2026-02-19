# Test Round-Trip (V2 -> Model -> V2 & V3)
# Dependencies (Dot-Sourcing for Robustness)
. "$PSScriptRoot\src\Core\RosettaStone.ps1"
. "$PSScriptRoot\src\Core\CanonicalModel.ps1"
. "$PSScriptRoot\src\Drivers\DriverV2.ps1"
. "$PSScriptRoot\src\Drivers\DriverV3.ps1"
. "$PSScriptRoot\src\Importers\ImporterV2.ps1"
. "$PSScriptRoot\src\Importers\ImporterV3.ps1"

$inputDir = "J:\replica_lab\20_outputs\dual_driver_test"
$outputDir = "J:\replica_lab\20_outputs\round_trip_test"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$logFile = "$outputDir\round_trip_log.txt"
function Log($msg) {
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Write-Host $msg
}

Log "STARTING ROUND TRIP TEST"

# 1. Use the V2 XML generated in previous step as Input
$inputFile = "$inputDir\test_output_v2.xml"
if (-not (Test-Path $inputFile)) {
    Log "FATAL: Input file $inputFile not found. Run test_dual_driver.ps1 first."
    exit
}

Log "1. Importing V2 XML: $inputFile"
try {
    $importer = [ImporterV2]::new($inputFile)
    $doc = $importer.Import()
    Log "   -> Import Success. Document: $($doc.Name) (ID: $($doc.Id))"
    Log "   -> Field Count: $($doc.Fields.Count)"
    foreach ($f in $doc.Fields) {
        Log "      - Field: $($f.Name) (LegacyID: $($f.IdLegacy))"
        Log "        Properties: $($f.Properties.Keys -join ', ')"
    }
}
catch {
    Log "   !!! IMPORT FAILED: $($_.Exception.Message)"
    Log "   !!! StackTrace: $($_.Exception.StackTrace)"
    exit
}

# 2. Export back to V2 (Should be identical or cleaner)
Log "2. Re-Exporting to V2 (Round Trip)..."
try {
    $v2Driver = [DriverV2]::new("$outputDir\round_trip_v2.xml")
    $v2Driver.Export($doc)
    Log "   -> Exported to $outputDir\round_trip_v2.xml"
}
catch {
    Log "   !!! EXPORT V2 FAILED: $($_.Exception.Message)"
}

# 3. Export to V3 (Modern)
Log "3. Exporting to V3..."
try {
    $v3Driver = [DriverV3]::new("$outputDir\round_trip_v3.json")
    $v3Driver.Export($doc)
    Log "   -> Exported to $outputDir\round_trip_v3.json"
}
catch {
    Log "   !!! EXPORT V3 FAILED: $($_.Exception.Message)"
}

Log "DONE."
