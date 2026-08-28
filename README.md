# Purwa — Self-Hosting Systems Programming Language

**Version** v37.11 — Windows x86-64 (PE32+)

A self-hosting systems programming language that compiles straight to native
x86-64 machine code — no LLVM, no GCC, no external linker, no CRT.

https://github.com/ZFOURTYONE/purwa

## Included binaries

| File | Description |
|---|---|
| `purwac.exe` | Compiler (JIT, REPL, watch, `--target linux`) |
| `purwa-fmt.exe` | Source code formatter |
| `purwa-lsp.exe` | Language Server Protocol (LSP 3.17) server |
| `speednet.exe` | Internet speed & ping tester (CLI) |

## Quick Start

```text
echo main() do show("Hello\n") end > hello.pw
purwac hello.pw -o hello.exe
hello.exe
```

## Features

- Single-pass compiler, no dependencies, **zero** external toolchain
- Self-hosting 3-stage bootstrap fixpoint (bit-for-bit SHA256)
- Windows PE32+ and Linux ELF64 cross-target
- In-RAM JIT, `--watch` hot reload, interactive REPL
- Static type system (optional annotations, `--strict`)
- Deterministic memory: arenas, cleanup LIFO
- Native concurrency: threads, mutexes, atomic bump allocator
- Standard library: net/tcp/http/ws, async, SIMD, canvas, GUI, WASM, KV
- **W^X PE32+ sections** (v37.11): `.text` RX + `.data` RW — 0 RWX segments
- **English-first**: all error messages in English, MIT license

## Technical

| Property | Value |
|---|---|
| Compiler binary | ~228 KB (231 KB on disk) |
| Hello-world binary | 2,048 bytes |
| Self-compile time | ~500 ms |
| Suite | 101/101 positive, 14/14 negative |
| Fixpoint SHA | `64D23AD66515D80E…` |
| License | MIT |

## Build from source

Source is available at https://github.com/ZFOURTYONE/purwa
(requires `purwac.exe` to bootstrap).