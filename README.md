# ⚡ Purwa

> **Feels like Python. Runs like C.**  
> **A self-hosting, zero-dependency systems programming language that compiles straight to native x86-64 machine code — no LLVM, no GCC, no external linker, and no CRT.**

![Platform](https://img.shields.io/badge/Platform-Windows%20PE32%2B%20%7C%20Linux%20ELF64-informational)
![Tests](https://img.shields.io/badge/Suite-121%2F121%20Passing-success)
![Self-hosting](https://img.shields.io/badge/Fixpoint-Bit--for--Bit%20Reproducible-brightgreen)
![Binary Size](https://img.shields.io/badge/Hello--world-2.048%20bytes-orange)
![Security](https://img.shields.io/badge/Security-W%5EX%20Compliant-blueviolet)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## 🌟 The Core Superpower: Why Purwa?

| 🐍 Feels like Python (Ergonomic & Fast Iteration) | ⚡ Runs like C / Rust (Native Systems Power) |
|---|---|
| **Zero-ceremony syntax** (`do ... end`, no boilerplate, no `return`) | **Native x86-64 machine code** emitted in 1 fast pass |
| **Instant In-RAM JIT execution** (`purwac run app.pw`) | **Standalone 2,048-byte executables** (PE32+ & ELF64) |
| **Interactive REPL** (`purwac -i`) and CLI eval (`purwac -e "40+2"`) | **Zero external dependencies** (no LLVM, no GCC, no CRT, no VM) |
| **Live hot-reload** (`purwac --watch app.pw`) | **Zero-GC memory control** (`alloc`/`drop` & sub-nanosecond bump arenas) |
| **High-level stdlib** (JSON, CSV, Regex/Glob, Unicode, Tensors) | **Direct hardware access** (RDTSC cycle counter, SSE2 math, threads, raw syscalls) |

---

## 📦 Download Prebuilt Releases (v37.13)

| Target Platform | Package | Size | Contents |
|---|---|---|---|
| 🪟 **Windows x86-64** | [**`purwa-v37.13-windows-x64.zip`**](https://github.com/ZFOURTYONE/purwa-dist/raw/main/releases/purwa-v37.13-windows-x64.zip) | ~195 KB | `purwac.exe`, `purwa-fmt.exe`, `purwa-lsp.exe`, `speednet.exe`, 38 stdlibs, VSIX |
| 🐧 **Linux x86-64** | [**`purwa-v37.13-linux-x64.zip`**](https://github.com/ZFOURTYONE/purwa-dist/raw/main/releases/purwa-v37.13-linux-x64.zip) | ~190 KB | `purwac-linux`, `purwa-fmt-linux`, `purwa-lsp-linux`, `speednet-linux`, 38 stdlibs, VSIX |

---

### 1. Minimal Hello World (`hello.pw`)

```purwa
main() do
    show("Hello from Purwa!\n")
end
```

### 2. Run It Like a Script, or Compile to a 2 KB Binary

#### 🪟 Windows (PowerShell / CMD)
```powershell
# 1. Run instantly in memory (Zero disk artifacts, sub-millisecond startup)
purwac run hello.pw

# 2. Or compile to a standalone native PE32+ executable (~2 KB)
purwac hello.pw -o hello.exe
.\hello.exe
```

#### 🐧 Linux (Bash / Zsh)
```bash
# 1. Make the compiler executable
chmod +x purwac-linux

# 2. Run instantly in memory via JIT
./purwac-linux run hello.pw

# 3. Or compile to a native Linux ELF64 binary
./purwac-linux hello.pw --target linux -o hello
chmod +x hello && ./hello
```

---

## ✨ CLI Developer Toolbelt

| Command | Description |
|---|---|
| `purwac run app.pw` | **Instant In-RAM JIT** — execute straight from memory with zero disk artifacts |
| `purwac app.pw --watch` | **Live Hot-Reload** — instantly re-JIT on every file save |
| `purwac -i` | **Interactive REPL** — experiment with expressions in real time |
| `purwac -e "40+2"` | **One-Liner Evaluation** — evaluate expressions straight from your terminal |
| `purwac app.pw -o app.exe` | **Native Windows Build** — emit standalone PE32+ executable (W^X sections) |
| `purwac app.pw --target linux -o app` | **Native Linux Cross-Compile** — emit standalone ELF64 executable (SysV ABI) |
| `purwac app.pw --strict` | **Strict Mode** — enforce static type contracts and struct integrity |
| `purwac --version` | Display compiler version and SHA-256 self-hosting fixpoint |

---

## 💡 Level 1: Pythonic Simplicity & Clean Syntax

Purwa is **expression-oriented**: every block returns its last evaluated value. Clean, intuitive, and readable:

```purwa
// Simple functions without ceremony: name(params), do-end block, last value wins
c_to_f(c) do
    c * 9 / 5 + 32
end

struct Point { x, y }

Point.dist_sq(self, other) do
    dx = self.x - other.x
    dy = self.y - other.y
    dx * dx + dy * dy
end

main() do
    temp = 25
    show($"Temperature: {temp}C = {c_to_f(temp)}F\n")

    p1 = Point(10, 20)
    p2 = Point(13, 24)
    show_num(p1.dist_sq(p2)) // 25
    show("\n")
    0
end
```

### Pattern Matching & Control Flow
```purwa
grade_for(score: i64): string do
    if score >= 90 do
        "A"
    else if score >= 80 do
        "B"
    else do
        "C"
    end
end

main() do
    for k in 0..5 do
        status = match k do
            0 => "start"
            4 => "end"
            _ => "running"
        end
        show($"step {k}: {status}\n")
    end
    show(grade_for(85))
    show("\n")
    0
end
```

---

## ⚡ Level 2: Hardcore Systems Engineering Under the Hood

When your application demands bare-metal efficiency, Purwa gives you full low-level power with zero abstractions:

### 1. Zero-GC Memory Management & Bump Arenas
Deterministic memory release with `cleanup drop`, or sub-nanosecond allocations using custom memory arenas:
```purwa
main() do
    // 1. Deterministic stack/heap lifetime (runs automatically on exit)
    buf = alloc(4096)
    cleanup drop(buf)

    // 2. High-speed bump arena (allocations take ~3-5 CPU cycles)
    arena = create_arena(1048576)
    cleanup drop_arena(arena)

    i = 0
    while i < 1000 do
        obj = arena_alloc(arena, 64)
        set_byte(obj, 0, i % 256)
        i = i + 1
    end

    // 3. Recycle the entire 1 MB memory slab in 1 CPU instruction
    arena_reset(arena)
    0
end
```

### 2. Native Multi-Threading & Mutex Concurrency
True OS kernel threads (Win32 threads on Windows, `sys_clone` + `futex_wait` pthread model on Linux) with atomic synchronization:
```purwa
global COUNTER = 0
global MTX = 0

worker(ctx) do
    i = 0
    while i < 1000 do
        lock_mutex(MTX)
        COUNTER += 1
        unlock_mutex(MTX)
        i = i + 1
    end
    0
end

main() do
    MTX = create_mutex()
    cleanup drop_mutex(MTX)
    t1 = spawn_thread(worker, 0)
    t2 = spawn_thread(worker, 0)
    join_thread(t1)
    join_thread(t2)
    show($"counter = {COUNTER}\n") // always 2000
    0
end
```

### 3. Direct Hardware Intrinsics & SSE2 Math
Execute single-opcode CPU intrinsics directly without foreign function wrappers:
```purwa
main() do
    // High-resolution CPU cycle counter (RDTSC hardware intrinsic)
    t0 = rdtsc()

    // 1-cycle SSE2 hardware square root
    root = fsqrt(144.0)

    t1 = rdtsc()
    show($"sqrt(144) = {root}, elapsed cycles: {t1 - t0}\n")
    0
end
```

---

## 🏎️ Performance Benchmarks

Purwa delivers near-C raw execution speeds with tiny binaries and sub-second compile times:

| Benchmark | C (GCC -O2) | **Purwa** | Rust | Go | Python |
|---|---|---|---|---|---|
| **Sieve of Eratosthenes** (100k primes) | 7.80 ms | **8.29 ms** | 9.63 ms | 12.49 ms | 105 ms |
| **Takeuchi** tak(24,16,8) | 11.61 ms | **14.66 ms** | 13.70 ms | 17.87 ms | 311 ms |
| **Compiler Binary Size** | 50–90 MB | **~228 KB** | 80–120 MB | 15–25 MB | ~40 MB |
| **Hello World Binary Size** | 15–30 KB | **2,048 B** | 300–3,000 KB | 1.8–3 MB | — |
| **Self-Compile Duration** | ~3.5 s | **~0.4 s** | ~12 s | ~1.8 s | — |

*Dead-Function Elimination (DFE) automatically strips unreachable functions, keeping production binaries ultra-compact.*

---

## 📚 Standard Libraries (`lib/`)

No package managers or external dependencies needed. Just `import "<name>"`:

```text
📦 Core Data & Text     : collections (Vec/Stack/Queue), strings, unicode (UTF-8), match (glob **), time (ISO 8601), functional
💾 Storage & Formats    : kv (Bitcask engine), data (binary codec), csv, json, jsonpath
🔬 Math & Vectors       : mathf (SSE2 transcendental), ndarray (N-Dim tensors), stats, simd (128-bit vectorization)
🌐 System & Networking  : net (TCP/HTTPS client & server), ws (WebSockets), async (event loop), cli, hrtimer, console
🎨 UI & Graphics        : pui (declarative GUI), nui (Win32 native ClearType UI), minifb (pixel windows), canvas, otui (TUI), wasm
```

---

## 🛠️ Developer Ecosystem & Tooling

| Tool | Binary / Path | Capabilities |
|---|---|---|
| **Formatter** | `bin/purwa-fmt.exe` | Canonical, zero-config source formatter (`-w` for in-place) |
| **Language Server** | `bin/purwa-lsp.exe` | LSP 3.17 server with Markdown hover documentation, signatures & auto-completion |
| **VS Code Extension** | `tools/editors/vscode/` | Syntax grammar, LSP client, and complete snippet pack (`purwa-lang-37.11.0.vsix`) |
| **Internet Speed Tester** | `apps/speednet.pw` | Standalone CLI speed & latency tool built with `net` + `hrtimer` (~40 KB) |
| **Sovereign GUI Showcase** | `apps/calculator.pw` | Standalone zero-dependency GUI calculator with custom dark theme and bitmap font |

---

## 🛡️ Ironclad Quality Gates & Guarantees

Every release of Purwa passes an exhaustive automated test battery before merging:

1. **Bit-for-Bit 3-Stage Bootstrap Fixpoint**: $s_1 = s_2 = s_3$ identical SHA-256 hash.
2. **Comprehensive Regression Suite**: **121/121 tests passing** (`suite/run_suite_purwac.pw`).
3. **Negative Diagnostic Suite**: 15/15 invalid programs rejected with clear English error messages.
4. **W^X Security Compliance**: Zero RWX segments across Windows PE32+ and Linux ELF64.
5. **Zero-Byte Mojibake & Documentation Gate**: Every single code block in documentation is compile-verified.

---

## 📖 Documentation & Links

- 📜 [Language Specification (V37.13)](docs/SPEC.md) — Normative formal grammar & ABI
- 📘 [Coding Guide & Handbook](docs/GUIDE.md) — Step-by-step practical manual with full library reference
- 🚀 [Public Distribution Releases](https://github.com/ZFOURTYONE/purwa-dist) — Prebuilt standalone Windows & Linux binaries
- 🗺️ [Architecture & Ledger](docs/architecture.md) · [Roadmap](ROADMAP.md) · [Changelog](docs/changelog/README.md)

---

*Licensed under the [MIT License](LICENSE.txt). Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).*
