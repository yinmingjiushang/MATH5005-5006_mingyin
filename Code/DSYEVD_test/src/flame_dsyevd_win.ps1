param(
  [Parameter(Mandatory=$true)] [string]$ExePath,                      # 你的exe
  [Parameter(Mandatory=$true)] [string]$OutDir,                       # 输出目录
  [Parameter(Mandatory=$false)] [string]$FlameGraphDir = "..\..\flamegraph\FlameGraph",
  [Parameter(Mandatory=$false)] [int]$DurationSec = 0                 # 0 = 等到进程结束
)

$ErrorActionPreference = "Stop"

# ==== 可按需修改的固定路径（若你的WPT装在别处，请改这里）====
$wprPath         = "C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\wpr.exe"
$wpaExporterPath = "C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\wpaexporter.exe"
$wpaGuiPath      = "C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\wpa.exe"

# ==== 依赖检查 ====
if (-not (Test-Path $wprPath))         { throw "wpr.exe not found: $wprPath" }
if (-not (Test-Path $wpaGuiPath))      { throw "wpa.exe not found: $wpaGuiPath（未安装 Windows Performance Analyzer GUI）" }
$haveExporter = Test-Path $wpaExporterPath

$flamegen = Join-Path $FlameGraphDir "flamegraph.pl"
if (-not (Test-Path $flamegen)) { throw "缺少 $flamegen（请确认 FlameGraph 目录）" }

$conv = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "wpa_csv_to_folded.ps1"
if (-not (Test-Path $conv)) { throw "缺少转换脚本: $conv" }

# ==== 输出路径 ====
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$etl    = Join-Path $OutDir "trace.etl"
$csv    = Join-Path $OutDir "cpu_samples.csv"
$folded = Join-Path $OutDir "stacks.folded"
$svg    = Join-Path $OutDir "flame.svg"

# ==== 单线程（先看清调用栈）====
$env:OMP_NUM_THREADS      = "1"
$env:OPENBLAS_NUM_THREADS = "1"
$env:MKL_NUM_THREADS      = "1"
$env:NUMEXPR_NUM_THREADS  = "1"

# ==== 采样（自动降级 GeneralProfile -> CPU）====
Write-Host "[wpr] start CPU sampling"
$started = $false
try {
  & $wprPath -start GeneralProfile -filemode | Out-Null
  $started = $true
} catch {
  Write-Warning "GeneralProfile 启动失败，尝试 CPU 配置……（可用管理员PS或加入 Performance Log/Monitor Users 提升权限）"
}
if (-not $started) {
  & $wprPath -cancel | Out-Null
  & $wprPath -start CPU -filemode | Out-Null
}

# ==== 运行目标程序 ====
Write-Host "[run] $ExePath"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $ExePath
$psi.UseShellExecute = $false
$proc = [System.Diagnostics.Process]::Start($psi)

if ($DurationSec -gt 0) {
  Start-Sleep -Seconds $DurationSec
  if (-not $proc.HasExited) { $proc.Kill() }
} else {
  $proc.WaitForExit()
}

# ==== 停止并保存 ETL ====
Write-Host "[wpr] stop -> $etl"
& $wprPath -stop $etl | Out-Null

# ==== 若已存在CSV（你之前手动导出过），则跳过导出 ====
$csvReady = (Test-Path $csv -PathType Leaf) -and ((Get-Item $csv).Length -gt 100)

if (-not $csvReady) {
  # ==== 方案B导出：先尝试 wpaexporter，不行就提示手动导出 ====
  if ($haveExporter) {
    Write-Host "[wpaexporter] export CPU Usage (Sampled) -> $csv"
    $wpaDir = Split-Path -Parent $wpaExporterPath
    Push-Location $wpaDir
    try {
      $args = @(
        '-i', $etl,
        '-o', $csv,
        '--profile=CPU Usage (Sampled)',  # 注意单参数
        '--symbols', 'on'
      )
      try {
        & $wpaExporterPath @args
      } catch {
        Write-Warning "wpaexporter 调用异常：$($_.Exception.Message)"
      }
    } finally {
      Pop-Location
    }
    $csvReady = (Test-Path $csv -PathType Leaf) -and ((Get-Item $csv).Length -gt 100)
  }

  if (-not $csvReady) {
    Write-Warning @"
wpaexporter 在此环境不可用或未能处理 ETL。请用 GUI 手动导出 CSV 后再继续：
  1) 打开：$wpaGuiPath
  2) 在 WPA 中打开 ETL：$etl
  3) 定位 "CPU Usage (Sampled)" 的 Table 视图
  4) 右键 "Export Table..." 保存为：$csv
完成后重新运行本脚本（或直接从“CSV->folded->SVG”这两步开始）。
"@
    # 同时帮你自动打开 WPA 指向 ETL，方便导出
    Start-Process -FilePath $wpaGuiPath -ArgumentList "`"$etl`""
    throw "需要手动导出 CSV：$csv"
  }
} else {
  Write-Host "[wpa] 检测到已存在有效CSV，跳过导出。"
}

# ==== CSV -> folded ====
Write-Host "[convert] csv -> folded"
& powershell -NoProfile -ExecutionPolicy Bypass -File $conv -Input $csv -Output $folded

if (-not (Test-Path $folded) -or (Get-Content $folded -TotalCount 2).Count -eq 0) {
  throw "折叠结果为空：$folded（请检查 CSV 列名是否被脚本正确识别）"
}

# ==== 绘制 flame.svg ====
Write-Host "[svg ] -> $svg"
& perl $flamegen $folded > $svg

Write-Host "[done] 打开 $svg"
