# Purwa v38.0 — Release Notes

*Script-speed development. Native-code delivery.* This is a **close-source
distribution release**: compiler binaries for three targets + bundled
libraries. No compiler source included.

**⚠️ BREAKING — the `if` grammar was unified.** The `then` keyword is **removed**
with no back-compat. Every `if` is now a single flat `do`-chain. Programs written
against v37 that used `if c then …` must be migrated (mechanical: `then` → `do`,
drop the `end` that used to sit before `else`).

---

## 🔑 One `if` form — `then` removed (the headline)

Purwa is expression-oriented: every block yields its last expression, no `return`.
The two v37 `if` forms — `if c do … end` (statement) and `if c then …` (value) —
were redundant: both already produced an **identical AST and byte-identical
machine code** (a single `emit_if`). v38 collapses them into one shape:

```
if c do … else if c2 do … else do … end
```

- Flat `else if` chain, **one `end`** at the very end, **no `end` before `else`**.
- Works both as a **statement** and as a **value** (the taken branch's last
  expression is the result).
- **Relaxed final `else`**: a bare expression is accepted — `else <expr>` (no
  mandatory `else do … end`).
- `if c then …` now fails loud with a single clear diagnostic pointing at the new
  form (the old keyword-rejection pattern, BL-003).

**Migration proof:** compiling the migrated compiler source with the previous
v37.39 binary produced a **byte-identical** executable — the rewrite is purely
syntactic, zero semantic change. The bundled `lib/`, `plugins/`, and
`tools/pw_pack.pw` in this package are all migrated to the new form.

## 🧰 Tooling & editors

- **`purwa-fmt`** and **`purwa-lsp`** rebuilt for v38 (LSP server reports 38.0.0).
- **VS Code extension** `ext/purwa-lang-38.0.0.vsix`: `then` dropped from the
  grammar, snippets updated to the single `do`-chain form.

## 📊 Quality gates (all green)

- 3-stage self-hosting fixpoint `s1 ≡ s2 ≡ s3`, bit-for-bit
  `07FED2F5…` (343,040 B).
- Regression suite **144/144** (new `lot_v57_if_unified.pw`), mirrored 1:1 by the
  Linux parity suite (144 PASS / 0 FAIL / 0 SKIP on WSL).
- Negative diagnostics **30/30** rejected cleanly (new `neg_v38_then_removed.pw`),
  15 pinned via `// EXPECT:`.
- Differential optimizer **144/144** (normal == `--no-fast` == expected).
- ARM64 self-host under the **vsil JIT** runtime: 15/15.
- Self-compile throughput 234 ms / 52,247 mlines/ms (≥ 85% baseline, < 450 ms).

---

*Compiler fixpoint:* `07FED2F5EB2F0A21FFCE0C9F15A2A5B09A6251B0183ED158B18CB2592BC689C5`
*Linux x86-64:* `34C1C269…` · *Linux ARM64:* `571FB1A3…` · see `SHA256SUMS.txt`.
