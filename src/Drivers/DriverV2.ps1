# using module "..\Core\CanonicalModel.ps1"
# using module "..\Core\RosettaStone.ps1"

class DriverV2 {
    [string] $OutputPath

    DriverV2([string]$outputPath) {
        $this.OutputPath = $outputPath
    }

    [void] Export([MvDocument]$doc, [bool]$UseBinaryHeader = $false) {
        $xmlBody = [System.Text.StringBuilder]::new()
        
        # 1. Root
        [void]$xmlBody.AppendLine("<editor>")
        
        # 2. Document Identity
        [void]$xmlBody.AppendLine("  <item tableName='EDITOR_DOCUMENTO' parentRefId='CD_DOCUMENTO' type='DOC'>")
        [void]$xmlBody.AppendLine("    <data><ROWSET><ROW>")
        [void]$xmlBody.AppendLine("      <CD_DOCUMENTO>$($doc.Id)</CD_DOCUMENTO>")
        [void]$xmlBody.AppendLine("      <DS_DOCUMENTO>$($doc.Name)</DS_DOCUMENTO>")
        [void]$xmlBody.AppendLine("      <CD_TIPO_ITEM>13</CD_TIPO_ITEM>") # Constant
        [void]$xmlBody.AppendLine("    </ROW></ROWSET></data>")
        
        # 3. Children (Version -> Layouts -> Fields)
        [void]$xmlBody.AppendLine("    <children>")
        
        # 3.1 Version
        [void]$xmlBody.AppendLine("      <association childTableName='EDITOR_VERSAO_DOCUMENTO' childRefId='CD_DOCUMENTO'>")
        [void]$xmlBody.AppendLine("        <item tableName='EDITOR_VERSAO_DOCUMENTO' parentRefId='CD_DOCUMENTO' type='EDITOR_VERSAO_DOCUMENTO'>")
        [void]$xmlBody.AppendLine("          <data><ROWSET><ROW>")
        [void]$xmlBody.AppendLine("            <CD_DOCUMENTO>$($doc.Id)</CD_DOCUMENTO>")
        [void]$xmlBody.AppendLine("            <VL_VERSAO>$($doc.Version)</VL_VERSAO>")
        $activeStr = if ($doc.Active) { "S" } else { "N" }
        [void]$xmlBody.AppendLine("            <SN_ATIVO>$activeStr</SN_ATIVO>")
        [void]$xmlBody.AppendLine("          </ROW></ROWSET></data>")

        # 3.2 Layouts & Fields
        [void]$xmlBody.AppendLine("          <children>")
        [void]$xmlBody.AppendLine("            <association childTableName='EDITOR_LAYOUT_CAMPO' childRefId='CD_DOCUMENTO'>")
        
        foreach ($field in $doc.Fields) {
            $this.WriteField($xmlBody, $field, $doc.Id, $doc.Version)
        }
        
        [void]$xmlBody.AppendLine("            </association>")
        [void]$xmlBody.AppendLine("          </children>")
        [void]$xmlBody.AppendLine("        </item>")
        [void]$xmlBody.AppendLine("      </association>")
        [void]$xmlBody.AppendLine("    </children>")
        [void]$xmlBody.AppendLine("  </item>")
        
        # 4. Hierarchy (Groups)
        [void]$xmlBody.AppendLine("  <hierarchy>")
        foreach ($group in $doc.Groups) {
            [void]$xmlBody.AppendLine("    <group name='$($group.Name)' type='$($group.Type)'></group>")
        }
        [void]$xmlBody.AppendLine("  </hierarchy>")
        [void]$xmlBody.AppendLine("</editor>")
        
        $finalString = $xmlBody.ToString()
        
        if ($UseBinaryHeader) {
            # Prepend ACED0005 + some padding/noise to simulate Java Serialization wrapper
            # Magic: AC ED 00 05
            $magic = [byte[]](0xAC, 0xED, 0x00, 0x05)
            $xmlBytes = [System.Text.Encoding]::UTF8.GetBytes($finalString)
            $totalBytes = [System.IO.MemoryStream]::new()
            $totalBytes.Write($magic, 0, $magic.Length)
            # Simulating some object metadata junk before XML
            $junk = [System.Text.Encoding]::UTF8.GetBytes("sr..java.util.ArrayList")
            $totalBytes.Write($junk, 0, $junk.Length)
            $totalBytes.Write($xmlBytes, 0, $xmlBytes.Length)
            
            [System.IO.File]::WriteAllBytes($this.OutputPath, $totalBytes.ToArray())
        }
        else {
            [System.IO.File]::WriteAllText($this.OutputPath, $finalString, [System.Text.Encoding]::UTF8)
        }
    }

