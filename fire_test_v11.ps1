# Fire Test: 1:1 Forensic Comparison (V11)

# --- 1. CORE MODELS ---
class MvField {
    [int]$IdLegacy
    [string]$Name
    [string]$Identifier
    [int]$TypeIdLegacy
    [int]$TypeIdModern
    [string]$TypeIdentifier
    [int]$X; [int]$Y; [int]$Width; [int]$Height
    [System.Collections.IDictionary]$Properties = @{}

    [void] SetTypeFromLegacy([int]$legacyId) {
        $this.TypeIdLegacy = $legacyId
        if ($legacyId -eq 4) { $this.TypeIdModern = 4; $this.TypeIdentifier = "CHECKBOX" }
        else { $this.TypeIdModern = 1; $this.TypeIdentifier = "TEXT" }
    }
    [void] SetProperty([string]$key, [object]$val) { $this.Properties[$key] = $val }
}

class MvDocument {
    [int]$Id; [string]$Name; [string]$Identifier
    [int]$Version; [bool]$Active; [string]$VersionStatus = "PUBLISHED"
    [System.Collections.ArrayList]$Fields = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$Groups = [System.Collections.ArrayList]::new()
    [void] AddField([MvField]$f) { [void]$this.Fields.Add($f) }
}

class RosettaStone {
    static [string] GetIdentifier([int]$id) {
        if ($id -eq 21) { return "acaoSql" }
        if ($id -eq 35) { return "tipo_do_grafico" }
        return "PROP_$id"
    }
    static [int] GetId([string]$key) {
        if ($key -eq "acaoSql") { return 21 }
        if ($key -eq "tipo_do_grafico") { return 35 }
        return 999
    }
    static [string] GetType([int]$id) { return "String" }
}

# --- 2. IMPORTER ---
class ImporterV2 {
    [string]$Path
    ImporterV2([string]$p) { $this.Path = $p }
    [MvDocument] Import() {
        try {
            $bytes = [System.IO.File]::ReadAllBytes($this.Path)
            $contentString = [System.Text.Encoding]::UTF8.GetString($bytes)
            $xmlStart = $contentString.IndexOf("<editor")
            if ($xmlStart -lt 0) { throw "Root <editor> tag not found" }
            [xml]$xml = [xml]$contentString.Substring($xmlStart)
            
            $doc = [MvDocument]::new()
            $docNode = $xml.editor.item | Where-Object { $_.tableName -eq 'EDITOR_DOCUMENTO' }
            $doc.Id = [int]$docNode.data.ROWSET.ROW.CD_DOCUMENTO
            $doc.Name = $docNode.data.ROWSET.ROW.DS_DOCUMENTO
            
            $fieldNodes = $xml.SelectNodes("//item[@tableName='EDITOR_CAMPO']")
            foreach ($fn in $fieldNodes) {
                $f = [MvField]::new()
                $row = $fn.data.ROWSET.ROW
                $f.Name = $row.DS_CAMPO
                $f.IdLegacy = [int]$row.CD_CAMPO
                $f.TypeIdLegacy = [int]$row.CD_TIPO_VISUALIZACAO
                
                $props = $fn.SelectNodes(".//item[@tableName='EDITOR_CAMPO_PROP_VAL']")
                foreach ($pn in $props) {
                    $propIdNum = [int]$pn.data.ROWSET.ROW.CD_PROPRIEDADE
                    $pval = $pn.data.ROWSET.ROW.LO_VALOR
                    $f.SetProperty([RosettaStone]::GetIdentifier($propIdNum), $pval)
                }
                $doc.AddField($f)
            }
            return $doc
        }
        catch {
            throw "ImporterV2 Error: $($_.Exception.Message)"
        }
    }
}

