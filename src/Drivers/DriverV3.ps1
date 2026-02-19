using module "J:\replica_lab\src\Core\CanonicalModel.ps1"
using module "J:\replica_lab\src\Core\RosettaStone.ps1"

class DriverV3 {
    [string] $OutputPath

    DriverV3([string]$outputPath) {
        $this.OutputPath = $outputPath
    }

    [void] Export([MvDocument]$doc) {
        # Construct the V3 Object Structure
        $v3Doc = [ordered]@{
            name          = $doc.Name
            identifier    = [MvDocument]::SanitizeIdentifier($doc.Name)
            versionStatus = $doc.VersionStatus
            version       = @{
                id   = $doc.Version
                hash = $null # Calculated at the end (Version Seal)
            }
            data          = @{
                id        = $doc.Id
                active    = $doc.Active
                createdBy = $doc.CreatedBy
            }
            fields        = $this.SerializeFields($doc)
            layouts       = $this.SerializeLayouts($doc)
        }

        # 3. Version Seal: MD5 of minified layouts.content
        $layoutContent = $v3Doc.layouts[0].content # This is already minified in SerializeLayouts
        $v3Doc.version.hash = $this.CalculateHash($layoutContent)
        
        # Pretty Print for final file + SQL No-Escape Policy
        $finalJson = ConvertTo-Json $v3Doc -Depth 10
        # Post-Processing: Unescape & < > for SQL fields (IDs 4, 21)
        $finalJson = $finalJson -replace '\\u0026', '&' -replace '\\u003c', '<' -replace '\\u003e', '>'
        
        [System.IO.File]::WriteAllText($this.OutputPath, $finalJson, [System.Text.Encoding]::UTF8)
    }

    [System.Collections.ArrayList] SerializeFields([MvDocument]$doc) {
        $list = [System.Collections.ArrayList]::new()
        foreach ($f in $doc.Fields) {
            $fieldObj = [ordered]@{
                name                = $f.Name
                identifier          = $f.Identifier
                visualizationType   = @{
                    id         = $f.TypeIdModern
                    identifier = $f.TypeIdentifier
                }
                fieldPropertyValues = $this.SerializeProperties($f, $doc.CreatedBy)
                layout              = "$($f.X),$($f.Y),$($f.Width),$($f.Height)"
            }
            [void]$list.Add($fieldObj)
        }
        return $list
    }

    [System.Collections.ArrayList] SerializeProperties([MvField]$f, [string]$createdBy) {
        $list = [System.Collections.ArrayList]::new()
        foreach ($key in $f.Properties.Keys) {
            $val = $f.Properties[$key]
            $propIdNum = [RosettaStone]::GetId($key)

            # Hybrid Hash Logic
            $valHash = ""
            if ($createdBy -eq "Migrador®") {
                $valHash = "d41d8cd98f00b204e9800998ecf8427e" # Force empty MD5
            }
            elseif ($val -is [bool] -or $null -eq $val) {
                # Static Lookup Table
                if ($null -eq $val) { $valHash = "37a6259cc0c1dae299a7866489dff0bd" }
                elseif ($val) { $valHash = "b326b5062b2f0e69046810717534cb09" }
                else { $valHash = "68934a3e9455fa72420237eb05902327" }
            }
            else {
                # Dynamic MD5 of UTF-8 string
                $rawVal = if ($val -is [DateTime]) { $val.ToString("yyyy-MM-dd") } else { $val.ToString() }
                $valHash = $this.CalculateHash($rawVal)
            }

            # Normalization
            $finalVal = $val
            if ($val -is [DateTime]) { $finalVal = $val.ToString("yyyy-MM-dd") }

            $propObj = [ordered]@{
                property = @{ identifier = $key }
                value    = $finalVal
                hash     = $valHash
            }
            [void]$list.Add($propObj)
        }
        return $list
    }
    
    [System.Collections.ArrayList] SerializeLayouts([MvDocument]$doc) {
        $list = [System.Collections.ArrayList]::new()
        
        # 1. Build the internal UI structure
        $uiStructure = [ordered]@{
            pageBody = [ordered]@{
                groups = $this.SerializeGroups($doc.Groups)
                pages  = @()
            }
        }
        
        # 2. Stringify the UI structure (The Matrioska Rule) + MINIFICATION
        # We use depth 20 and -Compress to ensure minification (no \n)
        $contentString = ConvertTo-Json $uiStructure -Depth 20 -Compress
        
        $layoutObj = [ordered]@{
            name    = "Design Padrão"
            content = $contentString
        }
        
        [void]$list.Add($layoutObj)
        return $list
    }

    [System.Collections.ArrayList] SerializeGroups([System.Collections.ArrayList]$groups) {
        $list = [System.Collections.ArrayList]::new()
        foreach ($g in $groups) {
            $grpObj = [ordered]@{
                name     = $g.Name
                type     = $g.Type
                children = @()
            }
            [void]$list.Add($grpObj)
        }
        return $list
    }

    [string] CalculateHash([string]$content) {
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $hash = [BitConverter]::ToString($md5.ComputeHash($bytes)).Replace("-", "").ToLower()
        return $hash
    }
}