    [void] WriteField([System.Text.StringBuilder]$sb, [MvField]$field, [int]$docId, [int]$version) {
        [void]$sb.AppendLine("              <item tableName='EDITOR_LAYOUT_CAMPO' parentRefId='CD_DOCUMENTO' type='EDITOR_LAYOUT_CAMPO'>")
        [void]$sb.AppendLine("                <data><ROWSET><ROW>")
        [void]$sb.AppendLine("                  <NR_LINHA>$($field.Y)</NR_LINHA>") 
        [void]$sb.AppendLine("                  <NR_COLUNA>$($field.X)</NR_COLUNA>")
        [void]$sb.AppendLine("                  <NR_LARGURA>$($field.Width)</NR_LARGURA>")
        [void]$sb.AppendLine("                  <NR_ALTURA>$($field.Height)</NR_ALTURA>")
        [void]$sb.AppendLine("                  <CD_DOCUMENTO>$docId</CD_DOCUMENTO>")
        [void]$sb.AppendLine("                  <VL_VERSAO>$version</VL_VERSAO>")
        [void]$sb.AppendLine("                  <CD_CAMPO>$($field.IdLegacy)</CD_CAMPO>")
        [void]$sb.AppendLine("                </ROW></ROWSET></data>")
        [void]$sb.AppendLine("                <children>")
        [void]$sb.AppendLine("                  <association childTableName='EDITOR_CAMPO' childRefId='CD_CAMPO'>")
        [void]$sb.AppendLine("                    <item tableName='EDITOR_CAMPO' parentRefId='CD_CAMPO' type='CAM'>")
        [void]$sb.AppendLine("                      <data><ROWSET><ROW>")
        [void]$sb.AppendLine("                        <CD_CAMPO>$($field.IdLegacy)</CD_CAMPO>")
        [void]$sb.AppendLine("                        <DS_CAMPO>$($field.Name)</DS_CAMPO>")
        [void]$sb.AppendLine("                        <CD_TIPO_VISUALIZACAO>$($field.TypeIdLegacy)</CD_TIPO_VISUALIZACAO>")
        [void]$sb.AppendLine("                        <DS_IDENTIFICADOR>$($field.Identifier)</DS_IDENTIFICADOR>")
        [void]$sb.AppendLine("                      </ROW></ROWSET></data>")
        [void]$sb.AppendLine("                      <children>")
        [void]$sb.AppendLine("                        <association childTableName='EDITOR_CAMPO_PROP_VAL' childRefId='CD_CAMPO'>")
        foreach ($key in $field.Properties.Keys) {
            $this.WriteProperty($sb, $field, $key, $field.Properties[$key])
        }
        [void]$sb.AppendLine("                        </association>")
        [void]$sb.AppendLine("                      </children>")
        [void]$sb.AppendLine("                    </item>")
        [void]$sb.AppendLine("                  </association>")
        [void]$sb.AppendLine("                </children>")
        [void]$sb.AppendLine("              </item>")
    }

    [void] WriteProperty([System.Text.StringBuilder]$sb, [MvField]$field, [string]$key, [object]$value) {
        $propId = [RosettaStone]::GetId($key)
        [void]$sb.AppendLine("                          <item tableName='EDITOR_CAMPO_PROP_VAL' parentRefId='CD_CAMPO' type='EDITOR_CAMPO_PROP_VAL'>")
        [void]$sb.AppendLine("                            <data><ROWSET><ROW>")
        [void]$sb.AppendLine("                              <CD_CAMPO>$($field.IdLegacy)</CD_CAMPO>")
        [void]$sb.AppendLine("                              <CD_TIPO_VISUALIZACAO>$($field.TypeIdLegacy)</CD_TIPO_VISUALIZACAO>")
        [void]$sb.AppendLine("                              <CD_PROPRIEDADE>$propId</CD_PROPRIEDADE>")
        $valStr = $this.ConvertValueForV2($key, $value)
        [void]$sb.AppendLine("                              <LO_VALOR>$valStr</LO_VALOR>")
        [void]$sb.AppendLine("                            </ROW></ROWSET></data>")
        [void]$sb.AppendLine("                          </item>")
    }

    [string] ConvertValueForV2([string]$key, [object]$value) {
        if ($null -eq $value) { return "" }
        if ($value -is [bool]) {
            if ($key -eq "obrigatorio" -or $key -eq "editavel") {
                if ($value) { return "true" } else { return "false" }
            }
            return if ($value) { "S" } else { "N" }
        }
        if ($value -is [DateTime]) { return $value.ToString("dd/MM/yy") }
        return $value.ToString()
    }
}
