# ============================================================
# FIXPACK C-min v1 — FIELDPROPS_NULL -> [] (targeted)
# - Only touches files that appear in IssuesCsv with FIELDPROPS_NULL
# - Replaces any property named fieldPropertyValues that is null with []
# - Logs json_path (reconstructed) + backup on APPLY
# ============================================================

param(
  [ValidateSet("DRYRUN","APPLY")]
  [string]$Mode = "DRYRUN",
  [string]$IssuesCsv = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$BasePath = "J:\replica_lab"
$AuditDir = Join-Path $BasePath "20_outputs\audit"
$FixDir   = Join-Path $BasePath "20_outputs\fix"

$Stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$BackupRoot = Join-Path $FixDir ("backup_fixpackCmin_" + $Stamp)
$ChangesCsv = Join-Path $FixDir ("fixpackCmin_changes_" + $Stamp + ".csv")
$SummaryTxt = Join-Path $FixDir ("fixpackCmin_summary_"  + $Stamp + ".txt")

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

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

function ConvertFromJsonSafe([string]$text) {
  $cmd = Get-Command ConvertFrom-Json -ErrorAction Stop
  $hasDepth = $false
  if ($cmd -and $cmd.Parameters -and $cmd.Parameters.ContainsKey("Depth")) { $hasDepth = $true }
  if ($hasDepth) { return (ConvertFrom-Json -InputObject $text -Depth 200) }
  return (ConvertFrom-Json -InputObject $text)
}

function Fix-Node([object]$node, [string]$path, [ref]$changes, [System.IO.TextWriter]$sw, [string]$file, [string]$Mode) {
  if ($null -eq $node) { return }

  if ($node -is [System.Array]) {
    for ($i=0; $i -lt $node.Length; $i++) {
      Fix-Node -node $node[$i] -path ($path + "[" + $i + "]") -changes $changes -sw $sw -file $file -Mode $Mode
    }
    return
  }

  $ps = $node.PSObject
  if ($null -eq $ps) { return }

  foreach ($p in $ps.Properties) {
    $name = $p.Name
    $val  = $p.Value
    $pPath = $path + "." + $name

    if ($name -eq "fieldPropertyValues" -and $null -eq $val) {
      $node.$name = @()
      $changes.Value++
      $sw.WriteLine(
        (Csv-Escape $file) + ";" +
        (Csv-Escape $pPath) + ";" +
        (Csv-Escape "null") + ";" +
        (Csv-Escape "[]") + ";" +
        (Csv-Escape "set_fieldPropertyValues_empty_array") + ";" +
        (Csv-Escape $Mode)
      )
      $val = $node.$name
    }

    Fix-Node -node $val -path $pPath -changes $changes -sw $sw -file $file -Mode $Mode
  }
}

# Resolve IssuesCsv
if ([string]::IsNullOrWhiteSpace($IssuesCsv)) {
  $IssuesCsv = Get-LatestFile -Dir $AuditDir -Pattern "editor3_audit_issues_v2_*.csv"
}
if ([string]::IsNullOrWhiteSpace($IssuesCsv) -or (-not (Test-Path -LiteralPath $IssuesCsv))) {
  throw "IssuesCsv não encontrado. Informe -IssuesCsv apontando para editor3_audit_issues_v2_*.csv"
}

Ensure-Dir -Path $FixDir
if ($Mode -eq "APPLY") { Ensure-Dir -Path $BackupRoot }

$issues = @(Import-Csv -LiteralPath $IssuesCsv -Delimiter ';') |
  Where-Object { $_.issue_code -eq "FIELDPROPS_NULL" }

$files = @()
$seen = @{}
foreach ($r in $issues) {
  $f = $r.file
  if (-not [string]::IsNullOrWhiteSpace($f)) {
    if (-not $seen.ContainsKey($f)) { $seen[$f] = 1; $files += $f }
  }
}

$sw = New-StreamWriterUtf8NoBom -Path $ChangesCsv
try { $sw.WriteLine("file;json_path;old_value;new_value;action;mode") } catch { $sw.Dispose(); throw }

$filesScanned = 0
$filesChanged = 0
$entriesChanged = 0
$parseFail = 0

foreach ($file in $files) {
  $filesScanned++
  if (-not (Test-Path -LiteralPath $file)) { continue }

  $text = [System.IO.File]::ReadAllText($file, $Utf8NoBom)
  $json = $null
  try { $json = ConvertFromJsonSafe -text $text } catch { $parseFail++; continue }

  $c = 0
  Fix-Node -node $json -path "$" -changes ([ref]$c) -sw $sw -file $file -Mode $Mode

  if ($c -gt 0) {
    $entriesChanged += $c
    if ($Mode -eq "APPLY") {
      # backup
      $rel = $file.Substring($BasePath.Length).TrimStart("\")
      $bkp = Join-Path $BackupRoot $rel
      $bdir = [System.IO.Path]::GetDirectoryName($bkp)
      if ($bdir -and (-not (Test-Path -LiteralPath $bdir))) { [System.IO.Directory]::CreateDirectory($bdir) | Out-Null }
      [System.IO.File]::Copy($file, $bkp, $true)

      # write back
      $out = [System.Text.RegularExpressions.Regex]::Replace($text, "`"fieldPropertyValues`"\s*:\s*null", "`"fieldPropertyValues`":[]")
      Write-Utf8NoBomAllText -Path $file -Text $out

      $filesChanged++
    }
  }
}

$sw.Dispose()

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine(("timestamp=" + $Stamp))
[void]$sb.AppendLine(("mode=" + $Mode))
[void]$sb.AppendLine(("issues_csv=" + $IssuesCsv))
[void]$sb.AppendLine(("files_scanned=" + $filesScanned))
[void]$sb.AppendLine(("files_changed=" + $filesChanged))
[void]$sb.AppendLine(("entries_changed=" + $entriesChanged))
[void]$sb.AppendLine(("parse_fail=" + $parseFail))
[void]$sb.AppendLine(("changes_csv=" + $ChangesCsv))
if ($Mode -eq "APPLY") { [void]$sb.AppendLine(("backup_root=" + $BackupRoot)) }

Write-Utf8NoBomAllText -Path $SummaryTxt -Text $sb.ToString()

Write-Host ("OK: " + $SummaryTxt)
Write-Host ("OK: " + $ChangesCsv)
if ($Mode -eq "APPLY") { Write-Host ("OK: " + $BackupRoot) }