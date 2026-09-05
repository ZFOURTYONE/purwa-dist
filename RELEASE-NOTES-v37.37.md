# Purwa v37.37 — Release Notes

*Script-speed development. Native-code delivery.* This is a **close-source
distribution release**: compiler binaries for three targets + bundled
libraries. No compiler source included.

Jump from the previous dist release **v37.14** → **v37.37** (Rounds 119–138).
Highlights below; the full engineering ledger lives in the open-source repo.

---

## 🆕 Triple Target — Linux ARM64 joins (the big one)

- **`purwac-arm64`** — the compiler itself, self-compiled for Linux aarch64.
- **`--target aarch64`** cross-compile: emit ELF64 ARM64 from any host.
- Backend hardened in v37.34 (BF3): 16-byte SP alignment (root-cause fix of the
  aarch64 CI Bus error), correct stack-param addressing, `imm12` sh-bit,
  arithmetic `>>` (ASR), `match` value comparison, fail-loud unsupported
  constructs, `PT_GNU_STACK`.
- Verified three ways: Unicorn (dev oracle), **vsil JIT runtime** (fast local
  oracle), and **native GitHub Actions hardware** (`ubuntu-24.04-arm`,
  self-compile fixpoint s1≡s2≡s3 ≡ shipped binary).

## 🛡️ Hardening Wave XIV (v37.32–v37.36, ledger BL-028…BL-045)

Every confirmed finding of a full-compiler deep audit is fixed or documented:

- No more **crash / hang / silent wrong code** classes on the error paths:
  capacity guards everywhere, hash-load hang fixes, deep-nesting guard,
  duplicate-constant rejection, >u64-max literal rejection, unknown `--target`
  rejection, module cap errors.
- **TCO correctness** (v37.33): nested-call tail arguments and wrong arity can
  no longer silently corrupt caller state.
- **`slice()` clamp** (v37.35): out-of-range end no longer reads past the
  buffer.
- **exec argv 512-token cap** (v37.36): overlong commands fail loud (exit 126)
  instead of corrupting the child stack.

## 🧰 CLI & DX (v37.37)

- **`-h` / `--help`** — full option screen (exit 0).
- **`-v`** — version alias (with `-V` / `--version`).
- **Unknown options fail loud** with a hint, instead of being treated as
  filenames.

## ⚙️ Also new since v37.14

- **Linux REPL + in-process JIT** (v37.20) and Linux `.so` **FFI**:
  dynamic-ELF loading with relocations, W^X page protection (v37.25/26),
  OpenSSL 3.x TLS via `lib/tls.pw`.
- **Linux threads** (`clone`), exec/process API, `lib/kv.pw` storage engine.
- Compiler self-compile ≈ **0.2 s**; throughput ~58,000 mlines/ms; suite
  **140/140** (Windows) / **140 PASS** (Linux) / 29/29 negatives.

---

## 📦 Assets

| File | What |
|---|---|
| `purwa-v37.37.zip` | Everything: 3 compiler targets + fmt + lsp + speednet + `lib/` + `apps/` + `benchmarks/` (555 KB) |
| `SHA256SUMS.txt` | SHA-256 for every shipped file |

Verify after download:

```text
Get-FileHash purwac.exe -Algorithm SHA256   # compare with SHA256SUMS.txt
```

| Compiler | Fixpoint SHA-256 (prefix) |
|---|---|
| `purwac.exe` / `purwac-win64.exe` | `D689DD3E35A58ECB…` |
| `purwac-linux` | `211AFAA91010B0A3…` |
| `purwac-arm64` | `1EC84F00229B1FED…` |
