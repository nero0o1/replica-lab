# ============================================================
# FIX PACK B v3 — MV Editor3: Fill NULL types + Hash Recompute
# PowerShell 5.1 compatible
#
# Goals (based on audit):
#   - Fix TYPE_INT_FAIL pid=1 when value=null -> fill via parent/file/global mode
#   - Fix TYPE_BOOL_FAIL pid=8 when value=null -> fill via parent/file/global mode
#   - Fix TYPE_STRING_FAIL pid=3 when value=null -> fill "" (or inherit/mode) + hash
#   - Fix FIELDPROPS_NULL: fieldPropertyValues null -> []
#   - Fix IDENTIFIER_FORMAT_FAIL: normalize to UPPER_SNAKE_CASE (no accents)
#   - Recompute hash for any touched fpv (value hash = md5(canonical text))
#
# Constraints:
#   - No ?: ; no $propId
#   - No Out-File/Set-Content/redirection
#   - UTF-8 no BOM via .NET only
#   - CSV delimiter ';'
# ============================================================

param(
  [ValidateSet("DRYRUN","APPLY")]
  [string]$Mode = "DRYRUN",
  [string]$IssuesCsv = "",
  [int]$MaxBytes = 134217728
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BasePath = "J:\replica_lab"
$AuditDir = Join-Path $BasePath "20_outputs\audit"
$FixDir   = Join-Path $BasePath "20_outputs\fix"

$Stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$BackupRoot = Join-Path $FixDir ("backup_fixpackB3_" + $Stamp)
$ChangesCsv = Join-Path $FixDir ("fixpackB3_changes_" + $Stamp + ".csv")
$SummaryTxt = Join-Path $FixDir ("fixpackB3_summary_"  + $Stamp + ".txt")

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

function Expected-Hash([object]$Value) {
  $txt = Canonical-Text -Value $Value
  return (Get-Md5Hex -Text $txt)
}

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

function Coerce-String([object]$v, [ref]$changed) {
  $changed.Value = $false
  if ($null -eq $v) { return $v }
  if ($v -is [string]) { return $v }
  $changed.Value = $true
  return (Canonical-Text -Value $v)
}

function Get-FpvPid([object]$fpv) {
  if (-not (Is-ObjectLike -o $fpv)) { return $null }
  $propObj = Get-PropValueI -o $fpv -name "property"
  $pidVal = Get-PropValueI -o $propObj -name "id"
  try { return [int]$pidVal } catch { return $null }
}

function Find-FpvInArray([object]$arr, [int]$propId) {
  if ($null -eq $arr) { return $null }
  if (-not ($arr -is [System.Collections.IEnumerable]) -or ($arr -is [string])) { return $null }
  foreach ($fpv in $arr) {
    $p = Get-FpvPid -fpv $fpv
    if ($null -ne $p -and $p -eq $propId) { return $fpv }
  }
  return $null
}

function Normalize-Identifier([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return $s }
  $t = $s.Trim()

  $norm = $t.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $norm.ToCharArray()) {
    $uc = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
    if ($uc -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($ch) }
  }
  $t2 = $sb.ToString().Normalize([Text.NormalizationForm]::FormC)

  $t2 = $t2.ToUpperInvariant()
  $t2 = [Regex]::Replace($t2, '[^A-Z0-9]+', '_')
  $t2 = [Regex]::Replace($t2, '_{2}', '_')
  $t2 = $t2.Trim('_')
  return $t2
}

