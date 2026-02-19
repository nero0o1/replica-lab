param(
  [ValidateSet("DRYRUN","APPLY")]
  [string]$Mode = "DRYRUN",
  [switch]$NormalizeSqlNewlines,
  [string]$IssuesCsv = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BasePath = "J:\replica_lab"
$AuditDir = Join-Path $BasePath "20_outputs\audit"
$FixDir   = Join-Path $BasePath "20_outputs\fix"

$Stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$BackupRoot = Join-Path $FixDir ("backup_fixpackB_" + $Stamp)
$ChangesCsv = Join-Path $FixDir ("fixpackB_changes_" + $Stamp + ".csv")
$SummaryTxt = Join-Path $FixDir ("fixpackB_summary_"  + $Stamp + ".txt")

$MaxBytes = 134217728 # 128 MiB
$TargetPropIds = @(1,3,4,8,17,21) # 25 fora (complexo)

$Utf8NoBom  = New-Object System.Text.UTF8Encoding($false)
$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { [System.IO.Directory]::CreateDirectory($Path) | Out-Null }
}
function New-StreamWriterUtf8NoBom([string]$Path) {
  $dir = [System.IO.Path]::GetDirectoryName($Path)
  if ($dir -and (-not (Test-Path -LiteralPath $dir))) { [System.IO.Directory]::CreateDirectory($dir) | Out-Null }
  return New-Object System.IO.StreamWriter($Path, $false, $Utf8NoBom)
}
function Write-Utf8NoBomAllText([string]$Path, [string]$Text) {
  $dir = [System.IO.Path]::GetDirectoryName($Path)
  if ($dir -and (-not (Test-Path -LiteralPath $dir))) { [System.IO.Directory]::CreateDirectory($dir) | Out-Null }
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

function Get-LatestFile([string]$Dir, [string]$Pattern) {
  if (-not (Test-Path -LiteralPath $Dir)) { return $null }
  $latest = $null
  $latestTime = [DateTime]::MinValue
  foreach ($f in [System.IO.Directory]::EnumerateFiles($Dir, $Pattern, [System.IO.SearchOption]::TopDirectoryOnly)) {
    $fi = New-Object System.IO.FileInfo($f)
    if ($fi.LastWriteTime -gt $latestTime) { $latestTime = $fi.LastWriteTime; $latest = $f }
  }
  return $latest
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
function Extract-JsonWindow([string]$s) {
  $res = @{ ok = $false; json = $null; start = -1; end = -1; reason = "" }
  if ($null -eq $s -or $s.Length -eq 0) { $res.reason = "empty"; return $res }

  $len = $s.Length
  $start = -1
  $open = [char]0
  $close = [char]0

  for ($i = 0; $i -lt $len; $i++) {
    $c = $s[$i]
    if ($c -eq '{' -or $c -eq '[') { $start = $i; $open = $c; if ($c -eq '{') { $close = '}' } else { $close = ']' }; break }
  }
  if ($start -lt 0) { $res.reason = "no_open_brace"; return $res }

  $depth = 0
  $inString = $false
  $escape = $false

  for ($j = $start; $j -lt $len; $j++) {
    $ch = $s[$j]
    if ($inString) {
      if ($escape) { $escape = $false }
      else {
        if ($ch -eq '\') { $escape = $true }
        elseif ($ch -eq '"') { $inString = $false }
      }
    } else {
      if ($ch -eq '"') { $inString = $true }
      elseif ($ch -eq $open) { $depth++ }
      elseif ($ch -eq $close) {
        $depth--
        if ($depth -eq 0) { $res.ok = $true; $res.start = $start; $res.end = $j; $res.json = $s.Substring($start, ($j - $start + 1)); return $res }
      }
    }
  }
  $res.reason = "unbalanced_braces"
  return $res
}
function Try-ParseJson([string]$text, [ref]$ParseMode, [ref]$ParseError) {
  $ParseMode.Value = "raw"
  $ParseError.Value = $null

  $cmd = Get-Command ConvertFrom-Json -ErrorAction Stop
  $hasDepth = $false
  if ($cmd -and $cmd.Parameters -and $cmd.Parameters.ContainsKey("Depth")) { $hasDepth = $true }

  try {
    if ($hasDepth) { return (ConvertFrom-Json -InputObject $text -Depth 200) }
    return (ConvertFrom-Json -InputObject $text)
  } catch {
    $ParseMode.Value = "window"
    $w = Extract-JsonWindow -s $text
    if (-not $w.ok) { $ParseError.Value = "window_extract_fail:" + $w.reason; return $null }
    try {
      if ($hasDepth) { return (ConvertFrom-Json -InputObject $w.json -Depth 200) }
      return (ConvertFrom-Json -InputObject $w.json)
    } catch {
      $ParseError.Value = "json_parse_fail:" + $_.Exception.Message
      return $null
    }
  }
}

function Is-ObjectLike([object]$o) {
  if ($null -eq $o) { return $false }
  if ($o -is [System.Collections.IDictionary]) { return $true }
  if ($o -is [pscustomobject]) { return $true }
  return $false
}
function Get-Props([object]$o) {
  if ($o -is [System.Collections.IDictionary]) { return @($o.Keys) }
  return @($o.PSObject.Properties.Name)
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
function Set-PropValueI([object]$o, [string]$name, [object]$value) {
  if ($o -is [System.Collections.IDictionary]) {
    foreach ($k in @($o.Keys)) { if ([string]$k -ieq $name) { $o[$k] = $value; return $k } }
    $o[$name] = $value
    return $name
  }
  foreach ($p in $o.PSObject.Properties) {
    if ($p.Name -ieq $name) { $p.Value = $value; return $p.Name }
  }
  $o | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force
  return $name
}
function Get-HashKey([object]$fpv) {
  $keys = Get-Props -o $fpv
  foreach ($k in $keys) { if ([string]$k -ieq "hash") { return [string]$k } }
  foreach ($k in $keys) { if ([string]$k -match '(?i)hash') { return [string]$k } }
  return "hash"
}

function Get-Md5Hex([string]$Text) {
  if ($null -eq $Text) { $Text = "" }
  $bytes = $Utf8NoBom.GetBytes($Text)
  $md5 = [System.Security.Cryptography.MD5]::Create()
  try { $hash = $md5.ComputeHash($bytes) } finally { $md5.Dispose() }
  $sb = New-Object System.Text.StringBuilder
  foreach ($b in $hash) { [void]$sb.AppendFormat("{0:x2}", $b) }
  return $sb.ToString()
}
function Canonical-Text([object]$Value) {
  if ($null -eq $Value) { return "null" }
  if ($Value -is [bool]) { if ($Value) { return "true" } return "false" }
  if ($Value -is [string]) { return $Value }
  $ci = [System.Globalization.CultureInfo]::InvariantCulture
  if ($Value -is [int] -or $Value -is [long]) { return $Value.ToString($ci) }
  if ($Value -is [double]) {
    $d = [double]$Value
    if ([Math]::Abs($d - [Math]::Round($d)) -lt 0.0000000001) { return ([long][Math]::Round($d)).ToString($ci) }
    return $d.ToString($ci)
  }
  if ($Value -is [decimal]) {
    $dec = [decimal]$Value
    if ($dec -eq [Math]::Round($dec)) { return ([long][Math]::Round([double]$dec)).ToString($ci) }
    return $dec.ToString($ci)
  }
  return [string]$Value
}
function Expected-Hash([object]$Value) { return (Get-Md5Hex -Text (Canonical-Text -Value $Value)) }

function Coerce-Bool([object]$v, [ref]$changed) {
  $changed.Value = $false
  if ($null -eq $v) { return $v }
  if ($v -is [bool]) { return $v }
  if ($v -is [string]) {
    $s = $v.Trim()
    if ($s -match '^(?i:true|1|yes|y)$') { $changed.Value = $true; return $true }
    if ($s -match '^(?i:false|0|no|n)$') { $changed.Value = $true; return $false }
    return $v
  }
  if ($v -is [int] -or $v -is [long]) {
    if ([int64]$v -eq 1) { $changed.Value = $true; return $true }
    if ([int64]$v -eq 0) { $changed.Value = $true; return $false }
  }
  return $v
}
function Coerce-Int([object]$v, [ref]$changed) {
  $changed.Value = $false
  if ($null -eq $v) { return $v }
  if ($v -is [int]) { return $v }
  if ($v -is [long]) { $changed.Value = $true; return [int]$v }
  if ($v -is [double]) {
    $d = [double]$v
    if ([Math]::Abs($d - [Math]::Round($d)) -lt 0.0000000001) { $changed.Value = $true; return [int]([Math]::Round($d)) }
    return $v
  }
  if ($v -is [string]) {
    $s = $v.Trim()
    if ($s -match '^\d+$') { $changed.Value = $true; return [int]$s }
  }
  return $v
}
function Coerce-StringOrNull([object]$v, [ref]$changed) {
  $changed.Value = $false
  if ($null -eq $v) { return $v }
  if ($v -is [string]) { return $v }
  $changed.Value = $true
  return (Canonical-Text -Value $v)
}

function Escape-JsonString([string]$s) {
  if ($null -eq $s) { return "" }
  $sb = New-Object System.Text.StringBuilder
  for ($i=0; $i -lt $s.Length; $i++) {
    $ch = $s[$i]
    $code = [int][char]$ch
    if ($ch -eq '"') { [void]$sb.Append('\"') }
    elseif ($ch -eq '\') { [void]$sb.Append('\\') }
    elseif ($ch -eq "`b") { [void]$sb.Append('\b') }
    elseif ($ch -eq "`f") { [void]$sb.Append('\f') }
    elseif ($ch -eq "`n") { [void]$sb.Append('\n') }
    elseif ($ch -eq "`r") { [void]$sb.Append('\r') }
    elseif ($ch -eq "`t") { [void]$sb.Append('\t') }
    elseif ($code -lt 32) { [void]$sb.AppendFormat('\u{0:x4}', $code) }
    else { [void]$sb.Append($ch) }
  }
  return $sb.ToString()
}
function To-Ordered([object]$o, [switch]$IsRoot) {
  if ($null -eq $o) { return $null }

  if ($o -is [System.Collections.IEnumerable] -and -not ($o -is [string]) -and -not (Is-ObjectLike -o $o)) {
    $arr = New-Object System.Collections.ArrayList
    foreach ($el in $o) { [void]$arr.Add((To-Ordered -o $el)) }
    return ,$arr.ToArray()
  }

  if (Is-ObjectLike -o $o) {
    $ordered = [ordered]@{}
    $names = @()
    foreach ($p in (Get-Props -o $o)) { $names += [string]$p }

    if ($IsRoot) {
      $rootOrder = @("name","identifier","type","group","data","version","layouts")
      foreach ($k in $rootOrder) {
        foreach ($n in $names) { if ($n -ieq $k) { $ordered[$n] = (To-Ordered -o (Get-PropValueI -o $o -name $n)); break } }
      }
      foreach ($n in $names) {
        $exists = $false
        foreach ($k in $ordered.Keys) { if ([string]$k -ieq $n) { $exists = $true; break } }
        if (-not $exists) { $ordered[$n] = (To-Ordered -o (Get-PropValueI -o $o -name $n)) }
      }
      return $ordered
    }

    foreach ($n in $names) { $ordered[$n] = (To-Ordered -o (Get-PropValueI -o $o -name $n)) }
    return $ordered
  }

  return $o
}
function Write-JsonValue([System.Text.StringBuilder]$sb, [object]$v) {
  if ($null -eq $v) { [void]$sb.Append("null"); return }
  if ($v -is [bool]) { if ($v) { [void]$sb.Append("true") } else { [void]$sb.Append("false") }; return }
  if ($v -is [string]) { [void]$sb.Append('"'); [void]$sb.Append((Escape-JsonString -s $v)); [void]$sb.Append('"'); return }
  if ($v -is [int] -or $v -is [long] -or $v -is [double] -or $v -is [decimal]) {
    $ci = [System.Globalization.CultureInfo]::InvariantCulture
    [void]$sb.Append($v.ToString($ci))
    return
  }
  if ($v -is [System.Collections.IDictionary]) {
    [void]$sb.Append("{")
    $first = $true
    foreach ($k in $v.Keys) {
      if (-not $first) { [void]$sb.Append(",") } else { $first = $false }
      [void]$sb.Append('"'); [void]$sb.Append((Escape-JsonString -s ([string]$k))); [void]$sb.Append('":')
      Write-JsonValue -sb $sb -v $v[$k]
    }
    [void]$sb.Append("}")
    return
  }
  if ($v -is [System.Collections.IEnumerable] -and -not ($v -is [string])) {
    [void]$sb.Append("[")
    $first = $true
    foreach ($el in $v) {
      if (-not $first) { [void]$sb.Append(",") } else { $first = $false }
      Write-JsonValue -sb $sb -v $el
    }
    [void]$sb.Append("]")
    return
  }
  [void]$sb.Append('"'); [void]$sb.Append((Escape-JsonString -s ([string]$v))); [void]$sb.Append('"')
}

function Looks-LikePath([string]$v) {
  if ([string]::IsNullOrWhiteSpace($v)) { return $false }
  if ($v -match '^[A-Za-z]:\\') { return $true }
  if ($v -match '^\\\\') { return $true }
  if ($v -match '\.edt$' -or $v -match '\.edit$' -or $v -match '\.json$') { return $true }
  return $false
}
function Detect-PathColumn([object[]]$rows) {
  $props = @($rows[0].PSObject.Properties.Name)
  $bestCol = $null
  $bestScore = 0
  foreach ($col in $props) {
    $score = 0
    $checked = 0
    foreach ($r in $rows) {
      if ($checked -ge 200) { break }
      $checked++
      $sv = [string]$r.$col
      if (-not (Looks-LikePath -v $sv)) { continue }
      if (Test-Path -LiteralPath $sv) { $score++ }
    }
    if ($score -gt $bestScore) { $bestScore = $score; $bestCol = $col }
  }
  if ($bestScore -eq 0) { return $null }
  return $bestCol
}

Ensure-Dir -Path $FixDir

if ([string]::IsNullOrWhiteSpace($IssuesCsv)) {
  $IssuesCsv = Get-LatestFile -Dir $AuditDir -Pattern "editor3_audit_issues_v2_*.csv"
}
if ($null -eq $IssuesCsv -or (-not (Test-Path -LiteralPath $IssuesCsv))) {
  throw ("Nao encontrei editor3_audit_issues_v2_*.csv em: " + $AuditDir)
}

$issues = @(Import-Csv -LiteralPath $IssuesCsv -Delimiter ';')
if ($issues.Count -eq 0) { throw ("CSV vazio: " + $IssuesCsv) }

$pathCol = Detect-PathColumn -rows $issues
if ($null -eq $pathCol) { throw ("Nao consegui detectar coluna de path no CSV: " + $IssuesCsv) }

# candidatos = arquivos que possuem TYPE_* ou HASH_* (foco FIX PACK B)
$targets = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
foreach ($r in $issues) {
  $code = [string]$r.issue_code
  if ($code -like "TYPE_*" -or $code -like "HASH_*") {
    $p = [string]$r.$pathCol
    if (-not [string]::IsNullOrWhiteSpace($p) -and (Test-Path -LiteralPath $p)) { [void]$targets.Add($p) }
  }
}
$candidates = @($targets)

$filesScanned = 0
$filesSkippedSize = 0
$parseOk = 0
$parseFail = 0
$filesChanged = 0
$entriesChanged = 0
$decodeSalvageUsed = 0
$jsonWindowUsed = 0

$sw = New-StreamWriterUtf8NoBom -Path $ChangesCsv
try {
  $sw.WriteLine("file;json_path;property_id;old_value;new_value;old_hash;new_hash;action;mode")

  foreach ($file in $candidates) {
    $filesScanned++
    $fi = New-Object System.IO.FileInfo($file)
    if ($fi.Length -gt $MaxBytes) { $filesSkippedSize++; continue }

    $bytes = [System.IO.File]::ReadAllBytes($file)
    $usedSalvage = $false
    $text = Decode-Utf8Robust -Bytes $bytes -UsedSalvage ([ref]$usedSalvage)
    if ($usedSalvage) { $decodeSalvageUsed++ }
    $text = Clean-Text -s $text

    $parseMode = ""
    $parseErr = $null
    $json = Try-ParseJson -text $text -ParseMode ([ref]$parseMode) -ParseError ([ref]$parseErr)
    if ($null -eq $json) { $parseFail++; continue }
    $parseOk++
    if ($parseMode -eq "window") { $jsonWindowUsed++ }

    $changedThisFile = $false

    $stack = New-Object System.Collections.Generic.Stack[object]
    $stack.Push(@{ node = $json; path = "$" })

    while ($stack.Count -gt 0) {
      $it = $stack.Pop()
      $node = $it.node
      $path = $it.path
      if ($null -eq $node) { continue }

      if ($node -is [System.Collections.IEnumerable] -and -not ($node -is [string]) -and -not (Is-ObjectLike -o $node)) {
        $idx = 0
        foreach ($el in $node) { $stack.Push(@{ node = $el; path = ($path + "[" + $idx + "]") }); $idx++ }
        continue
      }

      if (Is-ObjectLike -o $node) {
        foreach ($pn in (Get-Props -o $node)) {
          $val = Get-PropValueI -o $node -name $pn
          $newPath = $path + "." + $pn

          if ([string]$pn -ieq "fieldPropertyValues") {
            if ($null -eq $val) { continue }
            if (-not ($val -is [System.Collections.IEnumerable]) -or ($val -is [string])) { continue }

            $i = 0
            foreach ($fpv in $val) {
              $fpvPath = $newPath + "[" + $i + "]"
              $i++
              if (-not (Is-ObjectLike -o $fpv)) { continue }

              $propObj = Get-PropValueI -o $fpv -name "property"
              $pidVal = Get-PropValueI -o $propObj -name "id"
              $pidNum = $null
              try { $pidNum = [int]$pidVal } catch { $pidNum = $null }
              if ($null -eq $pidNum) { continue }

              $isTarget = $false
              foreach ($t in $TargetPropIds) { if ($t -eq $pidNum) { $isTarget = $true; break } }
              if (-not $isTarget) { continue }

              $oldValue = Get-PropValueI -o $fpv -name "value"
              $hashKey = Get-HashKey -fpv $fpv
              $oldHash = Get-PropValueI -o $fpv -name $hashKey

              $newValue = $oldValue
              $didChange = $false

              if ($pidNum -eq 8 -or $pidNum -eq 17) {
                $tmp = $false
                $newValue = Coerce-Bool -v $oldValue -changed ([ref]$tmp)
                if ($tmp) { $didChange = $true }
              }
              elseif ($pidNum -eq 1) {
                $tmp = $false
                $newValue = Coerce-Int -v $oldValue -changed ([ref]$tmp)
                if ($tmp) { $didChange = $true }
              }
              elseif ($pidNum -eq 3 -or $pidNum -eq 4) {
                $tmp = $false
                $newValue = Coerce-StringOrNull -v $oldValue -changed ([ref]$tmp)
                if ($tmp) { $didChange = $true }
              }
              elseif ($pidNum -eq 21) {
                $tmp = $false
                $newValue = Coerce-StringOrNull -v $oldValue -changed ([ref]$tmp)
                if ($tmp) { $didChange = $true }
                if ($NormalizeSqlNewlines -and ($newValue -is [string])) {
                  $s = [string]$newValue
                  if ($s.Contains("`r") -or $s.Contains("`n")) {
                    $s2 = $s.Replace("`r`n", "`n").Replace("`r","`n").Replace("`n","\n")
                    if ($s2 -ne $s) { $newValue = $s2; $didChange = $true }
                  }
                }
              }

              $newHash = Expected-Hash -Value $newValue
              $oldHashStr = ""
              if ($null -ne $oldHash) { $oldHashStr = ([string]$oldHash).Trim() }
              if ([string]::IsNullOrWhiteSpace($oldHashStr) -or ($oldHashStr.ToLowerInvariant() -ne $newHash)) { $didChange = $true }

              if ($didChange) {
                $entriesChanged++
                $changedThisFile = $true

                $action = "recompute_hash"
                if ($pidNum -eq 8 -or $pidNum -eq 17) { $action = "coerce_bool_and_hash" }
                elseif ($pidNum -eq 1) { $action = "coerce_int_and_hash" }
                elseif ($pidNum -eq 21 -and $NormalizeSqlNewlines) { $action = "coerce_string_sql_and_hash" }
                elseif ($pidNum -eq 21) { $action = "coerce_string_and_hash" }
                elseif ($pidNum -eq 3 -or $pidNum -eq 4) { $action = "coerce_string_and_hash" }

                $line = (Csv-Escape $file) + ";" +
                        (Csv-Escape ($fpvPath + ".value")) + ";" +
                        (Csv-Escape $pidNum) + ";" +
                        (Csv-Escape (Canonical-Text -Value $oldValue)) + ";" +
                        (Csv-Escape (Canonical-Text -Value $newValue)) + ";" +
                        (Csv-Escape $oldHashStr) + ";" +
                        (Csv-Escape $newHash) + ";" +
                        (Csv-Escape $action) + ";" +
                        (Csv-Escape $Mode)
                $sw.WriteLine($line)

                if ($Mode -eq "APPLY") {
                  Set-PropValueI -o $fpv -name "value" -value $newValue | Out-Null
                  Set-PropValueI -o $fpv -name $hashKey -value $newHash | Out-Null
                }
              }
            }
            continue
          }

          $stack.Push(@{ node = $val; path = $newPath })
        }
      }
    }

    if ($Mode -eq "APPLY" -and $changedThisFile) {
      $filesChanged++

      $rel = $file
      if ($file.StartsWith($BasePath, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $file.Substring($BasePath.Length).TrimStart('\')
      } else {
        $rel = $file.Replace(":","").TrimStart('\')
      }

      $bak = Join-Path $BackupRoot $rel
      $bakDir = [System.IO.Path]::GetDirectoryName($bak)
      if (-not (Test-Path -LiteralPath $bakDir)) { [System.IO.Directory]::CreateDirectory($bakDir) | Out-Null }
      [System.IO.File]::WriteAllBytes($bak, [System.IO.File]::ReadAllBytes($file))

      $orderedRoot = To-Ordered -o $json -IsRoot
      $sb = New-Object System.Text.StringBuilder
      Write-JsonValue -sb $sb -v $orderedRoot
      [System.IO.File]::WriteAllText($file, $sb.ToString(), $Utf8NoBom)
    }
  }

} finally {
  if ($sw) { $sw.Dispose() }
}

$sb2 = New-Object System.Text.StringBuilder
[void]$sb2.AppendLine("FIX PACK B v2 SUMMARY")
[void]$sb2.AppendLine(("timestamp=" + $Stamp))
[void]$sb2.AppendLine(("mode=" + $Mode))
[void]$sb2.AppendLine(("issues_csv=" + $IssuesCsv))
[void]$sb2.AppendLine(("candidates_files=" + $candidates.Count))
[void]$sb2.AppendLine(("files_scanned=" + $filesScanned))
[void]$sb2.AppendLine(("files_skipped_size=" + $filesSkippedSize))
[void]$sb2.AppendLine(("parse_ok=" + $parseOk))
[void]$sb2.AppendLine(("parse_fail=" + $parseFail))
[void]$sb2.AppendLine(("decode_salvage_used=" + $decodeSalvageUsed))
[void]$sb2.AppendLine(("json_window_used=" + $jsonWindowUsed))
[void]$sb2.AppendLine(("entries_changed=" + $entriesChanged))
[void]$sb2.AppendLine(("files_changed=" + $filesChanged))
[void]$sb2.AppendLine(("changes_csv=" + $ChangesCsv))
if ($Mode -eq "APPLY") { [void]$sb2.AppendLine(("backup_root=" + $BackupRoot)) }

Write-Utf8NoBomAllText -Path $SummaryTxt -Text $sb2.ToString()

Write-Host ("OK: " + $SummaryTxt)
Write-Host ("OK: " + $ChangesCsv)
if ($Mode -eq "APPLY") { Write-Host ("OK: " + $BackupRoot) }