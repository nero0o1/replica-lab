param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BasePath = "J:\replica_lab"
$OutDir   = Join-Path $BasePath "20_outputs\audit"

$Stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$IssuesPath  = Join-Path $OutDir ("editor3_audit_issues_v2_" + $Stamp + ".csv")
$SummaryPath = Join-Path $OutDir ("editor3_audit_summary_v2_" + $Stamp + ".txt")

$MaxBytes = 134217728 # 128 MiB
$Utf8NoBom  = New-Object System.Text.UTF8Encoding($false)
$Utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { [System.IO.Directory]::CreateDirectory($Path) | Out-Null }
}

function Write-Utf8NoBomAllText([string]$Path, [string]$Text) {
  $dir = [System.IO.Path]::GetDirectoryName($Path)
  if ($dir -and (-not (Test-Path -LiteralPath $dir))) { [System.IO.Directory]::CreateDirectory($dir) | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom)
}

function New-StreamWriterUtf8NoBom([string]$Path) {
  $dir = [System.IO.Path]::GetDirectoryName($Path)
  if ($dir -and (-not (Test-Path -LiteralPath $dir))) { [System.IO.Directory]::CreateDirectory($dir) | Out-Null }
  return New-Object System.IO.StreamWriter($Path, $false, $Utf8NoBom)
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

function Extract-JsonWindow([string]$s) {
  $res = @{ ok = $false; json = $null; start = -1; end = -1; reason = "" }
  if ($null -eq $s -or $s.Length -eq 0) { $res.reason = "empty"; return $res }

  $len = $s.Length
  $start = -1
  $open = [char]0
  $close = [char]0

  for ($i = 0; $i -lt $len; $i++) {
    $c = $s[$i]
    if ($c -eq '{' -or $c -eq '[') {
      $start = $i
      $open = $c
      if ($c -eq '{') { $close = '}' } else { $close = ']' }
      break
    }
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
        if ($depth -eq 0) {
          $res.ok = $true
          $res.start = $start
          $res.end = $j
          $res.json = $s.Substring($start, ($j - $start + 1))
          return $res
        }
      }
    }
  }
  $res.reason = "unbalanced_braces"
  return $res
}