function Escape-JsonString([string]$s) {
  if ($null -eq $s) { return "" }
  $sb = New-Object System.Text.StringBuilder
  $len = $s.Length
  for ($i=0; $i -lt $len; $i++) {
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
        foreach ($n in $names) {
          if ($n -ieq $k) { $ordered[$n] = (To-Ordered -o (Get-PropValueI -o $o -name $n)); break }
        }
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

Ensure-Dir -Path $FixDir

if ([string]::IsNullOrWhiteSpace($IssuesCsv)) {
  $IssuesCsv = Get-LatestFile -Dir $AuditDir -Pattern "editor3_audit_issues_v2_*.csv"
}
if ($null -eq $IssuesCsv -or (-not (Test-Path -LiteralPath $IssuesCsv))) {
  throw "Nao encontrei issues csv (editor3_audit_issues_v2_*.csv) em: $AuditDir"
}

$issues = @(Import-Csv -LiteralPath $IssuesCsv -Delimiter ';')
if ($issues.Count -eq 0) { throw "Issues CSV vazio: $IssuesCsv" }

# Target only files that actually have issues we can act on
$targetFiles = @(
  $issues |
    Where-Object {
      $_.issue_code -like "TYPE_*" -or
      $_.issue_code -eq "FIELDPROPS_NULL" -or
      $_.issue_code -eq "IDENTIFIER_FORMAT_FAIL"
    } |
    Select-Object -ExpandProperty file -Unique
)

if ($targetFiles.Count -eq 0) { throw "Nenhum arquivo-alvo encontrado nas issues para TYPE_*/FIELDPROPS_NULL/IDENTIFIER_FORMAT_FAIL" }

# ---------- PASS 1: compute global modes (evidence-based) ----------
$globalIntCounts  = @{}
$globalBoolCounts = @{ "true" = 0; "false" = 0 }

$parseOk = 0
$parseFail = 0
$decodeSalvageUsed = 0
$jsonWindowUsed = 0

foreach ($file in $targetFiles) {
  if (-not (Test-Path -LiteralPath $file)) { continue }
  $fi = New-Object System.IO.FileInfo($file)
  if ($fi.Length -gt $MaxBytes) { continue }

  $bytes = [System.IO.File]::ReadAllBytes($file)
  $usedSalvage = $false
  $text = Decode-Utf8Robust -Bytes $bytes -UsedSalvage ([ref]$usedSalvage)
  if ($usedSalvage) { $decodeSalvageUsed++ }
  $text = Clean-Text -s $text

  $pm = ""
  $pe = $null
  $json = Try-ParseJson -text $text -ParseMode ([ref]$pm) -ParseError ([ref]$pe)
  if ($null -eq $json) { $parseFail++; continue }
  $parseOk++
  if ($pm -eq "window") { $jsonWindowUsed++ }

  # Walk nodes, collect pid=1 ints and pid=8 bools (non-null only)
  $stack = New-Object System.Collections.Generic.Stack[object]
  $stack.Push($json)

  while ($stack.Count -gt 0) {
    $node = $stack.Pop()
    if ($null -eq $node) { continue }

    if ($node -is [System.Collections.IEnumerable] -and -not ($node -is [string]) -and -not (Is-ObjectLike -o $node)) {
      foreach ($el in $node) { $stack.Push($el) }
      continue
    }

    if (Is-ObjectLike -o $node) {
      foreach ($pn in (Get-Props -o $node)) {
        $val = Get-PropValueI -o $node -name $pn

        if ([string]$pn -ieq "fieldPropertyValues" -and $null -ne $val -and ($val -is [System.Collections.IEnumerable]) -and -not ($val -is [string])) {
          foreach ($fpv in $val) {
            $propId = Get-FpvPid -fpv $fpv
            if ($null -eq $propId) { continue }

            if ($propId -eq 1) {
              $v = Get-PropValueI -o $fpv -name "value"
              if ($null -ne $v) {
                $chg = $false
                $iv = Coerce-Int -v $v -changed ([ref]$chg)
                if ($iv -is [int]) {
                  $k = [string]$iv
                  if (-not $globalIntCounts.ContainsKey($k)) { $globalIntCounts[$k] = 0 }
                  $globalIntCounts[$k] = [int]$globalIntCounts[$k] + 1
                }
              }
            }
            elseif ($propId -eq 8) {
              $v = Get-PropValueI -o $fpv -name "value"
              if ($null -ne $v) {
                $chg = $false
                $bv = Coerce-Bool -v $v -changed ([ref]$chg)
                if ($bv -is [bool]) {
                  if ($bv) { $globalBoolCounts["true"] = [int]$globalBoolCounts["true"] + 1 }
                  else { $globalBoolCounts["false"] = [int]$globalBoolCounts["false"] + 1 }
                }
              }
            }
          }
        } else {
          $stack.Push($val)
        }
      }
    }
  }
}

# Determine global modes deterministically (tie-break: smaller int; false beats true)
$globalIntMode = $null
if ($globalIntCounts.Keys.Count -gt 0) {
  $bestN = -1
  $bestK = $null
  foreach ($k in ($globalIntCounts.Keys | Sort-Object {[int]$_})) {
    $n = [int]$globalIntCounts[$k]
    if ($n -gt $bestN) { $bestN = $n; $bestK = $k }
  }
  if ($null -ne $bestK) { $globalIntMode = [int]$bestK }
}

$globalBoolMode = $null
if (($globalBoolCounts["true"] + $globalBoolCounts["false"]) -gt 0) {
  if ($globalBoolCounts["false"] -ge $globalBoolCounts["true"]) { $globalBoolMode = $false } else { $globalBoolMode = $true }
}

# ---------- PASS 2: apply fixes ----------
$filesScanned = 0
$filesSkippedSize = 0
$filesMissing = 0
$filesChanged = 0
$entriesChanged = 0

$fillFromParent = 0
$fillFromFileMode = 0
$fillFromGlobalMode = 0
$fillUnresolved = 0
$setFieldPropsEmpty = 0
$fixIdentifier = 0
$coerceScalar = 0
$hashRecompute = 0

$sw = New-StreamWriterUtf8NoBom -Path $ChangesCsv
try {
  $sw.WriteLine("file;json_path;property_id;old_value;new_value;old_hash;new_hash;action;mode")

  foreach ($file in $targetFiles) {
    if (-not (Test-Path -LiteralPath $file)) { $filesMissing++; continue }
    $fi = New-Object System.IO.FileInfo($file)
    if ($fi.Length -gt $MaxBytes) { $filesSkippedSize++; continue }
    $filesScanned++

    $bytes = [System.IO.File]::ReadAllBytes($file)
    $usedSalvage = $false
    $text = Decode-Utf8Robust -Bytes $bytes -UsedSalvage ([ref]$usedSalvage)
    $text = Clean-Text -s $text

    $pm = ""
    $pe = $null
    $json = Try-ParseJson -text $text -ParseMode ([ref]$pm) -ParseError ([ref]$pe)
    if ($null -eq $json) { continue }

    # compute per-file modes (pid=1 int, pid=8 bool)
    $fileIntCounts = @{}
    $fileBoolCounts = @{ "true" = 0; "false" = 0 }

    $stack0 = New-Object System.Collections.Generic.Stack[object]
    $stack0.Push($json)
    while ($stack0.Count -gt 0) {
      $node0 = $stack0.Pop()
      if ($null -eq $node0) { continue }

      if ($node0 -is [System.Collections.IEnumerable] -and -not ($node0 -is [string]) -and -not (Is-ObjectLike -o $node0)) {
        foreach ($el0 in $node0) { $stack0.Push($el0) }
        continue
      }

      if (Is-ObjectLike -o $node0) {
        foreach ($pn0 in (Get-Props -o $node0)) {
          $val0 = Get-PropValueI -o $node0 -name $pn0
          if ([string]$pn0 -ieq "fieldPropertyValues" -and $null -ne $val0 -and ($val0 -is [System.Collections.IEnumerable]) -and -not ($val0 -is [string])) {
            foreach ($fpv0 in $val0) {
              $pid0 = Get-FpvPid -fpv $fpv0
              if ($null -eq $pid0) { continue }

              if ($pid0 -eq 1) {
                $v0 = Get-PropValueI -o $fpv0 -name "value"
                if ($null -ne $v0) {
                  $chg0 = $false
                  $iv0 = Coerce-Int -v $v0 -changed ([ref]$chg0)
                  if ($iv0 -is [int]) {
                    $k0 = [string]$iv0
                    if (-not $fileIntCounts.ContainsKey($k0)) { $fileIntCounts[$k0] = 0 }
                    $fileIntCounts[$k0] = [int]$fileIntCounts[$k0] + 1
                  }
                }
              } elseif ($pid0 -eq 8) {
                $v0 = Get-PropValueI -o $fpv0 -name "value"
                if ($null -ne $v0) {
                  $chg0 = $false
                  $bv0 = Coerce-Bool -v $v0 -changed ([ref]$chg0)
                  if ($bv0 -is [bool]) {
                    if ($bv0) { $fileBoolCounts["true"] = [int]$fileBoolCounts["true"] + 1 }
                    else { $fileBoolCounts["false"] = [int]$fileBoolCounts["false"] + 1 }
                  }
                }
              }
            }
          } else {
            $stack0.Push($val0)
          }
        }
      }
    }

    $fileIntMode = $null
    if ($fileIntCounts.Keys.Count -gt 0) {
      $bestN = -1
      $bestK = $null
      foreach ($k in ($fileIntCounts.Keys | Sort-Object {[int]$_})) {
        $n = [int]$fileIntCounts[$k]
        if ($n -gt $bestN) { $bestN = $n; $bestK = $k }
      }
      if ($null -ne $bestK) { $fileIntMode = [int]$bestK }
    }

    $fileBoolMode = $null
    if (($fileBoolCounts["true"] + $fileBoolCounts["false"]) -gt 0) {
      if ($fileBoolCounts["false"] -ge $fileBoolCounts["true"]) { $fileBoolMode = $false } else { $fileBoolMode = $true }
    }

    $changedThisFile = $false

    # root.identifier normalization if needed
    $idVal = Get-PropValueI -o $json -name "identifier"
    if ($null -ne $idVal -and ($idVal -is [string])) {
      $idNorm = Normalize-Identifier -s $idVal
      if ($idNorm -ne $idVal -and -not [string]::IsNullOrWhiteSpace($idNorm)) {
        $fixIdentifier++
        $changedThisFile = $true
        $line = (Csv-Escape $file) + ";" + (Csv-Escape "$.identifier") + ";;" +
                (Csv-Escape $idVal) + ";" + (Csv-Escape $idNorm) + ";;;" +
                (Csv-Escape "normalize_identifier") + ";" + (Csv-Escape $Mode)
        $sw.WriteLine($line)
        if ($Mode -eq "APPLY") { Set-PropValueI -o $json -name "identifier" -value $idNorm | Out-Null }
      }
    }

    # Walk tree with context (to use fieldParent inheritance)
    $stack = New-Object System.Collections.Generic.Stack[object]
    $stack.Push(@{ node = $json; path = "$"; parent = $null })

    while ($stack.Count -gt 0) {
      $it = $stack.Pop()
      $node = $it.node
      $path = $it.path
      $parentNode = $it.parent

      if ($null -eq $node) { continue }

      if ($node -is [System.Collections.IEnumerable] -and -not ($node -is [string]) -and -not (Is-ObjectLike -o $node)) {
        $idx = 0
        foreach ($el in $node) {
          $stack.Push(@{ node = $el; path = ($path + "[" + $idx + "]"); parent = $parentNode })
          $idx++
        }
        continue
      }

      if (Is-ObjectLike -o $node) {
        foreach ($pn in (Get-Props -o $node)) {
          $val = Get-PropValueI -o $node -name $pn
          $newPath = $path + "." + $pn

          # FIELDPROPS_NULL fix: fieldPropertyValues null -> []
          if ([string]$pn -ieq "fieldPropertyValues") {
            if ($null -eq $val) {
              $setFieldPropsEmpty++
              $changedThisFile = $true
              $line = (Csv-Escape $file) + ";" + (Csv-Escape $newPath) + ";;" +
                      (Csv-Escape "null") + ";" + (Csv-Escape "[]") + ";;;" +
                      (Csv-Escape "set_fieldPropertyValues_empty_array") + ";" + (Csv-Escape $Mode)
              $sw.WriteLine($line)
              if ($Mode -eq "APPLY") { Set-PropValueI -o $node -name $pn -value @() | Out-Null }
              continue
            }

            if ($val -is [System.Collections.IEnumerable] -and -not ($val -is [string])) {
              $i = 0
              foreach ($fpv in $val) {
                $fpvPath = $newPath + "[" + $i + "]"
                $i++
                if (-not (Is-ObjectLike -o $fpv)) { continue }

                $propId = Get-FpvPid -fpv $fpv
                if ($null -eq $propId) { continue }
                if ($propId -ne 1 -and $propId -ne 8 -and $propId -ne 3) { continue }

                $oldValue = Get-PropValueI -o $fpv -name "value"
                $hashKey = Get-HashKey -fpv $fpv
                $oldHash = Get-PropValueI -o $fpv -name $hashKey
                $oldHashStr = ""
                if ($null -ne $oldHash) { $oldHashStr = ([string]$oldHash).Trim() }

                $newValue = $oldValue
                $action = ""

                # fill NULLs first
                if ($null -eq $newValue) {
                  $filled = $false

                  # 1) inherit from fieldParent chain if available
                  $pnode = $null
                  if ([string]$path -match '\.fieldParent$') { $pnode = $null } else { $pnode = Get-PropValueI -o $node -name "fieldParent" }

                  $probe = $pnode
                  while (-not $filled -and $null -ne $probe) {
                    $pp = Get-PropValueI -o $probe -name "fieldPropertyValues"
                    $match = Find-FpvInArray -arr $pp -pid $propId
                    if ($null -ne $match) {
                      $pv = Get-PropValueI -o $match -name "value"
                      if ($null -ne $pv) {
                        $newValue = $pv
                        $filled = $true
                        $fillFromParent++
                        $action = "fill_null_from_parent"
                        break
                      }
                    }
                    $probe = Get-PropValueI -o $probe -name "fieldParent"
                  }

                  # 2) per-file mode
                  if (-not $filled) {
                    if ($propId -eq 1 -and $null -ne $fileIntMode) { $newValue = $fileIntMode; $filled = $true; $fillFromFileMode++; $action = "fill_null_from_file_mode" }
                    elseif ($propId -eq 8 -and $null -ne $fileBoolMode) { $newValue = $fileBoolMode; $filled = $true; $fillFromFileMode++; $action = "fill_null_from_file_mode" }
                    elseif ($propId -eq 3) { $newValue = ""; $filled = $true; $fillFromFileMode++; $action = "fill_null_string_empty" }
                  }

                  # 3) global mode
                  if (-not $filled) {
                    if ($propId -eq 1 -and $null -ne $globalIntMode) { $newValue = $globalIntMode; $filled = $true; $fillFromGlobalMode++; $action = "fill_null_from_global_mode" }
                    elseif ($propId -eq 8 -and $null -ne $globalBoolMode) { $newValue = $globalBoolMode; $filled = $true; $fillFromGlobalMode++; $action = "fill_null_from_global_mode" }
                    elseif ($propId -eq 3) { $newValue = ""; $filled = $true; $fillFromGlobalMode++; $action = "fill_null_string_empty" }
                  }

                  if (-not $filled) {
                    $fillUnresolved++
                    continue
                  }
                }

                # then coerce type if still wrong shape
                $didCoerce = $false
                if ($propId -eq 1) {
                  $chg = $false
                  $cv = Coerce-Int -v $newValue -changed ([ref]$chg)
                  if ($chg) { $didCoerce = $true; $coerceScalar++ }
                  $newValue = $cv
                }
                elseif ($propId -eq 8) {
                  $chg = $false
                  $cv = Coerce-Bool -v $newValue -changed ([ref]$chg)
                  if ($chg) { $didCoerce = $true; $coerceScalar++ }
                  $newValue = $cv
                }
                elseif ($propId -eq 3) {
                  $chg = $false
                  $cv = Coerce-String -v $newValue -changed ([ref]$chg)
                  if ($chg) { $didCoerce = $true; $coerceScalar++ }
                  $newValue = $cv
                  if ($null -eq $newValue) { $newValue = "" }
                }

                $newHash = Expected-Hash -Value $newValue

                $needsWrite = $false
                if ((Canonical-Text -Value $oldValue) -ne (Canonical-Text -Value $newValue)) { $needsWrite = $true }
                if ([string]::IsNullOrWhiteSpace($oldHashStr) -or ($oldHashStr.ToLowerInvariant() -ne $newHash)) { $needsWrite = $true }

                if ($needsWrite) {
                  $entriesChanged++
                  $hashRecompute++
                  $changedThisFile = $true
                  if ([string]::IsNullOrWhiteSpace($action)) { $action = "coerce_or_hash" }

                  $line = (Csv-Escape $file) + ";" +
                          (Csv-Escape ($fpvPath + ".value")) + ";" +
                          (Csv-Escape $propId) + ";" +
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
          }

          # push recursion, carry current node as parent context
          $stack.Push(@{ node = $val; path = $newPath; parent = $node })
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
}
finally {
  if ($sw) { $sw.Dispose() }
}

$sb2 = New-Object System.Text.StringBuilder
[void]$sb2.AppendLine("FIX PACK B v3 SUMMARY")
[void]$sb2.AppendLine(("timestamp=" + $Stamp))
[void]$sb2.AppendLine(("mode=" + $Mode))
[void]$sb2.AppendLine(("issues_csv=" + $IssuesCsv))
[void]$sb2.AppendLine(("target_files=" + $targetFiles.Count))
[void]$sb2.AppendLine(("max_bytes=" + $MaxBytes))
[void]$sb2.AppendLine(("parse_ok_pass1=" + $parseOk))
[void]$sb2.AppendLine(("parse_fail_pass1=" + $parseFail))
[void]$sb2.AppendLine(("decode_salvage_used_pass1=" + $decodeSalvageUsed))
[void]$sb2.AppendLine(("json_window_used_pass1=" + $jsonWindowUsed))
[void]$sb2.AppendLine(("global_int_mode_pid1=" + ($globalIntMode -as [string])))
[void]$sb2.AppendLine(("global_bool_mode_pid8=" + ($globalBoolMode -as [string])))
[void]$sb2.AppendLine(("files_scanned=" + $filesScanned))
[void]$sb2.AppendLine(("files_missing=" + $filesMissing))
[void]$sb2.AppendLine(("files_skipped_size=" + $filesSkippedSize))
[void]$sb2.AppendLine(("files_changed=" + $filesChanged))
[void]$sb2.AppendLine(("entries_changed=" + $entriesChanged))
[void]$sb2.AppendLine(("fill_from_parent=" + $fillFromParent))
[void]$sb2.AppendLine(("fill_from_file_mode=" + $fillFromFileMode))
[void]$sb2.AppendLine(("fill_from_global_mode=" + $fillFromGlobalMode))
[void]$sb2.AppendLine(("fill_unresolved=" + $fillUnresolved))
[void]$sb2.AppendLine(("set_fieldprops_empty=" + $setFieldPropsEmpty))
[void]$sb2.AppendLine(("fix_identifier=" + $fixIdentifier))
[void]$sb2.AppendLine(("coerce_scalar=" + $coerceScalar))
[void]$sb2.AppendLine(("hash_recompute=" + $hashRecompute))
[void]$sb2.AppendLine(("changes_csv=" + $ChangesCsv))
if ($Mode -eq "APPLY") { [void]$sb2.AppendLine(("backup_root=" + $BackupRoot)) }

Write-Utf8NoBomAllText -Path $SummaryTxt -Text $sb2.ToString()

Write-Host ("OK: " + $SummaryTxt)
Write-Host ("OK: " + $ChangesCsv)
if ($Mode -eq "APPLY") { Write-Host ("OK: " + $BackupRoot) }
# ============================================================