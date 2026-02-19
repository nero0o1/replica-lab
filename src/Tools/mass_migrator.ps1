# Mass Migrator Tool
# Usage: powershell -File src/Tools/mass_migrator.ps1

# Dependencies
. "$PSScriptRoot\..\Core\RosettaStone.ps1"
. "$PSScriptRoot\..\Core\CanonicalModel.ps1"
. "$PSScriptRoot\..\Importers\ImporterV2.ps1"
. "$PSScriptRoot\..\Drivers\DriverV3.ps1"
. "$PSScriptRoot\..\Importers\ImporterV3.ps1" # For verification

# Configuration
$sourceDir = "J:\replica_lab\mv_zips_edt_2"
$outputBaseDir = "J:\replica_lab\20_outputs\mass_migration"
$tempDir = "J:\replica_lab\20_outputs\_TEMP_PROCESS"
$logFile = "$outputBaseDir\migration_report.log"

# Init
if (-not (Test-Path $outputBaseDir)) { New-Item -ItemType Directory -Force -Path $outputBaseDir | Out-Null }
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Force -Path $tempDir | Out-Null }
New-Item -ItemType File -Force -Path $logFile | Out-Null

function Log($msg, $type = "INFO") {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$type] $msg"
    Add-Content -Path $logFile -Value $line
    $color = "Gray"
    if ($type -eq "ERROR") { $color = "Red" }
    elseif ($type -eq "SUCCESS") { $color = "Green" }
    elseif ($type -eq "WARN") { $color = "Yellow" }
    Write-Host $line -ForegroundColor $color
}

Log "STARTING MASS MIGRATION"
Log "Source: $sourceDir"
Log "Output: $outputBaseDir"

# Get ZIPs
$zips = Get-ChildItem -Path $sourceDir -Filter "*.zip"
Log "Found $($zips.Count) ZIP files to process."

$stats = @{ Success = 0; Fail = 0; Total = 0 }

foreach ($zip in $zips) {
    $stats.Total++
    Log "Processing $($zip.Name)..."
    
    try {
        # 1. Clear Temp
        Get-ChildItem -Path $tempDir -Recurse | Remove-Item -Recurse -Force
        
        # 2. Extract Main ZIP
        Expand-Archive -Path $zip.FullName -DestinationPath $tempDir -Force
        
        # 3. Handle Russian Doll ZIPs
        $functionalZips = Get-ChildItem -Path $tempDir -Filter "*.zip"
        if ($functionalZips.Count -gt 0) {
            Log "   -> Detected nested ZIPs. Extracting 5.documentos.zip..."
            $docZip = Get-ChildItem -Path $tempDir -Filter "5.documentos.zip"
            if ($docZip) {
                Expand-Archive -Path $docZip.FullName -DestinationPath $tempDir -Force
            }
            else {
                Log "   -> 5.documentos.zip not found, skipping nested extraction." "WARN"
            }
        }
        
        # 4. Find Input File (XML, EDT or tempfile0)
        $inputFiles = Get-ChildItem -Path $tempDir -File
        $targetFile = $null
        
        foreach ($f in $inputFiles) {
            if ($f.Extension -eq ".xml" -or $f.Extension -eq ".edt") { $targetFile = $f; break }
            if ($f.Name -like "tempfile*") { $targetFile = $f } # Fallback
        }
        
        if (-not $targetFile) {
            throw "No suitable input file (.xml, .edt, tempfile*) found in ZIP hierarchy."
        }
        
        Log "   -> Input: $($targetFile.Name)"
        
        # 5. Import V2
        $importer = [ImporterV2]::new($targetFile.FullName)
        $doc = $importer.Import()
        
        # 5. Export V3
        $jsonName = "$($zip.BaseName).json"
        $jsonPath = "$outputBaseDir\$jsonName"
        $driver = [DriverV3]::new($jsonPath)
        $driver.Export($doc)
        
        # 6. Verify (Read Back)
        $verifier = [ImporterV3]::new($jsonPath)
        $checkDoc = $verifier.Import()
        
        if ($checkDoc.Fields.Count -ne $doc.Fields.Count) {
            Log "   -> WARNING: Field count mismatch (Original: $($doc.Fields.Count), JSON: $($checkDoc.Fields.Count))" "WARN"
        }
        
        Log "   -> SUCCESS. Saved to $jsonName" "SUCCESS"
        $stats.Success++
    }
    catch {
        Log "   -> FAILED: $($_.Exception.Message)" "ERROR"
        $stats.Fail++
    }
}

Log "MIGRATION COMPLETE."
Log "Total: $($stats.Total)"
Log "Success: $($stats.Success)"
Log "Fail: $($stats.Fail)"
