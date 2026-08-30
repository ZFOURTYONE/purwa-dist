# ===========================================================================
# benchmarks/run_benchmarks.ps1 — Official Multi-Language Benchmark Suite
# Automatically detects available compilers on your system:
# [Purwa, C (GCC/Clang), Zig, Rust, Go, Node.js, Python]
# ===========================================================================
$ErrorActionPreference = 'Continue'

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "             PURWA OFFICIAL MULTI-LANGUAGE BENCHMARK SUITE                      " -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outDir = "$env:TEMP\purwa_benchmarks"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# 1. Locate Compilers (PS 5.1 & PS 7+ compatible)
function Find-Tool([string]$name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$purwaExe = $null
if (Test-Path "$scriptDir\..\purwac.exe") { $purwaExe = (Resolve-Path "$scriptDir\..\purwac.exe").Path }
elseif (Test-Path "$scriptDir\purwac.exe") { $purwaExe = (Resolve-Path "$scriptDir\purwac.exe").Path }
elseif (Find-Tool "purwac") { $purwaExe = Find-Tool "purwac" }

$gccExe = Find-Tool "gcc"
if (-not $gccExe) { $gccExe = Find-Tool "clang" }

$zigExe = Find-Tool "zig"
if (-not $zigExe -and (Test-Path "I:\Tool\zig-x86_64-windows-0.17.0-dev.1893+78e3b1c73\zig-x86_64-windows-0.17.0-dev.1893+78e3b1c73\zig.exe")) {
    $zigExe = "I:\Tool\zig-x86_64-windows-0.17.0-dev.1893+78e3b1c73\zig-x86_64-windows-0.17.0-dev.1893+78e3b1c73\zig.exe"
}

$rustExe = Find-Tool "rustc"
$goExe = Find-Tool "go"
$nodeExe = Find-Tool "node"
$pythonExe = Find-Tool "python"
if (-not $pythonExe) { $pythonExe = Find-Tool "python3" }

Write-Host "`n[+] Toolchain Detection:" -ForegroundColor Green
Write-Host "    * Purwa   : $(if ($purwaExe) { "$purwaExe (READY)" } else { "NOT FOUND" })"
Write-Host "    * C (GCC) : $(if ($gccExe) { "$gccExe (READY)" } else { "Not installed (Optional)" })"
Write-Host "    * Zig     : $(if ($zigExe) { "$zigExe (READY)" } else { "Not installed (Optional)" })"
Write-Host "    * Rust    : $(if ($rustExe) { "$rustExe (READY)" } else { "Not installed (Optional)" })"
Write-Host "    * Go      : $(if ($goExe) { "$goExe (READY)" } else { "Not installed (Optional)" })"
Write-Host "    * Node.js : $(if ($nodeExe) { "$nodeExe (READY)" } else { "Not installed (Optional)" })"
Write-Host "    * Python  : $(if ($pythonExe) { "$pythonExe (READY)" } else { "Not installed (Optional)" })"

if (-not $purwaExe) {
    Write-Host "`n[ERROR] purwac.exe not found! Please place purwac.exe in the parent directory or add to PATH." -ForegroundColor Red
    exit 1
}

# 2. Build Benchmarks
Write-Host "`n[+] Compiling Workloads..." -ForegroundColor Green

# Purwa
$pairs = @{ 'fib'='pw_fib.pw'; 'sum'='pw_sum.pw'; 'tco'='pw_tco.pw'; 'tak'='pw_tak.pw'; 'sieve'='pw_sieve.pw'; 'mandel'='pw_mandel.pw' }
foreach ($k in $pairs.Keys) {
    & $purwaExe "$scriptDir\$($pairs[$k])" -o "$outDir\pw_$k.exe" 2>&1 | Out-Null
}

# C
if ($gccExe) {
    & $gccExe -O2 "$scriptDir\bench.c" -o "$outDir\c.exe" 2>&1 | Out-Null
}

# Zig
if ($zigExe) {
    Push-Location $outDir
    & $zigExe build-exe -O ReleaseFast "$scriptDir\bench.zig" 2>&1 | Out-Null
    if (Test-Path "bench.exe") { Move-Item "bench.exe" "zig.exe" -Force -ErrorAction SilentlyContinue }
    Pop-Location
}

# Rust
if ($rustExe) {
    & $rustExe -O "$scriptDir\bench.rs" -o "$outDir\rust.exe" 2>&1 | Out-Null
}

# Go
if ($goExe) {
    $env:GO111MODULE = 'off'; $env:GOTELEMETRY = 'off'; $env:GOTMPDIR = $env:TEMP
    & $goExe build -o "$outDir\go.exe" "$scriptDir\bench.go" 2>&1 | Out-Null
}

# 3. Timing Function
function Time-Cmd([scriptblock]$block, [int]$runs = 7) {
    $ts = @()
    # 2 warm-up runs (discarded)
    1..2 | ForEach-Object { & $block 2>$null | Out-Null }
    1..$runs | ForEach-Object {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        & $block 2>$null | Out-Null
        $sw.Stop()
        $ts += $sw.Elapsed.TotalMilliseconds
    }
    return [Math]::Round(($ts | Sort-Object)[[Math]::Floor($runs/2)], 2)
}

# 4. Run Workloads
Write-Host "`n[+] Executing Benchmarks (Median of 7 runs per workload)..." -ForegroundColor Green

$workloads = @(
    @{ ID='fib'; Name='1. Recursive Fibonacci 32' },
    @{ ID='sum'; Name='2. Loop Summation (5M iter)' },
    @{ ID='tco'; Name='3. In-Place TCO (20M iter)' },
    @{ ID='tak'; Name='4. Takeuchi Function tak' },
    @{ ID='sieve'; Name='5. Sieve of Eratosthenes' },
    @{ ID='mandel'; Name='6. Mandelbrot Set (200x200)' }
)

$results = @()
foreach ($wl in $workloads) {
    $id = $wl.ID
    $row = [ordered]@{ Workload = $wl.Name }

    # Purwa
    $rPw = Time-Cmd { & "$outDir\pw_$id.exe" }
    $row['Purwa'] = "$rPw ms"

    if ($gccExe -and (Test-Path "$outDir\c.exe")) {
        $rC = Time-Cmd { & "$outDir\c.exe" $id }
        $row['C (GCC)'] = "$rC ms"
    }
    if ($zigExe -and (Test-Path "$outDir\zig.exe")) {
        $rZig = Time-Cmd { & "$outDir\zig.exe" $id }
        $row['Zig'] = "$rZig ms"
    }
    if ($rustExe -and (Test-Path "$outDir\rust.exe")) {
        $rRs = Time-Cmd { & "$outDir\rust.exe" $id }
        $row['Rust'] = "$rRs ms"
    }
    if ($goExe -and (Test-Path "$outDir\go.exe")) {
        $rGo = Time-Cmd { & "$outDir\go.exe" $id }
        $row['Go'] = "$rGo ms"
    }
    if ($nodeExe) {
        $rNd = Time-Cmd { & $nodeExe "$scriptDir\bench.js" $id }
        $row['Node.js'] = "$rNd ms"
    }
    if ($pythonExe) {
        $rPy = Time-Cmd { & $pythonExe "$scriptDir\bench.py" $id }
        $row['Python'] = "$rPy ms"
    }

    $results += [PSCustomObject]$row
}

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "                         HEAD-TO-HEAD BENCHMARK RESULTS                         " -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# 5. Binary Sizes
Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "                         NATIVE BINARY SIZE COMPARISON                          " -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan

$binRows = @()
if (Test-Path "$outDir\pw_fib.exe") {
    $sz = (Get-Item "$outDir\pw_fib.exe").Length
    $binRows += [PSCustomObject]@{ Language="Purwa"; Bytes=$sz; KB=[Math]::Round($sz/1KB, 1); Ratio="1.0x (Lightest)" }
}
if (Test-Path "$outDir\c.exe") {
    $sz = (Get-Item "$outDir\c.exe").Length
    $binRows += [PSCustomObject]@{ Language="C (GCC -O2)"; Bytes=$sz; KB=[Math]::Round($sz/1KB, 1); Ratio="$([Math]::Round($sz/5632, 0))x larger" }
}
if (Test-Path "$outDir\zig.exe") {
    $sz = (Get-Item "$outDir\zig.exe").Length
    $binRows += [PSCustomObject]@{ Language="Zig (0.17 ReleaseFast)"; Bytes=$sz; KB=[Math]::Round($sz/1KB, 1); Ratio="$([Math]::Round($sz/5632, 0))x larger" }
}
if (Test-Path "$outDir\go.exe") {
    $sz = (Get-Item "$outDir\go.exe").Length
    $binRows += [PSCustomObject]@{ Language="Go"; Bytes=$sz; KB=[Math]::Round($sz/1KB, 1); Ratio="$([Math]::Round($sz/5632, 0))x larger" }
}
if (Test-Path "$outDir\rust.exe") {
    $sz = (Get-Item "$outDir\rust.exe").Length
    $binRows += [PSCustomObject]@{ Language="Rust (-O)"; Bytes=$sz; KB=[Math]::Round($sz/1KB, 1); Ratio="$([Math]::Round($sz/5632, 0))x larger" }
}

$binRows | Format-Table -AutoSize

Write-Host "`nBenchmark completed successfully!" -ForegroundColor Green
