param(
  [string]$BasePath = "J:\replica_lab"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$OutDir = Join-Path $BasePath "20_outputs\analysis"
$Stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")

$Editor3Csv = Join-Path $OutDir ("editor3_catalog_" + $Stamp + ".csv")
$Editor2Csv = Join-Path $OutDir ("editor2_inventory_" + $Stamp + ".csv")
$SummaryTxt = Join-Path $OutDir ("replica_catalog_summary_" + $Stamp + ".txt")

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    [System.IO.Directory]::CreateDirectory($Path) | Out-Null
  }
}

function New-StreamWriterUtf8NoBom([string]$Path) {
  $dir = [System.IO.Path]::GetDirectoryName($Path)
  if ($dir -and (-not (Test-Path -LiteralPath $dir))) {
    [System.IO.Directory]::CreateDirectory($dir) | Out-Null
  }
  return New-Object System.IO.StreamWriter($Path, $false, $Utf8NoBom)
}

function Write-Utf8NoBomAllText([string]$Path, [string]$Text) {
  $dir = [System.IO.Path]::GetDirectoryName($Path)
  if ($dir -and (-not (Test-Path -LiteralPath $dir))) {
    [System.IO.Directory]::CreateDirectory($dir) | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom)
}

function Csv-Escape([object]$Value) {
  if ($null -eq $Value) { return "" }
  $s = [string]$Value
  $needsQuote = $false
  if ($s.Contains(";")) { $needsQuote = $true }
  if ($s.Contains('"')) { $needsQuote = $true }
  if ($s.Contains("`r") -or $s.Contains("`n")) { $needsQuote = $true }
  if ($needsQuote) { return '"' + ($s.Replace('"','""')) + '"' }
  return $s
}

function Decode-Utf8Robust([byte[]]$Bytes, [ref]$UsedSalvage) {
  $UsedSalvage.Value = $false
  try { return $Utf8Strict.GetString($Bytes) }
  catch { $UsedSalvage.Value = $true; return $Utf8NoBom.GetString($Bytes) }
}

function Clean-Text([string]$s) {
  if ($null -eq $s) { return "" }
  if ($s.Length -gt 0 -and [int]$s[0] -eq 0xFEFF) { $s = $s.Substring(1) }
  if ($s.IndexOf([char]0) -ge 0) { $s = $s.Replace([char]0, "") }
  return $s.Trim()
}

function Is-ObjectLike([object]$o) {
  if ($null -eq $o) { return $false }
  if ($o -is [System.Collections.IDictionary]) { return $true }
  if ($o -is [pscustomobject]) { return $true }
  return $false
}

function Get-PropValueI([object]$o, [string]$name) {
  if ($null -eq $o) { return $null }
  if ($o -is [System.Collections.IDictionary]) {
    foreach ($k in $o.Keys) { if ([string]$k -ieq $name) { return $o[$k] } }
    return $null
  }
  foreach ($p in $o.PSObject.Properties) { if ($p.Name -ieq $name) { return $p.Value } }
  return $null
}

function Get-HashState([object]$versionObj) {
  if (-not (Is-ObjectLike -o $versionObj)) { return "VERSION_NOT_OBJECT" }
  $hasHashProp = $false
  foreach ($p in $versionObj.PSObject.Properties) {
    if ($p.Name -ieq "hash") { $hasHashProp = $true; break }
  }
  if (-not $hasHashProp) { return "MISSING_PROP" }

  $hv = Get-PropValueI -o $versionObj -name "hash"
  if ($null -eq $hv) { return "NULL" }
  $hs = ([string]$hv).Trim()
  if ([string]::IsNullOrWhiteSpace($hs)) { return "EMPTY" }
  if ($hs -match '^[0-9a-fA-F]{32}$') { return "HEX32" }
  return "INVALID_FORMAT"
}