function Try-ParseJson([string]$text, [ref]$ParseMode, [ref]$ParseError) {
  $ParseMode.Value = "raw"
  $ParseError.Value = $null

  try {
    return (ConvertFrom-Json -InputObject $text)
  } catch {
    $ParseMode.Value = "window"
    $w = Extract-JsonWindow -s $text
    if (-not $w.ok) { $ParseError.Value = "window_extract_fail:" + $w.reason; return $null }
    try {
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

function Expected-Hash([object]$Value) {
  $txt = Canonical-Text -Value $Value
  return (Get-Md5Hex -Text $txt)
}

function Looks-LikePath([string]$v) {
  if ([string]::IsNullOrWhiteSpace($v)) { return $false }
  if ($v -match '^[A-Za-z]:\\') { return $true }
  if ($v -match '^\\\\') { return $true }
  if ($v -match '\.edit$' -or $v -match '\.edt$' -or $v -match '\.json$') { return $true }
  return $false
}

function Normalize-PathCandidate([string]$raw, [string]$Base) {
  if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
  $p = $raw.Trim().Replace("/", "\")
  if ($p -match '^[A-Za-z]:\\' -or $p -match '^\\\\') { return $p }
  return (Join-Path $Base $p)
}

function Get-LatestFileAny([string[]]$Dirs, [string]$Pattern) {
  $latest = $null
  $latestTime = [DateTime]::MinValue
  foreach ($d in $Dirs) {
    if (-not (Test-Path -LiteralPath $d)) { continue }
    foreach ($f in [System.IO.Directory]::EnumerateFiles($d, $Pattern, [System.IO.SearchOption]::TopDirectoryOnly)) {
      $fi = New-Object System.IO.FileInfo($f)
      if ($fi.LastWriteTime -gt $latestTime) { $latestTime = $fi.LastWriteTime; $latest = $f }
    }
  }
  return $latest
}

function Detect-PathColumn([object[]]$rows, [string]$Base) {
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
      $p = Normalize-PathCandidate -raw $sv -Base $Base
      if ($p -and (Test-Path -LiteralPath $p)) { $score++ }
    }
    if ($score -gt $bestScore) { $bestScore = $score; $bestCol = $col }
  }
  if ($bestScore -eq 0) { return $null }
  return $bestCol
}

function Detect-ClassifierColumns([object[]]$rows) {
  $ret = @{ likelyBoolCol = $null; labelCol = $null }
  $props = @($rows[0].PSObject.Properties.Name)

  foreach ($col in $props) {
    if ($col -match '(?i)EDITOR3.*JSON.*LIKELY' -or $col -match '(?i)JSON.*LIKELY') { $ret.likelyBoolCol = $col; break }
  }

  $bestCol = $null
  $bestScore = 0
  foreach ($col in $props) {
    $score = 0
    $checked = 0
    foreach ($r in $rows) {
      if ($checked -ge 500) { break }
      $checked++
      $sv = [string]$r.$col
      if ($sv -match '(?i)EDITOR3' -or $sv -match '(?i)JSON') {
        if ($sv -notmatch '(?i)EDITOR2' -and $sv -notmatch '(?i)XML') { $score++ }
      }
    }
    if ($score -gt $bestScore) { $bestScore = $score; $bestCol = $col }
  }
  if ($bestScore -gt 0) { $ret.labelCol = $bestCol }

  return $ret
}

Ensure-Dir -Path $OutDir

# 1) Prefer inventário discover_*.csv; fallback: scan extracted_edt3
$SearchDirs = @(
  (Join-Path $BasePath "20_outputs\ir"),
  (Join-Path $BasePath "20_outputs\audit"),
  (Join-Path $BasePath "20_outputs\fix")
)

$discover = Get-LatestFileAny -Dirs $SearchDirs -Pattern "discover_editor_candidates_*.csv"

$candidates = New-Object System.Collections.Generic.List[string]

if ($discover) {
  $rows = @(Import-Csv -LiteralPath $discover -Delimiter ';')
  if ($rows.Count -gt 0) {
    $pathCol = Detect-PathColumn -rows $rows -Base $BasePath
    if ($pathCol) {
      $classCols = Detect-ClassifierColumns -rows $rows
      $likelyBoolCol = $classCols.likelyBoolCol
      $labelCol = $classCols.labelCol

      foreach ($r in $rows) {
        $p = Normalize-PathCandidate -raw ([string]$r.$pathCol) -Base $BasePath
        if ($null -eq $p) { continue }

        $isCandidate = $false
        if ($likelyBoolCol) {
          $sv = ([string]$r.$likelyBoolCol).Trim()
          if ($sv -match '^(?i:true|1|yes|y)$') { $isCandidate = $true }
        }
        if (-not $isCandidate -and $labelCol) {
          $sl = [string]$r.$labelCol
          if (($sl -match '(?i)EDITOR3' -or $sl -match '(?i)JSON') -and ($sl -notmatch '(?i)EDITOR2') -and ($sl -notmatch '(?i)XML')) { $isCandidate = $true }
        }
        if ($isCandidate -and (Test-Path -LiteralPath $p)) { $candidates.Add($p) | Out-Null }
      }
    }
  }
}

if ($candidates.Count -eq 0) {
  $fallback = Join-Path $BasePath "10_work\extracted_edt3"
  if (-not (Test-Path -LiteralPath $fallback)) { throw "Sem discover CSV e sem fallback: $fallback" }
  foreach ($f in Get-ChildItem -LiteralPath $fallback -Recurse -Filter "*.edt" -File) {
    if ($f.Length -gt $MaxBytes) { continue }
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $used = $false
    $txt = Decode-Utf8Robust -Bytes $bytes -UsedSalvage ([ref]$used)
    $txt = Clean-Text -s $txt
    $pm = ""
    $pe = $null
    $obj = Try-ParseJson -text $txt -ParseMode ([ref]$pm) -ParseError ([ref]$pe)
    if ($obj) { $candidates.Add($f.FullName) | Out-Null }
  }
}

$files_scanned = 0
$parse_ok = 0
$parse_fail = 0
$issues_total = 0
$decode_salvage_used = 0
$json_window_used = 0

$sw = New-StreamWriterUtf8NoBom -Path $IssuesPath
try {
  $sw.WriteLine("file;root_identifier;issue_code;property_id;json_path;found;expected;action;severity")

  foreach ($file in $candidates) {
    $files_scanned++
    $fi = New-Object System.IO.FileInfo($file)
    if ($fi.Length -gt $MaxBytes) { continue }

    $bytes = [System.IO.File]::ReadAllBytes($file)
    $usedSalvage = $false
    $text = Decode-Utf8Robust -Bytes $bytes -UsedSalvage ([ref]$usedSalvage)
    if ($usedSalvage) { $decode_salvage_used++ }
    $text = Clean-Text -s $text

    $parseMode = ""
    $parseErr = $null
    $json = Try-ParseJson -text $text -ParseMode ([ref]$parseMode) -ParseError ([ref]$parseErr)

    if ($null -eq $json) {
      $parse_fail++
      $issues_total++
      $line = (Csv-Escape $file) + ";;PARSE_FAIL;;$;" +
              (Csv-Escape ("json_parse_fail:" + $parseErr)) + ";" +
              (Csv-Escape "valid JSON object/array") + ";" +
              (Csv-Escape "inspect_raw_and_salvage_window") + ";FAIL"
      $sw.WriteLine($line)
      continue
    }

    $parse_ok++
    if ($parseMode -eq "window") { $json_window_used++ }

    $rootId = Get-PropValueI -o $json -name "identifier"
    $rootIdStr = ""
    if ($null -ne $rootId) { $rootIdStr = [string]$rootId }

    # identifier format
    $okIdent = $true
    if ([string]::IsNullOrWhiteSpace($rootIdStr)) { $okIdent = $false }
    else {
      if ($rootIdStr -notmatch '^[A-Z0-9]+(_[A-Z0-9]+)*$') { $okIdent = $false }
    }
    if (-not $okIdent) {
      $issues_total++
      $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";IDENTIFIER_FORMAT_FAIL;;$.identifier;" +
              (Csv-Escape $rootIdStr) + ";" +
              (Csv-Escape "UPPER_SNAKE_CASE") + ";" +
              (Csv-Escape "fix_identifier_format") + ";FAIL"
      $sw.WriteLine($line)
    }

    # version + version.hash
    $ver = Get-PropValueI -o $json -name "version"
    if ($null -eq $ver) {
      $issues_total++
      $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";VERSION_MISSING;;$.version;" +
              (Csv-Escape "null") + ";" +
              (Csv-Escape "object with hash") + ";" +
              (Csv-Escape "add_version_object") + ";FAIL"
      $sw.WriteLine($line)
    } else {
      $vh = Get-PropValueI -o $ver -name "hash"
      $vhStr = ""
      if ($null -ne $vh) { $vhStr = ([string]$vh).Trim() }
      if ([string]::IsNullOrWhiteSpace($vhStr)) {
        $issues_total++
        $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";VERSION_HASH_MISSING;;$.version.hash;" +
                (Csv-Escape $vhStr) + ";" +
                (Csv-Escape "non-empty hash") + ";" +
                (Csv-Escape "compute_and_set_version_hash") + ";FAIL"
        $sw.WriteLine($line)
      }
    }

    # traverse for fieldPropertyValues
# --- PATCH: preserve empty arrays (avoid @() collapsing to $null) ---
function Get-PropValueI([object]$o, [string]$name) {
  if ($null -eq $o) { return $null }

  if ($o -is [System.Collections.IDictionary]) {
    foreach ($k in $o.Keys) {
      if ([string]$k -ieq $name) { return ,$o[$k] }
    }
    return $null
  }

  $ps = $o.PSObject
  if ($null -eq $ps) { return $null }

  $m = $ps.Properties.Match($name)
  if ($null -eq $m -or $m.Count -eq 0) { return $null }

  return ,$m[0].Value
}
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
            if ($null -eq $val) {
              $issues_total++
              $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";FIELDPROPS_NULL;;" + (Csv-Escape $newPath) + ";" +
                      (Csv-Escape "null") + ";" +
                      (Csv-Escape "array of objects") + ";" +
                      (Csv-Escape "rebuild_fieldPropertyValues") + ";FAIL"
              $sw.WriteLine($line)
              continue
            }

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
              foreach ($t in @(1,3,4,8,17,21,25)) { if ($t -eq $pidNum) { $isTarget = $true; break } }
              if (-not $isTarget) { continue }

              $v = Get-PropValueI -o $fpv -name "value"
              $hashKey = Get-HashKey -fpv $fpv
              $h = Get-PropValueI -o $fpv -name $hashKey
              $hStr = ""
              if ($null -ne $h) { $hStr = ([string]$h).Trim() }

              # TYPE checks
              if ($pidNum -eq 8 -or $pidNum -eq 17) {
                if (-not ($v -is [bool])) {
                  $issues_total++
                  $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";TYPE_BOOL_FAIL;" + (Csv-Escape $pidNum) + ";" +
                          (Csv-Escape ($fpvPath + ".value")) + ";" +
                          (Csv-Escape (Canonical-Text -Value $v)) + ";" +
                          (Csv-Escape "boolean true/false") + ";" +
                          (Csv-Escape "coerce_bool") + ";FAIL"
                  $sw.WriteLine($line)
                }
              }
              elseif ($pidNum -eq 1) {
                if (-not ($v -is [int]) -and -not ($v -is [long])) {
                  $issues_total++
                  $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";TYPE_INT_FAIL;" + (Csv-Escape $pidNum) + ";" +
                          (Csv-Escape ($fpvPath + ".value")) + ";" +
                          (Csv-Escape (Canonical-Text -Value $v)) + ";" +
                          (Csv-Escape "integer") + ";" +
                          (Csv-Escape "coerce_int") + ";FAIL"
                  $sw.WriteLine($line)
                }
              }
              elseif ($pidNum -eq 3) {
                if ($null -eq $v -or -not ($v -is [string])) {
                  $issues_total++
                  $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";TYPE_STRING_FAIL;" + (Csv-Escape $pidNum) + ";" +
                          (Csv-Escape ($fpvPath + ".value")) + ";" +
                          (Csv-Escape (Canonical-Text -Value $v)) + ";" +
                          (Csv-Escape "string") + ";" +
                          (Csv-Escape "coerce_string") + ";FAIL"
                  $sw.WriteLine($line)
                }
              }
              elseif ($pidNum -eq 4) {
                if (-not ($null -eq $v) -and -not ($v -is [string])) {
                  $issues_total++
                  $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";TYPE_STRING_FAIL;" + (Csv-Escape $pidNum) + ";" +
                          (Csv-Escape ($fpvPath + ".value")) + ";" +
                          (Csv-Escape (Canonical-Text -Value $v)) + ";" +
                          (Csv-Escape "string or null") + ";" +
                          (Csv-Escape "coerce_string_or_null") + ";FAIL"
                  $sw.WriteLine($line)
                }
              }
              elseif ($pidNum -eq 21) {
                if ($null -eq $v -or -not ($v -is [string])) {
                  $issues_total++
                  $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";TYPE_STRING_FAIL;" + (Csv-Escape $pidNum) + ";" +
                          (Csv-Escape ($fpvPath + ".value")) + ";" +
                          (Csv-Escape (Canonical-Text -Value $v)) + ";" +
                          (Csv-Escape "string") + ";" +
                          (Csv-Escape "coerce_string") + ";FAIL"
                  $sw.WriteLine($line)
                } else {
                  $s = [string]$v
                  if ($s.Contains("`r") -or $s.Contains("`n")) {
                    $issues_total++
                    $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";SQL_HAS_NEWLINE;" + (Csv-Escape $pidNum) + ";" +
                            (Csv-Escape ($fpvPath + ".value")) + ";" +
                            (Csv-Escape "contains CR/LF") + ";" +
                            (Csv-Escape "replace CR/LF with literal \n") + ";" +
                            (Csv-Escape "normalize_sql_newlines") + ";WARN"
                    $sw.WriteLine($line)
                  }
                }
              }
              elseif ($pidNum -eq 25) {
                $isArr = $false
                if ($null -ne $v) {
                  if ($v -is [System.Collections.IEnumerable] -and -not ($v -is [string]) -and -not (Is-ObjectLike -o $v)) { $isArr = $true }
                }
                if (-not $isArr) {
                  $issues_total++
                  $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";TYPE_ARRAY_FAIL;" + (Csv-Escape $pidNum) + ";" +
                          (Csv-Escape ($fpvPath + ".value")) + ";" +
                          (Csv-Escape (Canonical-Text -Value $v)) + ";" +
                          (Csv-Escape "array of {value,order}") + ";" +
                          (Csv-Escape "rebuild_listaValores") + ";FAIL"
                  $sw.WriteLine($line)
                }
              }

              # HASH checks
              if ([string]::IsNullOrWhiteSpace($hStr)) {
                $issues_total++
                $exp = "present"
                if ($pidNum -ne 25) { $exp = Expected-Hash -Value $v }
                $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";HASH_MISSING;" + (Csv-Escape $pidNum) + ";" +
                        (Csv-Escape ($fpvPath + "." + $hashKey)) + ";" +
                        (Csv-Escape $hStr) + ";" +
                        (Csv-Escape $exp) + ";" +
                        (Csv-Escape "set_hash") + ";FAIL"
                $sw.WriteLine($line)
              } else {
                if ($pidNum -ne 25) {
                  $expHash = Expected-Hash -Value $v
                  if ($hStr.ToLowerInvariant() -ne $expHash) {
                    $issues_total++
                    $line = (Csv-Escape $file) + ";" + (Csv-Escape $rootIdStr) + ";HASH_MISMATCH;" + (Csv-Escape $pidNum) + ";" +
                            (Csv-Escape ($fpvPath + "." + $hashKey)) + ";" +
                            (Csv-Escape $hStr) + ";" +
                            (Csv-Escape $expHash) + ";" +
                            (Csv-Escape "recompute_hash") + ";FAIL"
                    $sw.WriteLine($line)
                  }
                }
              }
            }

            continue
          }

          $stack.Push(@{ node = $val; path = $newPath })
        }
      }
    }
  }
}
finally {
  if ($sw) { $sw.Dispose() }
}

# Summary
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("timestamp=" + $Stamp)
[void]$sb.AppendLine("discover_csv=" + $(if ($discover) { $discover } else { "" }))
[void]$sb.AppendLine("candidates_files=" + $candidates.Count)
[void]$sb.AppendLine("files_scanned=" + $files_scanned)
[void]$sb.AppendLine("parse_ok=" + $parse_ok)
[void]$sb.AppendLine("parse_fail=" + $parse_fail)
[void]$sb.AppendLine("decode_salvage_used=" + $decode_salvage_used)
[void]$sb.AppendLine("json_window_used=" + $json_window_used)
[void]$sb.AppendLine("issues_total=" + $issues_total)
[void]$sb.AppendLine("issues_csv=" + $IssuesPath)

Write-Utf8NoBomAllText -Path $SummaryPath -Text $sb.ToString()

Write-Host ("OK: " + $SummaryPath)
Write-Host ("OK: " + $IssuesPath)