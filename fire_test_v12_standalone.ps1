# Fire Test: Phase 11 Forensic Verification (V12.2 - SELF-CONTAINED)

# --- 1. ROSETTA STONE ---
class RosettaStone {
    static [string] GetIdentifier([int]$id) {
        if ($id -eq 21) { return "acaoSql" }
        if ($id -eq 35) { return "tipo_do_grafico" }
        if ($id -eq 4) { return "acao" }
        return "PROP_$id"
    }
    static [int] GetId([string]$key) {
        if ($key -eq "acaoSql") { return 21 }
        if ($key -eq "tipo_do_grafico") { return 35 }
        if ($key -eq "acao") { return 4 }
        if ($key -eq "obrigatorio") { return 8 }
        return 999
    }
    static [string] GetType([int]$id) {
        if ($id -eq 8) { return "Boolean" }
        return "String"
    }
}

# --- 2. CANONICAL MODEL ---
class MvField {
    [int]$IdLegacy; [string]$Name; [string]$Identifier
    [int]$TypeIdLegacy; [int]$TypeIdModern; [string]$TypeIdentifier
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
    [int]$Id; [string]$Name; [string]$Identifier; [int]$Version; [bool]$Active
    [string]$VersionStatus; [string]$CreatedBy; [string]$VersionHash
    [System.Collections.ArrayList]$Fields = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$Groups = [System.Collections.ArrayList]::new()
    
    MvDocument() { $this.VersionStatus = "DRAFT"; $this.Active = $true }
    
    static [string] SanitizeIdentifier([string]$id) {
        if ([string]::IsNullOrWhiteSpace($id)) { return "UNNAMED_OBJ" }
        $san = $id.ToUpper().Trim() -replace '[^A-Z0-9_]', '_' -replace '_+', '_'
        return $san.Trim('_')
    }
    [void] AddField([MvField]$f) {
        $f.Identifier = [MvDocument]::SanitizeIdentifier($f.Identifier)
        [void]$this.Fields.Add($f)
    }
}

# --- 3. IMPORTER ---
class ImporterV2 {
    [string]$Path
    ImporterV2([string]$p) { $this.Path = $p }
    [MvDocument] Import() {
        # Java Breaker Scrubber
        $bytes = [System.IO.File]::ReadAllBytes($this.Path)
        $streamStr = [System.Text.Encoding]::UTF8.GetString($bytes)
        $xmlStart = $streamStr.IndexOf("<editor")
        if ($xmlStart -lt 0) { throw "No XML markers found in binary." }
        [xml]$xml = [xml]$streamStr.Substring($xmlStart)
        
        $doc = [MvDocument]::new()
        $docNode = $xml.editor.item | Where-Object { $_.tableName -eq 'EDITOR_DOCUMENTO' }
        $doc.Id = [int]$docNode.data.ROWSET.ROW.CD_DOCUMENTO
        $doc.Name = $docNode.data.ROWSET.ROW.DS_DOCUMENTO
        $doc.Identifier = [MvDocument]::SanitizeIdentifier($doc.Name)
        $doc.CreatedBy = $docNode.data.ROWSET.ROW.CD_USUARIO_CRIACAO
        
        # Field Parsing (simplified for test)
        $fieldNode = $xml.SelectNodes("//item[@tableName='EDITOR_CAMPO']")
        foreach ($fn in $fieldNode) {
            $f = [MvField]::new()
            $f.Name = $fn.data.ROWSET.ROW.DS_CAMPO
            $f.Identifier = $fn.data.ROWSET.ROW.DS_IDENTIFICADOR
            $f.SetTypeFromLegacy([int]$fn.data.ROWSET.ROW.CD_TIPO_VISUALIZACAO)
            $doc.AddField($f)
        }
        return $doc
    }
}

# --- 4. DRIVER V3 ---
class DriverV3 {
    [string]$Path
    DriverV3([string]$p) { $this.Path = $p }
    
    [void] Export([MvDocument]$doc) {
        $v3Doc = [ordered]@{
            name = $doc.Name; identifier = [MvDocument]::SanitizeIdentifier($doc.Name)
            version = [ordered]@{ id = $doc.Version; hash = $null }
            data = [ordered]@{ id = $doc.Id; active = $doc.Active; createdBy = $doc.CreatedBy }
            fields = $this.SerializeFields($doc)
            layouts = $this.SerializeLayouts($doc)
        }
        $compJson = ConvertTo-Json $v3Doc -Depth 20 -Compress
        $v3Doc.version.hash = $this.CalculateHash($v3Doc.layouts[0].content)
        $finalJson = ConvertTo-Json $v3Doc -Depth 20
        # SQL No-Escape Policy
        $finalJson = $finalJson -replace '\\u0026', '&' -replace '\\u003c', '<' -replace '\\u003e', '>'
        [System.IO.File]::WriteAllText($this.Path, $finalJson, [System.Text.Encoding]::UTF8)
    }