function Get-PathSegment([string]$Path, [int]$IndexFromBase, [string]$BasePrefix) {
  $rel = $Path
  if ($Path.StartsWith($BasePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    $rel = $Path.Substring($BasePrefix.Length).TrimStart('\')
  }
  $parts = $rel.Split('\')
  if ($parts.Length -gt $IndexFromBase) { return $parts[$IndexFromBase] }
  return ""
}

Ensure-Dir -Path $OutDir

$editor3Total = 0
$editor3ParsedOk = 0
$editor3ParseFail = 0
$editor3DecodeSalvage = 0
$hashStates = @{
  "HEX32" = 0
  "NULL" = 0
  "EMPTY" = 0
  "MISSING_PROP" = 0
  "INVALID_FORMAT" = 0
  "VERSION_NOT_OBJECT" = 0
  "VERSION_MISSING" = 0
}
$docIdentifierCounts = @{}

$editor3Root = Join-Path $BasePath "10_work\extracted_edt3"
$editor3BasePrefix = ($editor3Root.TrimEnd('\') + "\")

$sw3 = $null
$sw2 = $null

try {
  $sw3 = New-StreamWriterUtf8NoBom -Path $Editor3Csv
  $sw3.WriteLine("file;package_folder;file_name;size_bytes;json_parse_ok;parse_error;root_name;root_identifier;root_type;root_group;version_id;version_documentId;version_documentIdentifier;version_documentName;version_status;version_number;version_hash;version_hash_state;layouts_kind;layouts_count")

  if (Test-Path -LiteralPath $editor3Root) {
    foreach ($f in Get-ChildItem -LiteralPath $editor3Root -Recurse -Filter "*.edt" -File) {
      $editor3Total++
      $usedSalvage = $false
      $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
      $text = Decode-Utf8Robust -Bytes $bytes -UsedSalvage ([ref]$usedSalvage)
      if ($usedSalvage) { $editor3DecodeSalvage++ }
      $text = Clean-Text -s $text

      $obj = $null
      $parseErr = ""
      try { $obj = ConvertFrom-Json -InputObject $text }
      catch { $parseErr = $_.Exception.Message }

      $pkg = Get-PathSegment -Path $f.FullName -IndexFromBase 0 -BasePrefix $editor3BasePrefix
      if ($null -eq $obj) {
        $editor3ParseFail++
        $line = (Csv-Escape $f.FullName) + ";" + (Csv-Escape $pkg) + ";" + (Csv-Escape $f.Name) + ";" +
                (Csv-Escape $f.Length) + ";false;" + (Csv-Escape $parseErr) + ";;;;;;;;;;;;;;"
        $sw3.WriteLine($line)
        continue
      }

      $editor3ParsedOk++

      $rootName = Get-PropValueI -o $obj -name "name"
      $rootIdentifier = Get-PropValueI -o $obj -name "identifier"
      $rootType = Get-PropValueI -o $obj -name "type"
      $rootGroup = Get-PropValueI -o $obj -name "group"

      $versionObj = Get-PropValueI -o $obj -name "version"
      $hashState = "VERSION_MISSING"
      $versionId = ""
      $versionDocId = ""
      $versionDocIdent = ""
      $versionDocName = ""
      $versionStatus = ""
      $versionNumber = ""
      $versionHash = ""
      $layoutsKind = ""
      $layoutsCount = ""

      if (Is-ObjectLike -o $versionObj) {
        $versionId = Get-PropValueI -o $versionObj -name "id"
        $versionDocId = Get-PropValueI -o $versionObj -name "documentId"
        $versionDocIdent = Get-PropValueI -o $versionObj -name "documentIdentifier"
        $versionDocName = Get-PropValueI -o $versionObj -name "documentName"
        $versionStatus = Get-PropValueI -o $versionObj -name "versionStatus"
        $versionNumber = Get-PropValueI -o $versionObj -name "vlVersion"
        $vh = Get-PropValueI -o $versionObj -name "hash"
        if ($null -ne $vh) { $versionHash = [string]$vh }
        $hashState = Get-HashState -versionObj $versionObj

        $layouts = Get-PropValueI -o $versionObj -name "layouts"
        if ($layouts -is [System.Collections.IEnumerable] -and -not ($layouts -is [string])) {
          $layoutsKind = "array"
          $n = 0
          foreach ($el in $layouts) { $n++ }
          $layoutsCount = $n
        }
        elseif ($null -eq $layouts) {
          $layoutsKind = "null"
          $layoutsCount = 0
        }
        else {
          $layoutsKind = "object"
          $layoutsCount = 1
        }
      }

      if (-not $hashStates.ContainsKey($hashState)) { $hashStates[$hashState] = 0 }
      $hashStates[$hashState] = [int]$hashStates[$hashState] + 1

      if (-not [string]::IsNullOrWhiteSpace([string]$versionDocIdent)) {
        $k = [string]$versionDocIdent
        if (-not $docIdentifierCounts.ContainsKey($k)) { $docIdentifierCounts[$k] = 0 }
        $docIdentifierCounts[$k] = [int]$docIdentifierCounts[$k] + 1
      }

      $line = (Csv-Escape $f.FullName) + ";" + (Csv-Escape $pkg) + ";" + (Csv-Escape $f.Name) + ";" +
              (Csv-Escape $f.Length) + ";true;;" +
              (Csv-Escape $rootName) + ";" + (Csv-Escape $rootIdentifier) + ";" +
              (Csv-Escape $rootType) + ";" + (Csv-Escape $rootGroup) + ";" +
              (Csv-Escape $versionId) + ";" + (Csv-Escape $versionDocId) + ";" +
              (Csv-Escape $versionDocIdent) + ";" + (Csv-Escape $versionDocName) + ";" +
              (Csv-Escape $versionStatus) + ";" + (Csv-Escape $versionNumber) + ";" +
              (Csv-Escape $versionHash) + ";" + (Csv-Escape $hashState) + ";" +
              (Csv-Escape $layoutsKind) + ";" + (Csv-Escape $layoutsCount)
      $sw3.WriteLine($line)
    }
  }

  $editor2Total = 0
  $editor2ParseOk = 0
  $editor2ParseFail = 0
  $editor2DecodeSalvage = 0
  $editor2KindCounts = @{
    "JSON" = 0
    "XML" = 0
    "VERSION_STRING" = 0
    "UNKNOWN" = 0
  }

  $editor2Root = Join-Path $BasePath "11_unpack\edt2_runs"
  $editor2BasePrefix = ($editor2Root.TrimEnd('\') + "\")

  $sw2 = New-StreamWriterUtf8NoBom -Path $Editor2Csv
  $sw2.WriteLine("file;run_folder;doc_folder;segment_folder;file_name;size_bytes;parse_kind;parse_ok;parse_error;xml_root;item_table;item_type;ds_identificador;raw_preview")

  if (Test-Path -LiteralPath $editor2Root) {
    foreach ($f2 in Get-ChildItem -LiteralPath $editor2Root -Recurse -Filter "*.edt" -File) {
      $editor2Total++
      $usedSalvage2 = $false
      $bytes2 = [System.IO.File]::ReadAllBytes($f2.FullName)
      $text2 = Decode-Utf8Robust -Bytes $bytes2 -UsedSalvage ([ref]$usedSalvage2)
      if ($usedSalvage2) { $editor2DecodeSalvage++ }
      $text2 = Clean-Text -s $text2

      $obj2 = $null
      $xml2 = $null
      $parseErr2 = ""
      $parseKind2 = "UNKNOWN"
      $parseOk2 = $false
      $xmlRoot2 = ""
      $itemTable2 = ""
      $itemType2 = ""
      $dsIdent2 = ""
      $preview2 = ""
      if ($text2.Length -gt 0) {
        $len2 = [Math]::Min(80, $text2.Length)
        $preview2 = $text2.Substring(0, $len2).Replace("`r"," ").Replace("`n"," ")
      }

      try {
        $obj2 = ConvertFrom-Json -InputObject $text2
        $parseKind2 = "JSON"
        $parseOk2 = $true
      }
      catch {
        try {
          [xml]$xml2 = $text2
          $parseKind2 = "XML"
          $parseOk2 = $true
        }
        catch {
          if ($text2 -match '^[0-9]{4}\.[0-9]{1,3}\.[0-9]{1,3}(-[A-Za-z0-9]+)?\s*$') {
            $parseKind2 = "VERSION_STRING"
            $parseOk2 = $true
          }
          else {
            $parseErr2 = $_.Exception.Message
          }
        }
      }

      $rel2 = $f2.FullName
      if ($rel2.StartsWith($editor2BasePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel2 = $rel2.Substring($editor2BasePrefix.Length)
      }
      $parts2 = $rel2.Split('\')
      $runFolder = ""
      $docFolder = ""
      $segmentFolder = ""
      if ($parts2.Length -gt 0) { $runFolder = $parts2[0] }
      if ($parts2.Length -gt 1) { $docFolder = $parts2[1] }
      if ($parts2.Length -gt 2) { $segmentFolder = $parts2[2] }

      if ($editor2KindCounts.ContainsKey($parseKind2)) {
        $editor2KindCounts[$parseKind2] = [int]$editor2KindCounts[$parseKind2] + 1
      }
      else {
        $editor2KindCounts["UNKNOWN"] = [int]$editor2KindCounts["UNKNOWN"] + 1
      }

      if (-not $parseOk2) {
        $editor2ParseFail++
        $line2 = (Csv-Escape $f2.FullName) + ";" + (Csv-Escape $runFolder) + ";" + (Csv-Escape $docFolder) + ";" +
                 (Csv-Escape $segmentFolder) + ";" + (Csv-Escape $f2.Name) + ";" + (Csv-Escape $f2.Length) + ";" +
                 (Csv-Escape $parseKind2) + ";false;" + (Csv-Escape $parseErr2) + ";;;;" + (Csv-Escape $preview2)
        $sw2.WriteLine($line2)
        continue
      }

      $editor2ParseOk++

      if ($parseKind2 -eq "XML" -and $null -ne $xml2) {
        if ($null -ne $xml2.DocumentElement) { $xmlRoot2 = [string]$xml2.DocumentElement.Name }
        $itemNode = $xml2.SelectSingleNode("/editor/item")
        if ($null -ne $itemNode) {
          if ($itemNode.Attributes["tableName"]) { $itemTable2 = [string]$itemNode.Attributes["tableName"].Value }
          if ($itemNode.Attributes["type"]) { $itemType2 = [string]$itemNode.Attributes["type"].Value }
        }
        $dsNode = $xml2.SelectSingleNode("//DS_IDENTIFICADOR")
        if ($null -ne $dsNode) { $dsIdent2 = [string]$dsNode.InnerText }
      }
      elseif ($parseKind2 -eq "JSON" -and $null -ne $obj2) {
        $rootIdentJson = Get-PropValueI -o $obj2 -name "identifier"
        if ($null -ne $rootIdentJson) { $dsIdent2 = [string]$rootIdentJson }
      }
      elseif ($parseKind2 -eq "VERSION_STRING") {
        $dsIdent2 = $text2.Trim()
      }

      $line2 = (Csv-Escape $f2.FullName) + ";" + (Csv-Escape $runFolder) + ";" + (Csv-Escape $docFolder) + ";" +
               (Csv-Escape $segmentFolder) + ";" + (Csv-Escape $f2.Name) + ";" + (Csv-Escape $f2.Length) + ";" +
               (Csv-Escape $parseKind2) + ";true;;" + (Csv-Escape $xmlRoot2) + ";" +
               (Csv-Escape $itemTable2) + ";" + (Csv-Escape $itemType2) + ";" +
               (Csv-Escape $dsIdent2) + ";" + (Csv-Escape $preview2)
      $sw2.WriteLine($line2)
    }
  }

  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("REPLICA CATALOG SUMMARY")
  [void]$sb.AppendLine("timestamp=" + $Stamp)
  [void]$sb.AppendLine("base_path=" + $BasePath)
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("editor3_total=" + $editor3Total)
  [void]$sb.AppendLine("editor3_parse_ok=" + $editor3ParsedOk)
  [void]$sb.AppendLine("editor3_parse_fail=" + $editor3ParseFail)
  [void]$sb.AppendLine("editor3_decode_salvage_used=" + $editor3DecodeSalvage)
  [void]$sb.AppendLine("editor3_hash_hex32=" + $hashStates["HEX32"])
  [void]$sb.AppendLine("editor3_hash_null=" + $hashStates["NULL"])
  [void]$sb.AppendLine("editor3_hash_empty=" + $hashStates["EMPTY"])
  [void]$sb.AppendLine("editor3_hash_missing_prop=" + $hashStates["MISSING_PROP"])
  [void]$sb.AppendLine("editor3_hash_invalid_format=" + $hashStates["INVALID_FORMAT"])
  [void]$sb.AppendLine("editor3_version_missing=" + $hashStates["VERSION_MISSING"])
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("editor2_total=" + $editor2Total)
  [void]$sb.AppendLine("editor2_parse_ok=" + $editor2ParseOk)
  [void]$sb.AppendLine("editor2_parse_fail=" + $editor2ParseFail)
  [void]$sb.AppendLine("editor2_decode_salvage_used=" + $editor2DecodeSalvage)
  [void]$sb.AppendLine("editor2_kind_json=" + $editor2KindCounts["JSON"])
  [void]$sb.AppendLine("editor2_kind_xml=" + $editor2KindCounts["XML"])
  [void]$sb.AppendLine("editor2_kind_version_string=" + $editor2KindCounts["VERSION_STRING"])
  [void]$sb.AppendLine("editor2_kind_unknown=" + $editor2KindCounts["UNKNOWN"])
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("top_editor3_documentIdentifier_counts")

  $pairs = @()
  foreach ($k in $docIdentifierCounts.Keys) {
    $pairs += [pscustomobject]@{ key = $k; n = [int]$docIdentifierCounts[$k] }
  }
  $sortedPairs = $pairs | Sort-Object -Property @{Expression = "n"; Descending = $true}, @{Expression = "key"; Descending = $false}
  foreach ($p in ($sortedPairs | Select-Object -First 30)) {
    [void]$sb.AppendLine(($p.n.ToString() + ";" + $p.key))
  }

  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("editor3_csv=" + $Editor3Csv)
  [void]$sb.AppendLine("editor2_csv=" + $Editor2Csv)

  Write-Utf8NoBomAllText -Path $SummaryTxt -Text $sb.ToString()

  Write-Host ("OK: " + $Editor3Csv)
  Write-Host ("OK: " + $Editor2Csv)
  Write-Host ("OK: " + $SummaryTxt)
}
finally {
  if ($sw3) { $sw3.Dispose() }
  if ($sw2) { $sw2.Dispose() }
}