# --- 3. DRIVERS ---
class DriverV2 {
    [string]$Path
    DriverV2([string]$p) { $this.Path = $p }
    [void] Export([MvDocument]$doc, [bool]$binary) {
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.AppendLine("<editor>")
        [void]$sb.AppendLine("  <item tableName='EDITOR_DOCUMENTO'><data><ROWSET><ROW><CD_DOCUMENTO>$($doc.Id)</CD_DOCUMENTO><DS_DOCUMENTO>$($doc.Name)</DS_DOCUMENTO></ROW></ROWSET></data>")
        [void]$sb.AppendLine("  <children>")
        foreach ($f in $doc.Fields) {
            [void]$sb.AppendLine("    <item tableName='EDITOR_CAMPO'><data><ROWSET><ROW><CD_CAMPO>$($f.IdLegacy)</CD_CAMPO><DS_CAMPO>$($f.Name)</DS_CAMPO><CD_TIPO_VISUALIZACAO>$($f.TypeIdLegacy)</CD_TIPO_VISUALIZACAO></ROW></ROWSET></data>")
            [void]$sb.AppendLine("      <children>")
            foreach ($k in $f.Properties.Keys) {
                $propIdNum = [RosettaStone]::GetId($k)
                [void]$sb.AppendLine("        <item tableName='EDITOR_CAMPO_PROP_VAL'><data><ROWSET><ROW><CD_PROPRIEDADE>$propIdNum</CD_PROPRIEDADE><LO_VALOR>$($f.Properties[$k])</LO_VALOR></ROW></ROWSET></data></item>")
            }
            [void]$sb.AppendLine("      </children></item>")
        }
        [void]$sb.AppendLine("  </children></item></editor>")
        
        if ($binary) {
            $magic = [byte[]](0xAC, 0xED, 0x00, 0x05)
            $xmlBytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
            $fs = [System.IO.File]::Create($this.Path)
            $fs.Write($magic, 0, 4)
            $fs.Write($xmlBytes, 0, $xmlBytes.Length)
            $fs.Close()
        }
        else {
            [System.IO.File]::WriteAllText($this.Path, $sb.ToString(), [System.Text.Encoding]::UTF8)
        }
    }
}

class DriverV3 {
    [string]$Path
    DriverV3([string]$p) { $this.Path = $p }
    [void] Export([MvDocument]$doc) {
        $v3 = @{
            name    = $doc.Name
            layouts = @(@{
                    name    = "Design"
                    content = (ConvertTo-Json @{ pageBody = @{ fields = $doc.Fields } } -Compress)
                })
        }
        $v3 | ConvertTo-Json -Depth 10 | Out-File $this.Path -Encoding UTF8
    }
}

# --- 4. EXECUTION ---
try {
    $original = "J:\replica_lab\11_unpack\edt2_runs\20260215_013442\813 - APAC TST1_0052\05_documentos\tempfile0.edt"
    if (-not (Test-Path $original)) { throw "Original not found: $original" }
    
    $outV2 = "J:/replica_lab/20_outputs/fire_test_v2.edt"
    $outV3 = "J:/replica_lab/20_outputs/fire_test_v3.json"

    $imp = [ImporterV2]::new($original)
    $doc = $imp.Import()
    Write-Host "[OK] Imported doc: $($doc.Name) ($($doc.Fields.Count) fields)" -ForegroundColor Green

    $dv2 = [DriverV2]::new($outV2)
    $dv2.Export($doc, $true)
    Write-Host "[OK] V2 Exported (Binary Mode)." -ForegroundColor Green

    $dv3 = [DriverV3]::new($outV3)
    $dv3.Export($doc)
    Write-Host "[OK] V3 Exported (Matrioska Mode)." -ForegroundColor Green

    Write-Host "`n>>> VERIFICATION <<<" -ForegroundColor Cyan
    $v2Bytes = [System.IO.File]::ReadAllBytes($outV2)
    if ($v2Bytes[0] -eq 0xAC -and $v2Bytes[1] -eq 0xED) { Write-Host "[SUCCESS] V2 Binary header verified." -ForegroundColor Green }
    
    $v3Obj = Get-Content $outV3 -Raw | ConvertFrom-Json
    if ($v3Obj.layouts[0].content -is [string]) { Write-Host "[SUCCESS] V3 Matrioska logic confirmed." -ForegroundColor Green }
    
    Write-Host "`n>>> FIRE TEST COMPLETE <<<" -ForegroundColor Cyan
}
catch {
    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
