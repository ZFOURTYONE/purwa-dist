# Purwa Coding Guide

A practical guide to writing Purwa v37 programs. The normative reference is
the [Specification](SPEC.md). **Every example in this document is
compile-verified and runtime-checked against the v37.11 compiler.**

---

## Table of Contents

1. [Up and Running in 5 Minutes](#1-up-and-running-in-5-minutes)
2. [Five Golden Rules](#2-five-golden-rules)
3. [Variables & Types](#3-variables--types)
4. [Control Flow](#4-control-flow)
5. [Functions & Methods](#5-functions--methods)
6. [Structs, Enums, Arrays, Tuples](#6-structs-enums-arrays-tuples)
7. [Strings](#7-strings)
8. [Memory: alloc, arena, cleanup](#8-memory-alloc-arena-cleanup)
9. [Modules & Imports](#9-modules--imports)
10. [Threads & FFI](#10-threads--ffi)
11. [Common Pitfalls](#11-common-pitfalls)
12. [Style](#12-style)
13. [Quick Reference Card](#13-quick-reference-card)
14. [Purwa UI (PUI)](#14-purwa-ui-pui--gui-without-pixels)
15. [Minifb](#15-minifb--minimalist-pixel-window)
16. [Case Study: CHIP-8](#16-case-study-chip-8-emulator)
17. [Library Toolkit](#17-library-toolkit--write-apps-without-boilerplate)

---

## 1. Up and Running in 5 Minutes

Save as `hello.pw`:

```purwa
main() do
    show("Hello from Purwa!\n")
end
```

Compile and run:

```text
purwac hello.pw -o hello.exe
hello.exe
```

What you need to know right away:

| Thing | Meaning |
|---|---|
| `main()` is required | no arguments; a file without `main()` is a library module |
| No `return` keyword | the **last expression** of a block is its value |
| Blocks | always `do ... end`; items separated by newlines |
| Cross-compile | `purwac hello.pw --target linux -o hello` |

Fast iteration (JIT, v36.18+) — test first with zero artifacts, do the
formal compile afterwards:

| Command | Meaning |
|---|---|
| `purwac run hello.pw` | In-RAM JIT execute — no files written, real exit code |
| `purwac --watch hello.pw` | hot reload: re-JIT on every save |
| `purwac -i` | interactive In-RAM REPL (real console required) |
| `purwac -e "40+2"` | evaluate a single expression |
| `purwac --version` | print the compiler version |

Discipline (read-first doc, benchmark gate, release workflow) lives in
[`../procedure.md`](../procedure.md).

A complete program touching most of the basics:

```purwa
square(x) do x * x end

main() do
    name = "Purwa"
    show($"Hello from {name}, 2026!\n")

    total = 0
    i = 0
    while i < 10 do
        total = total + i
        i = i + 1
    end

    for k in 0..3 do
        show($"iter {k}: square {square(k)}\n")
    end

    nums = [10, 20, 30]
    show($"nums[1] = {nums[1]}\n")
    show($"total 0..9 = {total}\n")
    0
end
```

## 2. Five Golden Rules

Master these five and you avoid 90% of mistakes:

1. **One `do`, one `end`.** Every loop/if/function block opens with `do`
   and closes with `end`. No `do do`, no unclosed bodies — the v37 compiler
   rejects them with messages that state the correct shape.
2. **No `return`.** The last line of a block is its value. In `main()`,
   that value becomes the OS exit code (an empty block exits 0).
3. **String Equality is Type-Directed.** Comparing string literals or typed variables with `a == "test"` or `a == b` automatically uses `str_eq(a, b)` (content comparison).
4. **Print numbers with `show_num(n)`**, text with `show(s)`.
5. **Pair every `alloc` with `cleanup drop(...)`** immediately after
   acquisition. For many small objects, use an arena.

## 3. Variables & Types

```purwa
global TOTAL = 0              // program-wide variable
const MAX = 4096              // constant, compile-time inlined

main() do
    x = 10                    // local; type inferred
    pi: f64 = 3.14            // optional annotation, statically validated
    s: string = "text"
    buf: ptr = alloc(8)
    cleanup drop(buf)

    x += 5                    // compound assign: += -= *= /= %=
    TOTAL = x                 // writing a global directly

    show_num(x + TOTAL)
    show_num(MAX)
    0
end
```

Types: `i64` (integer), `f64` (float via SSE2), `string`/`ptr` (pointer),
`array<T>` (dynamic array), `struct Name` (record). Booleans are just `i64`
(`true`=1, `false`=0).

## 4. Control Flow

### if — pick the form by position

```purwa
grade_for(score: i64): string do
    // VALUE POSITION -> then ... else (produces a value)
    status = if score >= 75 then "pass" else "fail"

    // STATEMENT POSITION -> do ... end (v37: flat chain, ONE end at the end)
    if score >= 90 do
        show("grade A\n")
    else if score >= 80 do
        show("grade B\n")
    else do
        show("grade C\n")
    end

    // one-branch GUARD -> then without else
    if score == 100 then show("perfect!\n")

    status
end

main() do
    show(grade_for(85))
    show("\n")
    0
end
```

### Booleans — `true` / `false`, tested directly

A flag holds `true`/`false` and is tested as-is: `if ok`, `while not done`.
Never write `ok == 1`, `ok != 0`, or `ok == 0` — reserve numeric
comparisons for genuine numbers (indices, byte values, handles).

```purwa
find_it(n) do
    found = false
    i = 0
    while i < n and not found do
        if i * i == 25 then found = true else i = i + 1
    end
    found
end

main() do
    ok = true
    if ok then show("flag is true\n")
    ok = false
    if not ok do
        show("direct test beats ok == 0\n")
    end
    if find_it(10) then show("5*5 found\n") else show("missing\n")
    0
end
```

### while & for — each has exactly ONE form

```purwa
main() do
    // while cond do ... end
    i = 0
    while i < 3 do
        show_num(i)
        i = i + 1
    end

    // for var in start..end do ... end   (end exclusive)
    for k in 0..3 do
        show_num(k * k)
    end

    // break / continue apply to the innermost loop
    j = 0
    while true do
        j = j + 1
        if j == 2 do
            continue          // skip 2
        end
        if j > 5 do
            break             // stop at 6
        end
        show_num(j)
    end
    show("\n")
    0
end
```

### match — multi-way branching

```purwa
http_text(code: i64): string do
    match code do
        200 => "OK"
        404 => "Not Found"
        _   => "Other"        // wildcard for totality
    end
end

main() do
    show(http_text(404))
    show("\n")
    0
end
```

## 5. Functions & Methods

The everyday form: **no types** — the compiler infers everything, and arity
mistakes are still caught at compile time.

```purwa
// two styles, semantically identical
add(a, b) do
    a + b
end

twice(x) = x * 2

// multi-return: return a tuple, unpack with destructuring
divmod(a: i64, b: i64) do
    (a / b, a % b)
end

main() do
    (q, r) = divmod(17, 5)
    show($"17/5 = {q} remainder {r}\n")

    // functions are first-class values
    f = twice
    show_num(f(21))
    show("\n")
    0
end
```

**When to write types?** When a function becomes a **public library
contract** (`lib/`). Types are a promise to consumers — validated statically
at compile time, zero runtime cost:

```purwa
// lib/calculator.pw — public API
add(a: i64, b: i64): i64 do
    a + b
end
```

Inside your own application, let inference work.

Higher-order helpers (`apply`, `map_array`) come from the `functional`
module (see section 9).

## 6. Structs, Enums, Arrays, Tuples

```purwa
struct Point {
    x,
    y
}

// method: receiver declared EXPLICITLY (convention: self)
Point.sum(self): i64 do
    self.x + self.y
end

Point.scale(self, factor) = Point(self.x * factor, self.y * factor)

enum Color { RED, GREEN }

main() do
    p = Point(3, 4)
    show_num(p.sum())             // 7

    p2 = p.scale(10)
    show_num(p2.x)                // 30

    // enum: access Color.MEMBER or Color_MEMBER (value = index 0,1,...)
    show_num(Color.GREEN)         // 1
    show("\n")

    // array literal for small data
    nums = [10, 20, 30]
    nums[1] = 99
    show_num(nums[1])

    // large arrays: make_array + manual init
    big = make_array(1000, 0)
    big[999] = 7
    show_num(size(big))
    cleanup drop(big)
    show("\n")
    0
end
```

> Array literals are safe up to roughly ±30 elements. Beyond that use
> `make_array(n, default)`.

## 7. Strings

```purwa
main() do
    a = "Purwa"
    b = concat(a, " v37")            // join
    same = b == "Purwa v37"          // compares CONTENTS (type-directed)
    same_fn = str_eq(b, "Purwa v37") // explicit content check
    head = slice(b, 0, 5)            // "Purwa" (supports negative slice)
    clean = trim("  hi  ")
    starts = starts_with(clean, "ha")
    swapped = replace(b, "v37", "three-seven")
    n = parse_int("1234")
    t = to_text(456)

    show($"head={head} same={same} n={n}\n")
    show($"clean='{clean}' starts={starts} swapped='{swapped}' t={t}\n")

    // interpolation is the idiomatic way to build text
    show($"brief: {head} / {to_text(n + t)}\n")

    // split takes a BYTE CODE delimiter; results land in a dynamic array
    parts = split("a,b,c", 44)       // 44 = ','
    for k in 0..size(parts) do
        show($"  {k}: {parts[k]}\n")
    end

    // v36.6 additions (auto-available, no import needed)
    hit = contains(b, "v37")         // true
    at = index_of("banana", "na")    // 2
    up = to_upper(head)              // "PURWA"
    low = to_lower(up)               // "purwa"
    rev = reverse_str("abc")         // "cba"
    biggest = max2(n, t)             // 456
    g = gcd(48, 18)                  // 6
    show($"hit={hit} at={at} up={up} rev={rev} gcd={g}\n")

    // more live in opt-in modules: import "lib/strings.pw" / "lib/mathx.pw"
    // (pad_left, pad_right, repeat_str, count_substr, char_is_*; lcm,
    //  sqrt_int, is_prime, mod_pow)
    0
end
```

## 8. Memory: alloc, arena, cleanup

```purwa
process_file(path: string): i64 do
    buf = alloc(4096)
    cleanup drop(buf)                // runs automatically on return

    n = read_file(path, buf, 4096)   // path, buffer, capacity
    if n <= 0 do
        show("read failed\n")
        0
    else do
        n
    end
end

churn_many(): i64 do
    arena = create_arena(1048576)    // bump allocator
    cleanup drop_arena(arena)

    i = 0
    while i < 10000 do
        obj = arena_alloc(arena, 32) // ultra-fast sub-allocation
        set_byte(obj, 0, i % 256)
        i = i + 1
    end
    used = to_text(arena_size(arena)) // explicit conversion (safe idiom)
    show($"arena used = {used} bytes\n")
    arena_reset(arena)               // instant recycle
    0
end

main() do
    process_file("missing.txt")
    churn_many()
    0
end
```

Low level: `set_byte` / `get_byte` / `mem_copy` / `mem_set` / `size_of`;
JIT: `alloc_exec(n)` then `call_exec(fn, ...)`.

> **Automatic Number Formatting:** In Purwa v37, string interpolation
> `$"value = {x}"` automatically handles numbers, large 64-bit integers,
> and high-precision floats seamlessly. `to_text(v)` is also available
> whenever manual string conversion is desired.

## 9. Modules & Imports

```text
import "net"           // search order: net.pw -> lib/net.pw -> plugins/net.pw
```

- A file **with** `main()` is an application; a file **without** `main()`
  is a library.
- Plugins are written in pure Purwa under `plugins/<name>.pw`.
- Bundled module: `functional` provides `apply`, `map_array`, and friends.

Why this layout is deliberate: the essence of Purwa is the language and its
compiler — nothing else is required to *be* Purwa. `lib/` and `plugins/` are
bonus material: ordinary Purwa source you can read, copy, or replace, never
baked into the compiler (which stays byte-frozen at its fixpoint). Reach for
an existing library first; when your domain needs something the bundle lacks,
writing your own `plugins/<name>.pw` is the intended path, not a workaround.
The official set grows only toward what everyday users genuinely need — see
the Core Freeze Principle in the Specification (§12) and ROADMAP Milestone L1.

```purwa
import "functional"

double(x: i64): i64 do x * 2 end

main() do
    nums = [1, 2, 3, 4, 5]
    result = map_array(nums, 5, double)   // [2, 4, 6, 8, 10]
    show_num(result[4])                   // 10
    cleanup drop(result)
    show("\n")
    0
end
```

## 10. Threads & FFI

Native concurrency (Windows):

```purwa
global COUNTER = 0
global MTX = 0

worker(ctx: ptr): i64 do
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

    show($"counter = {COUNTER}\n")       // exactly 2000
    0
end
```

Dynamic FFI into Windows DLLs:

```purwa
popup(message: string, title: string): i64 do
    user32 = load_dll("user32.dll")
    code = 0
    if user32 != 0 do
        fn = get_fn(user32, "MessageBoxA")
        if fn != 0 then
            code = call_dll(fn, 0, message, title, 0)
        close_dll(user32)
    end
    code
end

main() do
    popup("Hello from Purwa!", "Purwa FFI")
    0
end
```

Other useful CLI switches: `--jit` (run from RAM), `-i` (REPL),
`--watch` (auto rebuild), `--strict` (annotations become hard errors).

## 11. Common Pitfalls

| # | Pitfall | ❌ Wrong | ✅ Right |
|---|---|---|---|
| 1 | double `do` / body without `end` | `while c do do ... end end` | `while c do ... end` |
| 2 | loop without `do` | `while c stmt end` | `while c do stmt end` |
| 3 | bare `if` | `if c show("x")` | `if c do show("x") end` or `if c then ...` |
| 4 | `match` without `do` | `match v 1 => ... end` | `match v do 1 => ... end` |
| 5 | `return` keyword | `return 5` | write `5` as the last line |
| 6 | comparing unannotated dynamic params | `if a == b` in `fn(a, b)` | annotate `fn(a: string, b: string)` or use `str_eq(a, b)` |
| 7 | printing numbers via `show` | `show(x)` (x integer) | `show_num(x)` |
| 8 | giant array literal | `[1, 2, ..., 500]` | `make_array(500, 0)` + init |
| 9 | semicolons between statements | `a = 1; b = 2` | one per line |
| 10 | memory leaks | `alloc(...)` with no release | `cleanup drop(buf)` |
| 11 | stray top-level assignment | `PI = 3.14` outside functions | `const PI = 3.14` |
| 12 | nested function definitions | function inside function | define only at top level |
| 13 | compiling a library | `purwac lib/net.pw -o net.exe` | `import "net"` from a program with `main()` |
| 14 | `if c then x = v end` (assign inside value-if, no else) | parser eats the closing `end` | `if c do x = v end` or add an `else` |
| 15 | top-level assignment to a global array literal | `G = [[..]]` outside a function | declare `global G = 0`, assign inside `init()` |
| 16 | nested `if` right before an outer `else` | `if a do ... if b do ... end else do ... end` (statement-if with else that has a nested if as its last item) | use **value-if** for the outer: `if a then do ... end else do ... end`, or wrap the nested logic in a helper function |

**Pitfall #16 detail (sharp edge v37):** `pd_items()` — the parser's item
loop inside a `do ... end` block — stops at the `else` keyword. When a
statement-if (`if c do ... else do ... end`) has a nested `if ... end` as
its **last** item, the nested `if`'s closing `end` is immediately followed
by the outer `else`, which the parser misreads as the old per-branch `end
before else` shape and rejects:

```text
// ✗ rejected: nested 'end' sits directly before outer 'else'
if json_mode == 0 do
    show("plain")
    if ok > 0 do show("stats") end
else do
    show("json")
end
```

```purwa
// ✓ accepted: VALUE-if blocks the adjacency
main() do
    json_mode = 0
    ok = 1
    if json_mode == 0 then do
        show("plain")
        if ok > 0 do show("stats") end
    end else do
        show("json")
    end
    0
end
```

The value-if form (`if c then do ... end else do ... end`) is the safe
pattern: the `then` block's own `end` sits between the nested `if` and the
`else`, so the parser never sees the ambiguous `end ... else` adjacency.
The statement-if form is fine when the else branch's items are all simple
expressions (no trailing nested block).

## 12. Style

1. **Naming**: functions/variables `snake_case`; structs/enums `PascalCase`;
   constants `SCREAMING_CASE`.
2. **Indentation**: 4 spaces per level.
3. **Build text** with interpolation `$"...{x}..."` instead of chained
   `concat`.
4. Place `cleanup` on the line right after resource acquisition.
5. **Write types only as contracts**: public library functions deserve full
   annotations; internal application code leans on inference.
6. **Booleans are `true`/`false`**: assign them directly (`ok = true`) and
   test them directly (`if ok`, `while not ok`). `== 1`/`!= 0`/`== 0` on a
   flag is a code smell — numbers are for data (indices, bytes, handles).

## 13. Quick Reference Card

| Construct | Canonical form |
|---|---|
| Function | `name(a, b) do ... end` or `name(x) = expr` |
| Return value | last line of the block; in `main()` it is the OS exit code |
| while | `while cond do ... end` |
| for | `for i in 0..n do ... end` |
| if statement | `if c do ... end` / `else if c2 do ... end` / `else do ... end` (satu `end`) |
| if value | `if c then a else b` |
| if guard | `if c then stmt` |
| boolean flag | `ok = true` / `ok = false` ; test `if ok` / `while not ok` (never `ok == 1`) |
| match | `match v do pattern => e _ => e end` |
| multi-return | `(a, b) = f()` ; function returns `(x, y)` |
| method | `Type.method(self, ...) do ... end` , call `obj.method()` |
| enum | `enum Name { A, B }` ; access `Name.A` |
| small array | `[1, 2, 3]` |
| large array | `make_array(n, 0)` + indexing |
| strings | `concat` `str_eq` `slice` `trim` `split` `$"..."` |
| memory | `alloc`/`drop`, arena `create_arena`/`arena_alloc` |
| cleanup | `cleanup drop(buf)` |
| threads | `spawn_thread`/`join_thread` + mutex (Windows) |
| process | `exec`/`spawn`/`exec2`/`spawn2`/`spawn_async`/`wait_process` (Windows & Linux, v37.9) |
| FFI | `load_dll` `get_fn` `call_dll` (Windows) |
| GUI (PUI) | `import "pui"` then `column/row/card/button/text/title/page` |

---

## 14. Purwa UI (PUI) — GUI without pixels

Build desktop applications declaratively: compose widgets, and PUI handles
layout, drawing, and click-to-action mapping. Recommended project structure:

```
apps/my_app/
  APP.pw        entrypoint: pui_start(...)
  MAIN_UI.pw    screen composition (built-in widgets)
  widgets.pw    custom application widgets
```

```purwa
import "pui"

build(n) do
    page([
        title("Counter"),
        text("value: " + to_text(n)),
        row([button("+", 1), button("-", 2)])
    ])
end

on_action(n, id) do
    if id == 1 do
        n + 1
    else if id == 2 do
        n - 1
    else do
        n
    end
end

main() do
    pui_start("My App", 420, 560, 0, build, on_action)
end
```

`pui_start` runs the normal GUI; with `--selftest` it renders offscreen and
validates the render (background, text color, layout fit) — exit code 0 means
pass. All pixel detail stays in the framework; the application file is pure
declaration.

### Two backends, one widget tree API

| Backend | Import | Rendering | When to use |
|---|---|---|---|
| PUI | `import "pui"` | self-drawn on canvas (bitmap font) | full pixel control, custom dark theme |
| NUI | `import "nui"` | native Win32 controls — ClearType text | sharp native look, identical application code |

The widget tree (`text title button column row card page spacer`) is identical;
switching backends only requires changing the import and `pui_start` to
`nui_start`. NUI creates real HWND per widget, uses Segoe UI ClearType font,
detects clicks via polling (no custom wndproc), and rebuilds controls on state
change. NUI defaults to **dark mode** (NU_DARK = 1): DWM dark title bar,
DarkMode_Explorer theme, and a self-assembled x64 WndProc via alloc_exec —
intercepting WM_CTLCOLORSTATIC/COLOREDIT/COLORBTN (light text, slate-900
background brush) and WM_ERASEBKGND (rejected; background filled during
rebuild), routing everything else to the original proc. ABI lesson: at WndProc
entry RSP = 8 (mod 16) so any path calling GDI must push rbp first. Limit:
custom widget colors are ignored by the native backend.

Available widgets: `text title small_text button column row box card page
spacer align color height_min width_min`. Modern dark theme is active by
default; adjust via `PUI_T` table if needed.

## 15. Minifb — Minimalist Pixel Window

For generative demos (plasma, starfield, visualizer) where widgets are
irrelevant: `import "minifb"` provides a classic three-function API over the
sovereign stack (canvas + gui):

    m = mfb_open("title", width, height)
    while running:
        ... fill pixels via canvas_set_pixel / set_byte ...
        mfb_update(m)
        if mfb_should_close(m) -> exit
    mfb_close(m)

Pixels are B,G,R,X per byte; m.c.buffer is the raw pointer for fast paths.
Esc or X button closes cleanly. A full animated example lives at
`apps/demo_minifb` — integer plasma (triangle wave, no floats), complete with
an offscreen `--selftest` that validates motion and gradient richness.

## 16. Case Study: CHIP-8 Emulator

Can Purwa build an emulator? Yes — `apps/demo_chip8` proves it: a complete
CHIP-8 CPU core (all standard opcode groups, 60Hz timers, XOR display with
VF collision), written entirely in Purwa, displayed via `lib/minifb` with
6x integer scaling.

Architecture pattern for any emulator:
  - core engine separate from display (`chip8_core.pw` without I/O)
  - global arrays for memory/registers; bitwise `&`, `|`, `^`, `<<`, `>>` available
  - host-to-machine input mapping via `CH_KEYS` array each frame
  - throttle: ~25 instructions per frame @60fps via `time_ms`
  - headless selftest: peak lit pixels, VRAM hash changes (motion), bounce
    position, zero unknown opcodes

Expensive lesson: assertions must not take a snapshot at a fixed point — right
after CLS the screen is legitimately empty for a moment; measure the peak.

### Loading ROMs from disk (v36.14)

`lib/fileio.pw` provides binary file reading via pure kernel32 FFI —
CreateFileA/GetFileSize/ReadFile/CloseHandle — without touching the compiler
(fixpoint preserved). `demo_chip8` receives it:

    purwac apps\demo_chip8\APP.pw -o demo_chip8.exe
    demo_chip8.exe "C:\rom\Maze [David Winter].ch8"   -> GUI
    demo_chip8.exe -check "C:\rom\X.ch8"              -> headless

ROMs are not bundled in the repo (mixed license); download from
kripod/chip8-roms. Verified results: Maze 64px lit / 0 unknown;
Logo 105px; Stars fully rendered (12,848px); Zero Demo animated
(3,252 pixels shifted between captures).

Architecture lesson from this session: the `[]` index operator in Purwa
has array runtime semantics — do NOT use it for raw buffers from
alloc/FFI; read via `get_byte`/`set_byte`. Symptoms are hard to predict
(selective data corruption) so test with isolation probes:
capture source bytes, capture loaded result, compare.

## 17. Library Toolkit — write apps without boilerplate

Since v37.3, reusable helpers are extracted into standard libraries under `lib/` so applications contain only **logic** (the "human-centric" style). Just `import` and use:

### Core Data, Text & Collections

| Library | Import | Contents |
|---|---|---|
| `lib/collections.pw` | `import "collections"` | Dynamic data structures: `Vec`, `Stack`, `Queue` with push/pop/peek/len operations |
| `lib/format.pw` | `import "format"` | Formatting utilities: `format_num` (thousand separators), `join` |
| `lib/strings.pw` | `import "strings"` | Extra string helpers: `pad_left`, `pad_right`, `repeat_str`, `count_substr`, `char_is_*` |
| `lib/str_arena.pw` | `import "str_arena"` | Bump string arena: `create_string_arena`, `arena_concat`, `arena_slice`, `arena_str_repeat`, `arena_reset_strings` |
| `lib/unicode.pw` | `import "unicode"` | Unicode/UTF-8 codec: `utf8_decode_rune`, `utf8_encode_rune`, `utf8_len`, `utf8_char_at`, `utf8_slice`, `utf8_str_width` (CJK/Emoji terminal visual width) |
| `lib/match.pw` | `import "match"` | Glob matching: `glob_match` (`*`, `?`, `[a-z]`, `[!abc]`), `glob_match_icase`, recursive path globs `glob_match_path` (`**`) |
| `lib/time.pw` | `import "time"` | Date & calendar: `time_now_epoch`, `DateTime`, `time_epoch_to_datetime`, `time_format_iso`, `time_parse_iso`, leap year calculation, duration math |
| `lib/functional.pw` | `import "functional"` | First-class functional utilities: `apply`, `map_array`, `filter_array`, `fold` |

### Data Formats & Storage

| Library | Import | Contents |
|---|---|---|
| `lib/bytes.pw` | `import "bytes"` | Byte-level buffer I/O: `read_u64`, `write_u64`, `read_u32`, `write_u32`, `read_u16`, `write_u16` |
| `lib/data.pw` | `import "data"` | Tagged-value binary records: `dt_put_u32`/`i64`/`str`/`bytes`/`arr`, `dt_get_*`, `dt_begin_record`/`dt_end_record` |
| `lib/kv.pw` | `import "kv"` | Embedded Bitcask-style key-value store: `kv_open(path)`, `kv_put`, `kv_get`, `kv_del`, `kv_count`, `kv_compact`, `kv_close` |
| `lib/csv.pw` | `import "csv"` | CSV reader/writer: `csv_parse(text)`, `csv_to_str(rows)`, supports quoted fields with commas + `""` escapes |
| `lib/json.pw` | `import "json"` | JSON builder & parser: `json_object`/`json_array`/`json_field_*`, `json_get_str`/`json_get_num`/`json_has`, `\uXXXX` UTF-8 decode |
| `lib/jsonpath.pw` | `import "jsonpath"` | Nested JSON navigation: `jp_get_str`/`jp_get_num`/`jp_get_raw`/`jp_has` with dot + index paths (`"choices[0].message.content"`) |

### Math, Science & Vectors

| Library | Import | Contents |
|---|---|---|
| `lib/mathf.pw` | `import "mathf"` | SSE2 floating-point math: `math_sqrt`, `math_sin`, `math_cos`, `math_tan`, `math_atan`/`atan2`, `math_exp`, `math_log`/`log10`, `math_pow`, `math_hypot`, `math_floor`/`ceil`/`round` |
| `lib/mathx.pw` | `import "mathx"` | Extended integer math: `lcm`, `sqrt_int`, `is_prime`, `mod_pow` |
| `lib/ndarray.pw` | `import "ndarray"` | N-Dimensional array engine: `sum`/`mean`/`min`/`max`, element-wise arithmetic, matrix multiplication (`matmul`), `transpose` |
| `lib/stats.pw` | `import "stats"` | Descriptive statistics: `stats_mean`, `stats_median`, `stats_mode`, `stats_var`, `stats_std`, `stats_percentile` + deterministic LCG RNG |
| `lib/simd.pw` | `import "simd"` | 128-bit SIMD kernels: `vec4_new`/`add`/`dot`, `mat4_identity`/`mat4_mul`, `simd_array_add`/`scale`/`dot` |

### System, Networking & Hardware

| Library | Import | Contents |
|---|---|---|
| `lib/cli.pw` | `import "cli"` | CLI argument parsing: `nameeq`, `salin_token`, `parse_int`, `show_num_comma`, `show_us_as_ms`, `show_mbps` |
| `lib/hrtimer.pw` | `import "hrtimer"` | Microsecond hardware timer: `hrt_init`, `hrt_us`, `hrt_ms`, `hrt_sleep_us` (QueryPerformanceCounter / POSIX clock) |
| `lib/console.pw` | `import "console"` | Terminal engine: raw mode `con_raw_on`/`off`, `con_read_key`, `con_poll_key`, ANSI cursor/colors (`con_fg256`, `con_fg_rgb`), frame buffer capture |
| `lib/net.pw` | `import "net"` | Networking stack: TCP server & client (`net_connect`, `net_listen`), HTTPS GET/POST (`https_get`, `https_post`), streaming API |
| `lib/ws.pw` | `import "ws"` | WebSocket server: `ws_listen`, `ws_accept`, `ws_handshake`, `ws_send_text`, `ws_recv_text`, `ws_close` |
| `lib/async.pw` | `import "async"` | Asynchronous event loop: `async_create_loop`, `async_set_timeout`/`set_interval`, `async_add_fd`, `async_run`, `async_stop` |
| `lib/fileio.pw` | `import "fileio"` | Direct binary file I/O via kernel32 / POSIX FFI |
| `lib/dirlist.pw` | `import "dirlist"` | Cross-platform directory listing: `dir_list(path, buf, max)` |
| `lib/env.pw` | `import "env"` | Environment variables: `get_env`, `get_env_str`, `env_set` |
| `lib/path.pw` | `import "path"` | Cross-platform path operations: `path_join`, `path_dir`, `path_base`, `path_ext`, `path_stem`, `path_is_abs`, `path_normalize` |

### UI, Graphics & WebAssembly

| Library | Import | Contents |
|---|---|---|
| `lib/pui.pw` | `import "pui"` | Declarative widget tree GUI with software canvas rendering (dark theme) |
| `lib/nui.pw` | `import "nui"` | Declarative widget tree GUI with native Win32 controls & ClearType font |
| `lib/minifb.pw` | `import "minifb"` | Lightweight pixel window backend for animations and game loops |
| `lib/gui.pw` | `import "gui"` | Immediate-mode UI over minifb (`gui_button`, `gui_checkbox`, `gui_progress_bar`) |
| `lib/canvas.pw` | `import "canvas"` | Off-screen 32-bit RGBA rasterizer: `canvas_create`, `canvas_set_pixel`, `canvas_fill_rect`, `canvas_draw_line`/`circle`, BMP exporter |
| `lib/otui.pw` | `import "otui"` | Terminal grid UI over ANSI with diff-based repainting |
| `lib/wasm.pw` | `import "wasm"` | Standalone WebAssembly binary builder and assembler |

**Example — `apps/speednet.pw` (internet speed tester):** ~12 KB source, ~35 KB
standalone exe, using four libraries at once:

```purwa
import "net"
import "bytes"
import "hrtimer"
import "cli"

ping_one(host, port) do
    t0 = hrt_us()                  // microsecond timer (lib/hrtimer)
    fd = net_connect(host, port)   // TCP client (lib/net)
    t1 = hrt_us()
    if fd < 0 then 0 - 1
    else do
        net_close(fd)
        t1 - t0
    end
end

main() do
    hrt_init()
    net_init()
    cmd = args()
    host = alloc(256)
    salin_token(cmd, 1, host, 256)  // parse CLI (lib/cli)
    show_us_as_ms(ping_one(host, 80))  // display (lib/cli)
    0
end
```

Since v37.3, `net_connect` is available — outbound TCP connections (previously
the library only supported the server side). Its implementation uses
`getaddrinfo` (host name) and `inet_addr` (literal IP).

*Guide v37.11 — updated for the one-form grammar (v37), toolkit libraries
(v37.3), Linux Process API (H3#1, v37.9), English-first docs (v37.10),
production hardening (v37.11), keyboard input + HTTPS (Round 85), and the
human-centric boolean convention `true`/`false` tested directly (Rounds
86–88).
All examples compile-verified against purwac v37.11.*