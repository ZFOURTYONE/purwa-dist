# ⚡ Purwa Multi-Language Benchmark Suite

This directory contains the official head-to-head performance, binary size, and compilation speed benchmark suite comparing **Purwa** against other major programming languages:
- **C (GCC / Clang)**
- **Zig (0.17)**
- **Rust (rustc)**
- **Go**
- **Node.js**
- **Python 3**

---

## 🚀 How to Run the Benchmarks

### 1. Fast One-Command Benchmark (PowerShell)
```powershell
powershell -File benchmarks/run_benchmarks.ps1
```

The runner will automatically:
1. Detect all compilers and runtimes installed on your system.
2. Compile and execute all 6 standard workloads across available languages.
3. Calculate high-resolution medians.
4. Print the comparative performance table and native binary size breakdown.

> **Zero Extra Setup Required**: If you only have Purwa installed, the runner will execute all native Purwa benchmarks instantly. If you have GCC, Zig, Rust, Go, Node.js, or Python on your system, it will automatically include them in the comparison!

---

## 📊 Workloads Tested

| # | Workload | What It Tests |
|---|:---|:---|
| **1** | **Recursive Fibonacci 32** | Deep call stacks, function frame overhead, recursion performance. |
| **2** | **Loop Summation (5M iter)** | Tight arithmetic loops, register accumulator performance. |
| **3** | **In-Place Tail Call Optimization (TCO)** | Register reuse and zero-stack tail recursion loop optimizations. |
| **4** | **Takeuchi Function `tak(24,16,8)`** | Branch-heavy recursive branching and combinatorial execution. |
| **5** | **Sieve of Eratosthenes (100K)** | Linear memory allocation, byte addressing, and prime computation. |
| **6** | **Mandelbrot Fractal Matrix (200×200)** | Fixed-point arithmetic, nested matrix loops, and inner branch prediction. |

---

## 📁 Source Files in this Directory

| File | Language | Description |
|:---|:---|:---|
| `bench.pw` | **Purwa** | Unified benchmark file in pure Purwa. |
| `pw_*.pw` | **Purwa** | Individual standalone workload sources for isolated testing. |
| `bench.c` | **C** | Standard C benchmark implementation (compiled with `-O2`). |
| `bench.zig` | **Zig** | Zig benchmark implementation (compiled with `-O ReleaseFast`). |
| `bench.rs` | **Rust** | Rust benchmark implementation (compiled with `-O`). |
| `bench.go` | **Go** | Go benchmark implementation. |
| `bench.js` | **Node.js** | JavaScript benchmark implementation for Node.js V8 engine. |
| `bench.py` | **Python** | Python 3 reference benchmark implementation. |
| `run_benchmarks.ps1` | **Runner** | Auto-detecting multi-language benchmark runner. |
| `run_benchmarks.pw` | **Runner** | 100% native Purwa runner with zero external scripting dependencies. |
