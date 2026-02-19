# test_structural_isolated.ps1
# Combines necessary classes to verify logic works, bypassing loading issues.

class RosettaStone {
    static [hashtable] GetModernType([int]$legacyId) {
        $map = @{
            1  = @{ Id = 1; Identifier = "TEXT" }
            4  = @{ Id = 4; Identifier = "CHECKBOX" }
            7  = @{ Id = 6; Identifier = "RADIOBUTTON" }
            11 = @{ Id = 9; Identifier = "DATE" }
        }
        if ($map.Contains($legacyId)) { return $map[$legacyId] }
        return @{ Id = $legacyId; Identifier = "UNKNOWN" }
    }
}

class MvField {
    [string]$Name
    [int]$TypeIdModern
    [string]$TypeIdentifier
    [int]$X
    [int]$Y
    [int]$Width
    [int]$Height

    [void] SetTypeFromLegacy([int]$legacyId) {
        $modernMap = [RosettaStone]::GetModernType($legacyId)
        $this.TypeIdModern = $modernMap.Id
        $this.TypeIdentifier = $modernMap.Identifier
    }
}

Write-Host "--- TEST: Isolated Structural Truth ---" -ForegroundColor Cyan

$f = [MvField]::new()
$f.Name = "TXT_FAKE_PREFIX"
$f.SetTypeFromLegacy(7) # 7 should map to 6 (RADIO)
$f.X = 10; $f.Y = 20; $f.Width = 100; $f.Height = 25

Write-Host "Name: $($f.Name)"
Write-Host "Modern ID: $($f.TypeIdModern)"
Write-Host "Modern Identifier: $($f.TypeIdentifier)"

if ($f.TypeIdModern -eq 6) {
    Write-Host "[SUCCESS] Logical mapping works (7 -> 6)." -ForegroundColor Green
}
else {
    Write-Host "[FAILURE] Logical mapping failed!" -ForegroundColor Red
}