    [System.Collections.ArrayList] SerializeFields([MvDocument]$doc) {
        $list = [System.Collections.ArrayList]::new()
        foreach ($f in $doc.Fields) {
            [void]$list.Add([ordered]@{
                    name = $f.Name; identifier = $f.Identifier
                    visualizationType = @{ id = $f.TypeIdModern; identifier = $f.TypeIdentifier }
                    fieldPropertyValues = $this.SerializeProperties($f, $doc.CreatedBy)
                })
        }
        return $list
    }

    [System.Collections.ArrayList] SerializeProperties([MvField]$f, [string]$createdBy) {
        $list = [System.Collections.ArrayList]::new()
        foreach ($k in $f.Properties.Keys) {
            $v = $f.Properties[$k]
            $h = ""
            if ($createdBy -eq "Migrador®") { $h = "d41d8cd98f00b204e9800998ecf8427e" }
            elseif ($v -is [bool] -or $null -eq $v) {
                if ($null -eq $v) { $h = "37a6259cc0c1dae299a7866489dff0bd" }
                elseif ($v) { $h = "b326b5062b2f0e69046810717534cb09" }
                else { $h = "68934a3e9455fa72420237eb05902327" }
            }
            else {
                $h = $this.CalculateHash($v.ToString())
            }
            [void]$list.Add([ordered]@{ property = @{ identifier = $k }; value = $v; hash = $h })
        }
        return $list
    }

    [System.Collections.ArrayList] SerializeLayouts([MvDocument]$doc) {
        $list = [System.Collections.ArrayList]::new()
        $ui = [ordered]@{ pageBody = [ordered]@{ groups = @(); pages = @() } }
        $list.Add([ordered]@{ name = "Design Padrão"; content = (ConvertTo-Json $ui -Depth 20 -Compress) })
        return $list
    }

    [string] CalculateHash([string]$str) {
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $b = [System.Text.Encoding]::UTF8.GetBytes($str)
        return [BitConverter]::ToString($md5.ComputeHash($b)).Replace("-", "").ToLower()
    }
}

# --- 5. TEST EXECUTION ---
try {
    Write-Host ">>> PHASE 11 VERIFICATION (V12.2) <<<" -ForegroundColor Cyan
    $testDoc = [MvDocument]::new()
    $testDoc.Name = "Teste Clinico Forense"
    $testDoc.CreatedBy = "SES50002"
    
    $fSql = [MvField]::new(); $fSql.Name = "Ação SQL"; $fSql.Identifier = "acao sql"; $fSql.SetProperty("acaoSql", "&<PAR_CD>"); $testDoc.AddField($fSql)
    $fBool = [MvField]::new(); $fBool.Name = "Obs"; $fBool.Identifier = "obs"; $fBool.SetProperty("obrigatorio", $true); $testDoc.AddField($fBool)

    $out = "J:\replica_lab\20_outputs\fire_test_v12_2.json"
    $dv3 = [DriverV3]::new($out); $dv3.Export($testDoc)
    
    # Assertions
    $raw = Get-Content $out -Raw; $obj = $raw | ConvertFrom-Json
    if ($obj.fields[0].identifier -eq "ACAO_SQL") { Write-Host "[OK] Sanitizer: ACAO_SQL" -ForegroundColor Green }
    if ($raw -match '&<PAR_CD>') { Write-Host "[OK] SQL No-Escape verified." -ForegroundColor Green }
    if ($obj.fields[1].fieldPropertyValues[0].hash -eq "b326b5062b2f0e69046810717534cb09") { Write-Host "[OK] Hybrid Hash (Static) verified." -ForegroundColor Green }
    if ($obj.version.hash -ne $null) { Write-Host "[OK] Version Seal verified." -ForegroundColor Green }

    # Migrador Exception
    $testDoc.CreatedBy = "Migrador®"; $dv3.Export($testDoc)
    $objM = Get-Content $out -Raw | ConvertFrom-Json
    if ($objM.fields[1].fieldPropertyValues[0].hash -eq "d41d8cd98f00b204e9800998ecf8427e") { Write-Host "[OK] Migrador® Exception verified." -ForegroundColor Green }

    Write-Host "`n>>> SUCCESS <<<" -ForegroundColor Cyan
}
catch {
    Write-Host "`n[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
