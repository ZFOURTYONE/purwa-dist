# Purwa v39.14 — Release Notes

*Script-speed development. Native-code delivery.* This is a **close-source
distribution release**: compiler binaries for three targets + bundled
libraries. No compiler source included.

Jump from the previous dist release **v38.0** → **v39.14** (Rounds 140–158,
the entire v39.x correctness campaign). Highlights below; the full
engineering ledger lives in the open-source repo.

---

## 🔒 The "no silent wrong code" campaign (ledger BL‑046…BL‑061)

Every row below is bug‑hunted, fixed in codegen, and **regression‑locked by a
deterministic suite** (exit‑code weighted — the suite fails loudly, never
flakily):

- **Float unary minus is IEEE** (v39.12): `-7.25` folds to the exact sign‑flip,
  both backends — the old bit‑as‑integer result (-0.59375) is dead.
- **Integer division overflow never traps** (v39.13–v39.14): `INT64_MIN / -1`
  used to **kill the compiler itself** (SIGFPE while constant-folding). Now the
  folder rewrites `x / -1 → 0 - x`, `x % -1 → 0`, and BOTH backends carry
  runtime guards — x86 `idiv` guarded (v39.13), ARM64 `SDIV`/`MSUB` guarded
  (v39.14: native ARM overflow yields 0/MIN, so the contract is enforced by
  *codegen*, not borrowed from any CPU's default). Uniform everywhere:
  `INT64_MIN / -1 == INT64_MIN`, `% -1 == 0`.
- **`alloc(sz < 1)` is a contract, not a coin flip** (v39.13): all three
  backends return `0` — the old Linux/ARM64 "fake pointer outside the mapping"
  (first write = SIGSEGV) can no longer happen.
- **Float operands in `if`/`while` conditions warn** (v39.13): the bit-compare
  semantics stays (documented), but it is now *diagnosed* on both backends,
  and `--strict` escalates every warning to an error — self-hosting the
  compiler under `--strict` is clean.
- **Array element types revalidate on store** (v39.7–v39.8), **float infix
  arithmetic lowers to real SSE** (v39.8), `show()` of residual-typed values
  routes through the runtime text heuristic instead of dereferencing garbage
  (v39.6) — each closes a class of *silent wrong output*.

## ⚡ Performance and memory

- **`region do ... end` now actually reclaims** (v39.11): parse-time escape
  analysis routes non-escaping allocations to a bump arena released in O(1) —
  verified peakWS parity vs `drop()` (15.4 MB → 3.1 MB on the probe).
- **Self-compile memoized** (v39.10): the per-function global-env rebuild
  (≈177k wasted AST nodes per compile) is gone — throughput recovered and
  improved past the recorded baseline era.
- Windows console is real UTF‑8 (v39.9) — diagnostics render correctly in
  `chcp 65001` and outside.
- Fast-path recognizers (counter-TCO, loop, store) are guarded by a
  deterministic **recognizer-alive gate** — a silently dead fast path fails
  the build, on x86 and ARM64 alike.

## 🧮 Triple target — all three fixpoints 1‑iteration at v39.14

| Artifact | SHA‑256 prefix | Size |
|---|---|---|
| `purwac.exe` / `purwac-win64.exe` | `9A1EED0E…` | 382,464 B |
| `purwac-linux` | `9681F387…` | 354,816 B |
| `purwac-arm64` | `280D9FAD…` | 654,336 B |

- Win bootstrap: `s1 ≡ s2 ≡ s3` bit-for-bit; Linux and ARM64 native self-host
  cross ≡ native (ARM64 verified under vsil and on ARM hardware CI).
- Regression suite **158/158**, negative suite **30/30 clean rejects**,
  ARM64 runner **19/19**, Linux parity **158/0** under WSL, stress gate 100 %
  (zero leak), self-compile bench **265 ms / 51,415 lines-ms⁻¹** — well above
  the 85 % Iron-Law floor.
- Hello world: **2,048 B** W^X PE32+, zero dependencies.

## 🧰 Tooling in this package

- `tools/purwa-fmt.exe`, `tools/purwa-lsp.exe` (+ linux builds) and
  `tools/pw-pack.exe` — **all rebuilt with the v39.14 compiler itself**.
- `lib/` grew to **52 modules** (new since v38.0: `log`, `sort`, `test`);
  `apps/`, `plugins/`, `benchmarks/` synced to the current open-source tree.
- `ext/purwa-lang-38.0.0.vsix` — VS Code extension (unchanged layout).

## 🔐 File integrity

`SHA256SUMS.txt` ships with the release (lowercase hex, same format as
v38.0: root compilers + README/LICENSE, then `tools/` and `ext/` entries).
Verify against the four compiler entries first.

---

*Purwa v39.14 — the compiler is the test subject, the test bench, and the
product. Three targets, one contract, zero silent wrong code.*
