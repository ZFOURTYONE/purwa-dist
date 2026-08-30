# ⚡ Purwa

**A self-hosting systems programming language that compiles straight to native
x86-64 machine code — no LLVM, no GCC, no external linker, no CRT.**

![Version](https://img.shields.io/badge/version-v37.12-6d28d9)
![Platform](https://img.shields.io/badge/Platform-Windows%20PE32%2B-informational)
![License](https://img.shields.io/badge/License-MIT-brightgreen)
![Compiler](https://img.shields.io/badge/Compiler-%7E228%20KB-blue)
![Hello-world](https://img.shields.io/badge/Hello--world-2.048%20bytes-orange)
![Security](https://img.shields.io/badge/Security-W%5EX%20sections-success)

Purwa is a small, fast, and **human-centric** systems language. Its compiler is
a single zero-dependency binary that emits Windows PE32+ executables directly —
and can cross-compile to Linux ELF64 from the same command line.

This package contains everything you need: **compiler, formatter, editor
language server, and a speed-testing tool**. No installation required —
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
| `purwac.exe` | The compiler — build, cross-compile, JIT, REPL, watch mode |
| `purwa-fmt.exe` | Source code formatter |
| `purwa-lsp.exe` | Language Server Protocol (LSP 3.17) server for editor support |
| `speednet.exe` | Internet speed & ping tester (command-line) |

---

## ✨ Features

- **Zero dependencies** — no toolchain, no runtime, no linker. One binary
  does everything.
- **Self-hosting** — the compiler is written entirely in Purwa and compiles
  itself (bit-for-bit reproducible bootstrap).
- **Tiny & fast** — hello-world is ~2 KB; the compiler rebuilds itself in
  under a second.
- **Secure output (W^X)** — every generated executable uses separate
  *read-execute* (code) and *read-write* (data) sections. No section is both
  writable and executable.
- **In-RAM JIT** — run programs directly from memory with zero disk artifacts
  (`purwac run app.pw`), plus live hot-reload on save (`--watch`).
- **Cross-compile** — target Linux ELF64 from Windows (`--target linux`).
- **Human-centric** — clean `do ... end` syntax, no ceremony, no `return`
  keyword, clear English diagnostics.

---

## 🛠️ Command Line

```text
purwac app.pw -o app.exe             build a Windows executable
purwac app.pw --target linux          cross-compile to Linux ELF64
purwac app.pw --jit                   execute straight from RAM
purwac app.pw --watch                 rebuild on file change
purwac app.pw --strict                treat type mismatches as errors
purwac -i                             interactive REPL
purwac -e "40+2"                      evaluate one expression
purwac --version                      show the compiler version
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

*Purwa v37.11* · Windows x86-64 (PE32+) · [SHA256SUMS.txt](SHA256SUMS.txt)
