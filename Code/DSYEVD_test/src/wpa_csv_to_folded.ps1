param(
  [Parameter(Mandatory=$true)] [string]$Input,   # WPA导出的CSV
  [Parameter(Mandatory=$true)] [string]$Output   # 输出folded文件路径
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $Input)) { throw "CSV not found: $Input" }

# 兼容不同版本列名
$sampleCols = @(
  'Weight','Sample Count','Samples','Count',
  'Inclusive Samples','Weight (Sample)','Sampled Weight'
)
$stackCols  = @(
  'Stack','Call Stack','Stack (Function)','Stack (Display)',
  'Symbolic Stack','Stack (Full)'
)

# 读CSV
$rows = Import-Csv -Path $Input
if ($rows.Count -eq 0) { throw "CSV empty: $Input" }

# 找列
$header = $rows[0].psobject.Properties.Name
$sampleCol = $sampleCols | Where-Object { $header -contains $_ } | Select-Object -First 1
$stackCol  = $stackCols  | Where-Object { $header -contains $_ } | Select-Object -First 1
if (-not $sampleCol -or -not $stackCol) {
  throw "Cannot find sample/stack columns. Headers: $($header -join ', ')"
}

function Normalize-Stack([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return $null }
  # 常见分隔符：' | '、';'、'->'、'→'
  $parts = $s -split '\s*\|\s*|\s*;\s*|\s*->\s*|\s*→\s*'
  $parts = $parts | Where-Object { $_ -and $_.Trim().Length -gt 0 }

  # 去地址偏移等噪声：func+0x123, func [0x7fff...]
  $parts = $parts | ForEach-Object {
    $_ -replace '\s*\[0x[0-9a-fA-F]+\]','' -replace '\+0x[0-9a-fA-F]+',''
  }

  if ($parts.Count -eq 0) { return $null }
  # 注意：FlameGraph 期望“从根到叶”的顺序，WPA 多数列已是自上而下；若发现方向反了，可加：$parts = [System.Array]::Reverse($parts); $parts
  return ($parts -join ';')
}

# 聚合相同栈的样本数
$acc = @{}
foreach ($r in $rows) {
  $st = Normalize-Stack ($r.$stackCol)
  if (-not $st) { continue }

  $w = 0
  $raw = $r.$sampleCol
  if ($raw -as [double]) { $w = [double]$raw }
  elseif ($raw -as [int]) { $w = [int]$raw }
  else {
    $raw2 = ($raw -replace ',','')
    if ($raw2 -as [double]) { $w = [double]$raw2 }
  }
  if ($w -le 0) { $w = 1 }  # 兜底：最少算1

  if ($acc.ContainsKey($st)) { $acc[$st] += $w } else { $acc[$st] = $w }
}

# 写出 folded
$dir = Split-Path -Parent $Output
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

$sb = New-Object System.Text.StringBuilder
foreach ($k in $acc.Keys) {
  [void]$sb.AppendLine("$k $($acc[$k])")
}
[IO.File]::WriteAllText($Output, $sb.ToString())

Write-Host "[folded] $Output, lines=$($acc.Count)"
