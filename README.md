# ⚡ Purwa

**Script-speed development. Native-code delivery.**  
**A self-hosting systems programming language that compiles straight to native
machine code — no LLVM, no GCC, no external linker, no CRT.**

![Version](https://img.shields.io/badge/version-v37.37-6d28d9)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20x86--64%20%7C%20Linux%20ARM64-informational)
![License](https://img.shields.io/badge/License-MIT-brightgreen)
![Compiler](https://img.shields.io/badge/Compiler-%7E330%20KB-blue)
![Security](https://img.shields.io/badge/Security-W%5EX%20sections-success)

Purwa is a small, fast, and **human-centric** systems language. Its compiler is
a single zero-dependency binary that emits Windows PE32+ executables directly —
and cross-compiles to Linux ELF64 (x86-64 **and ARM64**) from the same command
line.

This package contains everything you need: **compiler (three targets), formatter,
editor language server, and a speed-testing tool**. No installation required —
download, unzip, and run.

---

## 🚀 Quick Start

```text
# 1. Write a program
echo main() do show("Hello from Purwa!\n") end > hello.pw

# 2. Compile
purwac hello.pw -o hello.exe

# 3. Run
hello.exe
```

That's it. No runtime, no libraries, no PATH setup beyond where you put
`purwac.exe`.

---

## 📦 What's Included

| Binary | Description |
|---|---|
| `purwac.exe` / `purwac-win64.exe` | The compiler — build, cross-compile, JIT, REPL, watch mode |
| `purwac-linux` | Same compiler, Linux x86-64 ELF64 build |
| `purwac-arm64` | Same compiler, Linux ARM64 (aarch64) ELF64 build |
| `purwa-fmt.exe` | Source code formatter |
| `purwa-lsp.exe` | Language Server Protocol (LSP 3.17) server for editor support |
| `speednet.exe` / `speednet-linux` | Internet speed & ping tester (command-line) |
| `lib/` | Bundled standard libraries (35+ modules: net, json, crypto, tensor, …) |
| `apps/` | Example applications |
| `plugins/` | Optional plugin sources |
| `tools/pw_pack.pw` | Package tool source |
| `benchmarks/` | Cross-language benchmark suite (C, Rust, Go, Zig, Node, Python, Purwa) |

---

## ✨ Features

- **Zero dependencies** — no toolchain, no runtime, no linker. One binary
  does everything.
- **Self-hosting** — the compiler is written entirely in Purwa and compiles
  itself (bit-for-bit reproducible bootstrap).
- **Triple-target** — Windows PE32+, Linux x86-64 ELF64, and Linux ARM64
  (aarch64) ELF64 from the same source; all three fixpoints byte-verified.
- **Tiny & fast** — hello-world is ~1.5 KB; the compiler rebuilds itself in
  ~0.2 s.
- **Secure output (W^X)** — every generated executable uses separate
  *read-execute* (code) and *read-write* (data) segments. No segment is both
  writable and executable (incl. `PT_GNU_STACK` on ELF).
- **In-RAM JIT** — run programs directly from memory with zero disk artifacts
  (`purwac run app.pw`), plus live hot-reload on save (`--watch`).
- **Cross-compile** — `--target linux` and `--target aarch64` from Windows.
- **Human-centric** — clean `do ... end` syntax, no ceremony, no `return`
  keyword, clear English diagnostics, full `-h/--help` screen.

---

## 🛠️ Command Line

```text
purwac app.pw -o app.exe              build a Windows executable
purwac app.pw --target linux          cross-compile to Linux x86-64 ELF64
purwac app.pw --target aarch64        cross-compile to Linux ARM64 ELF64
purwac app.pw --jit                   execute straight from RAM
purwac app.pw --watch                 rebuild on file change
purwac app.pw --strict                treat type mismatches as errors
purwac -i                             interactive REPL
purwac -e "40+2"                      evaluate one expression
purwac --version                      show the compiler version
purwac -h                             full option list
```

---

## 📖 A Quick Taste

```purwa
// functions without ceremony: name(params), do-end block, last value wins
c_to_f(c) do
    c * 9 / 5 + 32
end

main() do
    show($"25C = {c_to_f(25)}F\n")
end
```

Purwa is **expression-oriented**: the last expression in a block is its value,
so there is no `return` keyword. Strings with interpolation, structs, enums,
pattern matching, first-class functions, native threads, and a built-in GUI
stack are all part of the language — no third-party packages.

---

## 🔐 File Integrity

Verify the downloaded binaries against the published checksums:

```text
# Windows (PowerShell)
Get-FileHash purwac.exe -Algorithm SHA256
# compare with the entry in SHA256SUMS.txt
```

The checksums in [SHA256SUMS.txt](SHA256SUMS.txt) are published together with
this release.

---

## 📄 License

**MIT** — free to use, modify, and redistribute. See [LICENSE.txt](LICENSE.txt).

---

*Purwa v37.37* · Windows x86-64 (PE32+) · Linux x86-64 (ELF64) · Linux ARM64 (ELF64) · [SHA256SUMS.txt](SHA256SUMS.txt)
