# 🗂️ Purwa Project Directory & File Manifest

| Path | Purpose |
| :--- | :--- |
| `procedure.md` | **MANDATORY read-first procedure**: iron laws, doc-sync matrix, P2–P6 workflows, gate battery. |
| `purwac.exe` | Production standalone native PE32+ (x86-64) Purwa compiler binary (self-hosting fixpoint, JIT In-RAM CLI). |
| `src/purwa_compiler.pw` | Master entry point & driver CLI of the Purwa modular self-hosting compiler. |
| `src/globals.pw` | Compiler global state arenas, AST node tags, token constants, and low-level memory helpers (`t32`, `t64`, `b32`, `b64`, `intern`). |
| `src/lexer.pw` | Lexer token scanner, keywords table (`kw_kind`), `float_to_bits`, `atoi`, and `lexall`. |
| `src/symtab.pw` | AST node constructor, struct definition registry, symbol hash tables (`dhash`, `ghash`), and env scopes. |
| `src/types.pw` | Pragmatic static type system, nominal struct checking, `check_type`, `infer_type`, `vhints`, and `check_call_types`. |
| `src/parser.pw` | Recursive descent parser, precedence climbing, control flow statements (`if`, `for`, `while`, `match`, `let`, `do`), and `count_lets`. |
| `src/emitter.pw` | x86-64 machine code byte emitters, register allocator peephole, constant folding, and arithmetic strength reduction. |
| `src/codegen.pw` | Codegen engine for expressions, statements, builtins, and Dead-Function Elimination (DFE). |
| `src/pe_builder.pw` | Windows PE32+ binary builder (dual W^X sections: `.text` RX + `.data` RW, IAT fixups). |
| `src/elf_builder.pw` | Linux ELF64 binary builder (dual W^X segments: RX + RW). |
| `src/jit.pw` | In-RAM JIT executor (`alloc_exec`, `call_exec`) and interactive REPL mode. |
| `src/strlib.pw` | Embedded stdlib strings & prelude (`S_STRLIB`/`S_STRLIB2`/`S_STRLIB3`), imported by `purwa_compiler.pw` via `import "strlib"`. |
| `apps/purwa_terminal.pw` | Standalone Interactive HyperShell & REPL written in pure Purwa. |
| `apps/app.pw` | Official showcase application (system dashboard demo). |
| `bin/purwa-fmt.exe` | Official source code formatter (source: `tools/purwa_fmt.pw`). |
| `bin/purwa-lsp.exe` | Language Server Protocol (LSP 3.17) server (source: `tools/purwa_lsp.pw`). |
| `bin/linux/purwac-linux` | Cross-compiled Linux ELF64 compiler binary (distribution artifact). |
| `bin/purwac-win64.exe` | Distribution copy of the Windows compiler binary. |
| `lib/` | Official modular system libraries (38) resolved via `import "<name>"`: `functional`, `str_arena`, `async`, `simd`, `wasm`, `canvas`, `gui`, **`net`** (satu titik masuk jaringan: TCP mentah + client HTTP/HTTPS via WinHTTP + stream API + builder respons server; `tcp`/`http` kini shim penerus), `ws`, **`console`** (VT/UTF-8/kursor/warna 256+truecolor/keyboard-input/frame capture, Round 85–90), `strings`, `mathx`, `collections`, `format`, `pui`, `nui`, `minifb`, **`otui`** (grid terminal UI headless-testable), `fileio`, **`kv`** (P9 embedded store), **`data`** (P9 tagged codec), **`ndarray`**, **`stats`**, **`csv`**, **`json`** (+decode `\uXXXX`, Round 90), **`jsonpath`** (navigasi path bersarang `a.b[0].c`), **`dirlist`** (listing direktori FFI), **`env`** (environment variable FFI), **`mathf`** (transcendental float: sqrt/sin/cos/tan/exp/log/pow), **`path`** (cross-platform path manipulation), **`time`** (Round 101: kalender DateTime, epoch, ISO 8601), **`match`** (Round 101: wildcard globbing `*`, `?`, `[a-z]`, `**`), **`unicode`** (Round 101: decoding UTF-8 1-4B, rune length, slicing, terminal display width). |
| `plugins/` | Community-style plugin modules (`math_utils`, `string_utils`) on the import fallback path. |
| `tools/editors/vscode/` | VS Code extension: TextMate grammar, language configuration, package manifest. |
| `examples/` | Runnable demo programs (Round 90, moved from repo root): `hello.pw` (2 KB baseline), `httptest.pw` (HTTP+HTTPS via `net`), `keytest.pw` (interactive keyboard via `console`), `loading.pw` (animated ASCII loader) + `loading.py` (Python reference original). Compile from repo root; see `examples/README.md`. |
| `suite/` | Regression test suite: **119 positive scenarios** (`lot_*.pw`, incl. `lot_v36_interp_float.pw`, `lot_kv_standalone.pw`, `lot_v37_param_assign.pw`, `lot_h4_strength.pw`, `lot_core_intrinsics.pw`, `lot_cross_platform.pw`, `lot_core_hardening.pw`, `lot_time.pw`, `lot_match.pw`, `lot_unicode.pw`, + 5 port Round 90: `lot_dirlist`, `lot_env`, `lot_jsonpath`, `lot_otui`, `lot_console2`, + `lot_syscall` Round 91, + `lot_mathf` & `lot_path` Round 94) + 15 negative tests in `suite/negative/` (incl. 4 grammar tests + 1 v37 old-form + function keyword + syscall arity) (100% PASS). `suite/linux_exec_smoke.pw` = H3#1 smoke test (spawn_async→wait_process→exec2 via fork/execve/wait4, exit 42 = lulus, CI-verified Ubuntu 24.04). `suite/linux_parity.txt` = allowlist H3#0: 105 kasus PASS yang DITEGAKKAN job linux-parity. |
| `suite/run_suite_purwac.pw` | Native standalone test suite runner in pure Purwa (canonical runner, **119 cases**). Negative suite: 15. |
| `suite/run_suite.pw` | Legacy pure-Purwa runner (81 cases, superseded). |
| `suite/run_suite.py` | Deprecated Python runner (kept for history only). |
| `apps/demo_kv/APP.pw` | P9 demo: 200-entry KV CRUD, deletes, persistence, corruption stability (`DEMO KV OK`). |
| `.github/workflows/ci.yml` | CI pipeline (2 jobs): `gates` — 3-stage bootstrap fixpoint (SHA256), regression suite, negative reject-all, binary size gate, `--strict` sanity; `linux-parity` — Linux fixpoint, negative, matriks paritas 119 kasus (105 ditegakkan via `suite/linux_parity.txt`), hello ELF, H3#1 exec smoke test (exit 42). |
| `tools/gates/` | Milestone H1/H2 verification test sources: hash-growth stress, 64-bit match, ambiguity, duplicate-field, type-checker (`--strict`) programs + v35 regression probes (`probe_concat.pw`, `probe_eq2.pw`, `probe_dfe.pw`). |
| `suite/debug_probes/` | Low-level debug probes & PE/IAT verification scripts (moved out of the suite root). |
| `tools/benchmarks/` | Cross-language benchmark suite (C, Rust, Go, Node.js, Python vs Purwa) with PowerShell and pure-Purwa runners. |
| `tools/bench_selfcompile.pw` (+ tracked `.exe`) | **Mandatory gate**: self-compile median-of-5 vs baseline (`tools/gates/bench_selfcompile.txt`), fails >120%. |
| `apps/examples/` | 12 modern progressive demos (01_hello..12_arena), inference-first, all compile+output verified. |
| `apps/calculator.pw` | Showcase GUI app: modern dark-theme calculator (380×544, Tailwind slate/sky/amber palette, own 5×7 bitmap font, fixed-point i64 arithmetic). `--selftest` = 16 gated logic tests; `--shot` = deterministic render dump. |
| `docs/SPEC.md` | V37.11 language specification — one-form grammar, types, stdlib, ABI, CLI, process API both-platforms. |
| `docs/GUIDE.md` | Practical v36+ coding guide (compile-verified examples). |
| `docs/architecture.md` | English core reference from the line-by-line audit: emitter, JIT pipeline, ABI, bug ledger BL-001…BL-011. |
| `procedure.md` | (listed above) mandatory entry document for humans & agents. |
| `tools/gates/syntax_probes/` | 13 v36 grammar accept/reject probes (13/13 matrix). |
| `tools/gates/verify_docs.ps1` | Docs verifier: every code block in SPEC/GUIDE/README must compile on v36. |
| `tools/gates/render_gate.ps1` | Calculator render gate: deterministic pixel assertions on the `--shot` canvas dump (theme anchors + E2E `7×8=56`). |
| `tools/gates/visual_gate.ps1` | Calculator live gate: launches the real GUI, asserts theme pixel signatures and click responsiveness (PostMessage-driven). |
| `tools/gates/single_click_test.ps1` | Calculator anti-double-input regression: one WM click must render exactly one glyph (font-exact pixel count). |
| `tools/gates/gui_subsystem_test.ps1` | Verifies `--gui` builds launch with zero console windows and `--selftest` output still flows through redirected stdout. |
| `tools/gates/hardening_gate.ps1` | v36.1 hardening gate: bootstrap fixpoint s1=s2=s3, 16 MB emitted stack, hello <=2048 bytes, suite/negatives, negative-safe byte-packing probe. |
| `tools/gates/bench_revalidate.ps1` | Cross-language benchmark re-validation harness (C/Rust/Go/Node/Python/Purwa medians + JSON dump); born from the TCO-record forensic audit. |
| `tools/gates/run_bench_all.ps1` | Full cross-language benchmark runner (warm-up 2 + 11 timed runs, median) for the six workloads vs C/Rust/Go/Node/Python. |
| `tools/gates/scan_mojibake.ps1` | Guard (v37.6): scans ALL live `.pw`/`.md` sources for double-encoded UTF-8 damage; exit code = damaged-file count (must be 0). |
| `tools/gates/repair_lines.ps1` | One-shot line-wise CP1252→UTF-8 undo used in the Round-64 docs repair. |
| `README.md` | Project overview, fast-start guide, and feature summary (points to `procedure.md`). |
| `ROADMAP.md` | Language roadmap and architectural milestone tracking (H1–H5 ✅, P9 ✅ v36.17). |
| `progress.md` | Comprehensive chronological development loop log (Rounds 1 → 93). |
| `benchmark.md` | Compilation speed, binary size, and execution benchmarks. |
| `benchmark_hot_reload.md` | Live hot-reload throughput benchmark report. |
| `docs/changelog/` | Version-by-version detailed release notes (V1 → V37.12). |
| `docs/legacy/` | Archived vernacular and historical compiler versions. |
| `tools/` | Formatter/LSP sources, migration scripts, low-level debug utilities, benchmark/gate tools. |
| `tools/migrate_v37_if.py` | v37 one-shot migration script: statement-if → flat `else if` chain (satu `end`); `else <expr>` → `else do <expr> end`; value-form preserved. |
| `tools/migrate_v38_bool.py` | Round 86 one-shot sweep: buang filler `else 0` (V21 membuat else opsional) dan ubah `then 1 else 0` → `then true else false`; mode report/apply, `--docs` untuk blok markdown; arsip `src/legacy/` dikecualikan. |
| `tools/migrate_v38_flags.py` | Round 87–88 one-shot sweep: flag `= 0/1` → `= false/true`, truthiness `== 1`/`!= 0`/`== 0` → langsung/`not` (5 kelas `--classes=abcde`), rantai if/else-if murni 0/1 → `true/false`; guard akhir-baris melindungi indeks (`found = 0 - 1`); `--phase2` mengaktifkan R10/R11; PRED Round 88: +16 predikat tervalidasi domain (token_eq/is_simple/find_env/gui_is_open/net_init/...); dikecualikan: `src/legacy/`, `tools/probes/`, `lot_h4_strength.pw` (counter). |
| `tools/probes/` | Round 87–88 forensik: `base_c/` baseline netral, `bisect_r10.ps1` konvergensi per kelas, `final_r10.ps1`/`final_r88.ps1` rantai fixpoint+gate, `refresh_r88.ps1` rebuild bin/dist penuh, `probe_bool87*.pw`/`probe_callcond.pw` bukti perilaku identik. |
| `tools/probes/bl8_verify.pw` | BL-008 repro: parameter reassignment no-op (exits 42 today = bug reproduced, 0 once fixed). |
| `docs/legacy/` | Archived: `docs/legacy/purwa_compiler_v18_vernacular.pw` (compiler history) + `docs/legacy/dialect/` (pre-v36 old-dialect programs, quarantined, not built). |
| `docs/changelog/version-v36.2.md` … `v36.14.md` | Release notes V36.2 → V36.14 (TCO, correctness sweeps, stdlib, PUI/NUI, minifb, CHIP-8, ROM fileio). |
| `LICENSE.txt` | MIT License (added v37.10 — internationalization). |
| `CONTRIBUTING.md` | Contribution guide: iron laws, fixpoint procedure, gate battery, coding style, license. |
| `docs/changelog/version-v37.12.md` | V37.12 release notes: Linux Parity (syscalls, threads clone+futex, mutex), Stdlib L1 (`mathf`, `path`), nominal struct type-safety (`types_ok`), fixpoint `233351BCC28F9A95…`. |
| `docs/changelog/version-v37.11.md` | V37.11 release notes: fail-fast err guard (fix hang & AV on adversarial input), `--version`/`-V` flag, W^X PE section split (`.text` RX + `.data` RW, hello 2.048 B, size gate →4096), fixpoint `64D23AD66515D80E…`. |
| `docs/changelog/version-v37.10.md` | V37.10 release notes: all compiler error messages in English, MIT license, CONTRIBUTING, PUI/NUI API rename, fixpoint `D00F949088345B32…`. |
| `docs/changelog/version-v36.15.md` | V36.15 release notes: type-directed interpolation (kills int≥65536 crash class) + struct-aware validator. |
| `docs/changelog/version-v36.16.md` | V36.16 release notes: f64 type-directed interpolation + type-aware concat + `fnum_bits`. |
| `docs/changelog/version-v36.17.md` | V36.17 release notes: P9 storage engine (`lib/kv`+`lib/data`), BL-001 arity gate, BL-003 diagnostic, suite 97. |
| `docs/changelog/version-v36.19.md` | V36.19 release notes: BL-007 FIXED — selfhost_entry global init root cause + fix. |
| `docs/changelog/version-v36.18.md` | V36.18 release notes: JIT completion (run/watch/REPL/eval, arg forwarding), self-host protocol, BL-007 open (experimental). |
| `lib/kv.pw` | v36.17: P9 embedded KV store — Bitcask-like log-append, CRC-tail recovery truncation, FNV-1a index, compaction (`kv_compact`). |
| `lib/ndarray.pw` | v37.11: N-dimensional array (sum/mean/min/max, element-wise, matmul, transpose) — human-centric Python-like API. |
| `lib/stats.pw` | v37.11: descriptive statistics (mean/median/mode/var/std/percentile) + deterministic LCG RNG. |
| `lib/csv.pw` | v37.11: CSV reader/writer with quoted fields (`csv_parse`, `csv_to_str`). |
| `lib/json.pw` | v37.11: JSON reader/writer (flat objects): `json_object`/`json_get_str`/`json_get_num`; +`\uXXXX`→UTF-8 decode (Round 90). |
| `lib/jsonpath.pw` | Round 90 (port DNA1): nested JSON navigation `jp_get_str/num/raw/has` with dot+index paths (`a.b[0].c`). |
| `lib/otui.pw` | Round 90 (port DNA1): full terminal grid UI over ANSI — `otui_init/put/put_str/present` diff-repaint, headless assertions via `otui_cell`. |
| `lib/dirlist.pw` | Round 90 (port DNA1): directory listing via FFI `FindFirstFileA` — `dir_list(path, buf, max)`. |
| `lib/data.pw` | v36.17: tagged-value codec `'I'/'S'/'A'/'R'/'E'` for KV payloads. |
| `lib/flutter.pw` | Round 102: Declarative Flutter-like reactive UI framework (Scaffold, AppBar, Column, Row, Container, Card, ListTile, Cupertino/Material widgets, Native ClearType Segoe UI, 2-pass zero-leak rendering). |
| `lib/arena.pw` | Round 102: High-performance memory arena built on native x86_64 atomic lock-free hardware bump pointer (`LOCK XADD`). |
| `lib/memory.pw` | Round 102: Global frame scratchpad and scoped memory management for UI/game frame loops. |
| `apps/demo_flutter.pw` | Round 102: Interactive Flutter-like modern GUI application with reactive state, ClearType typography, and zero-leak frame reclamation. |
| `apps/demo_memory_aware.pw` | Round 102: Systems programming demo showcasing deterministic `defer`, hardware arena, and frame scratchpads. |
| `suite/lot_v37_modernize.pw` | Round 102: Verification suite for type-directed string `==`/`!=`, negative slicing, and auto-float interpolation (exit 7401). |
| `suite/lot_v38_memory_arena.pw` | Round 102: Regression suite for `defer` deterministic cleanup, atomic arena allocation, and 10k frame stress loop (exit 0). |

