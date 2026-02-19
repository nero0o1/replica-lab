# Test Dual-Driver Architecture
# using module ".\src\Core\CanonicalModel.ps1"
# using module ".\src\Drivers\DriverV2.ps1"
# using module ".\src\Drivers\DriverV3.ps1"

# Manual Loading Pattern (Robust for PS 5.1)
. "$PSScriptRoot\src\Core\RosettaStone.ps1"
. "$PSScriptRoot\src\Core\CanonicalModel.ps1"
. "$PSScriptRoot\src\Drivers\DriverV2.ps1"
. "$PSScriptRoot\src\Drivers\DriverV3.ps1"

$outputDir = "J:\replica_lab\20_outputs\dual_driver_test"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$logFile = "$outputDir\test_log.txt"
function Log($msg) {
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

Log "1. Creating Canonical Model..."
$doc = [MvDocument]::new()
$doc.Id = 999
$doc.Name = "TEST_DUAL_DRIVER"
$doc.Identifier = "TEST_DUAL_DRIVER"
$doc.Version = 1

# Add a Checkbox Field (The Star of the Show)
$f = [MvField]::new()
$f.IdLegacy = 500
$f.Name = "Sn_Aceite"
$f.Identifier = "SN_ACEITE"
$f.SetTypeFromLegacy(4) # Legacy 4 -> Modern 4 (Checkbox)

# Set Properties
$f.SetProperty("obrigatorio", $true)   # Should be 'true' in XML (v2 heuristic)
$f.SetProperty("editavel", $false)     # Should be 'false' in XML
$f.SetProperty("reprocessar", $true)   # Should be 'S' in XML
$f.SetProperty("tamanho", 1)

$doc.AddField($f)

Log "2. Exporting via Driver V2 (Legacy XML)..."
try {
    $v2Driver = [DriverV2]::new("$outputDir\test_output_v2.xml")
    $v2Driver.Export($doc)
    Log "   -> V2 Exported to $outputDir\test_output_v2.xml"
}
catch {
    Log "   !!! V2 EXPORT FAILED: $($_.Exception.Message)"
    Log "   !!! StackTrace: $($_.Exception.StackTrace)"
}

Log "3. Exporting via Driver V3 (Modern JSON)..."
try {
    $v3Driver = [DriverV3]::new("$outputDir\test_output_v3.json")
    $v3Driver.Export($doc)
    Log "   -> V3 Exported to $outputDir\test_output_v3.json"
}
catch {
    Log "   !!! V3 EXPORT FAILED: $($_.Exception.Message)"
}

Log "Done."
