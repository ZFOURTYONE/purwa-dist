# Practical Purwa Developer Guide & Handbook

> **Feels like Python. Runs like C.**  
> A self-hosting, zero-dependency systems programming language that compiles straight to native x86-64 machine code.

---

## 1. Quick Start & Workflow

Purwa is distributed as a single standalone executable — `purwac.exe` on Windows and `bin/linux/purwac-linux` on Linux (run it directly, or place it on `PATH` as `purwac`). It requires no toolchain, no C compiler, no external linkers, and no virtual machines.

### 1.1 Compilation & Execution Modes

```bash
# 1. Compile to standalone native executable (PE32+ / ELF64)
purwac app.pw -o app.exe

# 2. Instant In-RAM JIT execution (Zero disk artifacts, instant run)
purwac run app.pw
purwac -r app.pw arg1 arg2

# 3. Live Hot-Reload Watcher (Recompiles and runs automatically on file save)
purwac --watch app.pw

# 4. Interactive Persistent REPL (stateful — functions/globals persist between lines)
purwac -i
purwac --repl

# 4b. Batch REPL script (automation/testing): run lines through the persistent JIT
purwac --repl-script myscript.txt

# 4c. Compiler-as-a-Service daemon (framed stdin/stdout protocol)
purwac --daemon

# 5. One-Liner Expression Evaluation
purwac -e "40 + 2"

# 6. Cross-Compilation for Linux ELF64 (from Windows with zero setup)
purwac app.pw -o app_linux --target linux
```

> **V37.16 — Compiler-as-a-Service (`--daemon`)**: a persistent JIT server over stdin/stdout with a 12-byte framed protocol (`PWDM` magic + seq + length). Commands: `PING`, `EVAL <expr>` (returns value, clean), `JIT <source>`, `COMPILE <target>\n<src>`, `STATS`, `SHUTDOWN`. State persists across requests (buffer reuse, IAT cache, W^X code pages) — warm responses in milliseconds for agent/LLM tooling. See `docs/SPEC.md` §8.

> **V37.15 — Incremental Persistent JIT (TRUE JIT)**: The interactive REPL is now **stateful**. Functions, globals, structs and constants defined in one line remain available in all subsequent lines, with only newly-defined functions recompiled (`emit_new_defs`) and full state rollback on error. Expressions are auto-wrapped and executed immediately; `:reset` clears the session. `--repl-script <file>` runs the same persistent pipeline over a text file — multi-line blocks are accumulated until `do`/`end` balance, `//` comments are skipped, and the last `main()` exit code is propagated.

---

## 2. Program Structure & Basics

Purwa programs are expression-oriented and structured using clean, block-scoped delimiters (`do ... end`). Semicolons are optional and can be used to separate multiple statements on a single line.

```purwa
// A complete Purwa application
main() do
    name = "Developer"
    show($"Welcome to Purwa, {name}!\n")
end
```

- Every executable program starts execution at `main()`.
- Global constants and variables are initialized before `main()` begins.
- Functions without `main()` act as reusable modules loaded via `import`.

---

## 3. Variables, Data Types & Pragmatic Typing

Purwa is a **statically typed, type-inferred** language. That's a fancy way of
saying two human things: *every value is one of a small set of concrete types*
(there is no "anything" blob at runtime), and *the compiler figures out which one
for you* from how you create it. In day-to-day code you almost never write a
type — you just say `count = 42` and Purwa knows it's an integer, forever. When
you *do* want to say it out loud (for clarity, for a function's contract, or to
help the compiler with a value it can't see the shape of), there's a tiny
annotation syntax. That's "pragmatic typing": inference by default, annotation on
request.

The full set of value types:

| Type | Keyword(s) | What it holds | Example literal |
|---|---|---|---|
| 64-bit signed integer | `i64` (alias `int`) | whole numbers, addresses, indices | `42`, `-7`, `999999` |
| 64-bit float (IEEE-754) | `f64` (alias `float`) | decimals, computed on SSE2 hardware | `3.14`, `0.5` |
| Boolean | `bool` | `true` / `false` (stored as a small int) | `true`, `x < y` |
| String | `str` (alias `string`) | NUL-terminated bytes — a *pointer* | `"hi"`, `$"{n}"` |
| Raw pointer | `ptr` (alias `rawptr`) | an untyped memory address | `alloc(64)` |
| Array | `array` / `array<i64>` | a fixed-capacity slot list (details in §7) | `[10, 20, 30]` |
| Struct | its own name | named fields | `Vector2D(3, 4)` |

### 3.1 Variable Declaration & Mutation

```purwa
main() do
    a = 10
    b = 20
    b = b + 5
    
    // Compound assignments
    b += 10
    b -= 5
    b *= 2
    b /= 4
    
    show_num(b)
    show("\n")
end
```

### 3.2 Type Annotations — *naming a type when you want to*

Write the type **after the name**, with a colon: `name: type = value`. It never
changes what the program *does* — the compiler would infer the same type anyway
for these examples — it's documentation you can trust, and a nudge when inference
needs help (see 3.3). The same `name: type` form works on **parameters** and,
after the closing paren, on a function's **return** type.

```purwa
// Scalar annotations (i64/int, f64/float, bool, str/string all accepted)
main() do
    count: i64 = 100000        // big number, explicitly an integer
    rate: f64 = 2.5            // a decimal
    active: bool = true        // a flag
    label: str = "ready"       // a string
    show($"{label}: {count} @ {rate} active={active}\n")
    0
end
```

```purwa
// Annotating parameters and the return value — this IS the function's contract
area(width: i64, height: i64): i64 do
    width * height
end

main() do
    show(area(6, 7))           // prints 42
    show("\n")
    0
end
```

> **Read this out loud.** `area(width: i64, height: i64): i64` tells a human
> *and* the compiler: "two integers in, one integer out." You can lean on it.

### 3.3 How Purwa Recognizes a Value's Type (and the one gray area)

The compiler tracks each variable's and expression's type *statically* — at
compile time, before your program runs. So `show()`, `+`, string interpolation,
and comparisons all pick the exact right machine path for a value because the
type was already known while building the binary. **A value whose type the
compiler can see is never guessed at runtime.** Inference has precise rules,
all settled at compile time:

- A literal tells the whole story: `999999` is an integer, `2.5` is a float,
  `"hi"` is a string. Even a huge number is safe — it's an integer, printed as a
  number.
- A variable keeps the type of the expression you created it from: `x = 5` is an
  integer, `name = read_text(p)` is a string, and a string annotated `: str` is a
  string whether or not the initializer was obvious.
- **Array elements carry their own element type** (since v39.7). When an array is
  built from a *homogeneous* source, the compiler records what its elements are,
  so `show(nums[0])` renders a number as a number and a string as a string — with
  no guessing and no runtime probe:

```purwa
main() do
    nums = [100000, 200000, 300000]   // homogeneous -> elements are i64
    show(nums[0])                      // prints 100000 (a number, correctly)
    show("\n")
    words = ["alpha", "beta"]          // homogeneous -> elements are str
    show(words[1])                     // prints beta (a string)
    0
end
```

The one gray area: a container whose element type the compiler *cannot* pin down
(an array built from a mixed literal, or read through an un-annotated helper).
For those, `show()`/`concat()` fall back to a runtime **string-or-number
heuristic**: values below 65 536 are always rendered as numbers (a tiny
integer can never be a real address), and anything larger is peeked as a
possible string. This heuristic is safe for the overwhelmingly common cases, but
a genuine large *integer* (≥ 65 536) that isn't a valid address sits in that
gray band. **The clean, honest fix is to give the compiler a type it can see:**
build arrays from homogeneous literals (so elements are typed — the `nums`/`words`
examples above), annotate a scalar `count: i64 = 100000`, or call `show_num(v)`
to force number rendering. Purwa never *silently* prints the wrong thing: either
the type is known and the output is exact, or it takes the documented heuristic.

### 3.4 Floating Point Arithmetic (SSE2)

Floating point numbers are 64-bit IEEE 754 doubles evaluated via native x86-64 SSE2 hardware instructions:

**Unary minus on floats is first-class since v39.12 (BL-058):** `-7.25` (a negated literal) is folded at parse time into the true IEEE negative, and `-x` over a *proven* `f64` (a typed `x: f64` parameter, or an inferred value like `g = fneg(...)`) compiles to the hardware `fneg` sign flip — identically on Windows, Linux, ARM64 and the JIT. Before v39.12 this silently produced garbage (integer NEG over the raw bits: `-7.25` became `-0.59375`). The general rule is unchanged: for *unproven* operands and for float **comparison** (`< > == !=`) and `%`, keep using the float builtins (`feq`/`flt`/`fgt`, `fneg`, `fadd`/`fsub`/`fmul`/`fdiv`) — the infix integer-semantics contract still applies there. Since v39.13 (BL-060) that comparison case is no longer silent even inside `if`/`while` **conditions** and on ARM64: a proven-`f64` operand in an infix comparison warns by default (same message as value context) and errors under `--strict`, on both backends — the emitted comparison keeps its integer-bit semantics, only the diagnostic fires.

```purwa
main() do
    pi = 3.14159
    radius = 5.0
    area = fmul(pi, fmul(radius, radius))
    
    show($"Radius = {radius}, Area = {area}\n")
end
```

---

## 4. Strings, Slicing & Modern Interpolation

Purwa provides full string ergonomics with both double quotes (`"..."`) and single quotes (`'...'`), along with string interpolation (`$"..."` and `$'...'`).

```purwa
main() do
    user = "Alice"
    role = 'admin'
    
    // String interpolation
    greeting = $"Hello {user}, your role is '{role}'."
    show(greeting)
    show("\n")
    
    // Core string operations
    msg = "  purwa systems programming  "
    trimmed = trim(msg)
    upper = to_upper(trimmed)
    
    show($"Original: '{trimmed}' -> Upper: '{upper}'\n")
end
```

### 4.1 String Equality (`==` / `!=`)

String equality is **value-based** — `==` and `!=` compare *contents*, not
pointers (the compiler emits `str_eq` automatically; v37.30). The operators
are the idiomatic default and the most readable form:

```purwa
main() do
    s1 = "hello"
    s2 = concat("hel", "lo")

    if s1 == s2 do
        show("Strings match by value!\n")
    end
    if s1 != s2 do
        show("Different strings!\n")
    end
end
```

Works the same for string variables, interpolation results
(`s == $"Hello {name}"`), and typed parameters alike. The explicit call
`str_eq(a, b)` is exactly equivalent and remains available — prefer the
operators for readability.

---

## 5. Control Flow

### 5.1 If-Else — One Form: the `do` Chain

Since **v38** Purwa has a **single** `if` form. The old `then` keyword was removed
(no back-compat): every `if` is now a flat `do`-chain, and because Purwa is
expression-oriented the same form works both as a *statement* and as a *value*.

**The chain** — `if c do … else if c2 do … else do … end`, with **one `end`** at
the very end and **no `end` before `else`/`else if`**:
```purwa
main() do
    score = 85

    if score >= 90 do
        show("A\n")
    else if score >= 80 do
        show("B\n")
    else if score >= 70 do
        show("C\n")
    else do
        show("F\n")
    end

    // Guard: a single branch, no else
    if score >= 0 do
        show("valid\n")
    end
    0
end
```

**As a value** — the `if` evaluates to the last expression of the branch taken,
so it composes directly in an assignment or expression:
```purwa
main() do
    score = 85

    // Inline: a branch may be a bare expression (bare `else <expr>` is allowed)
    status = if score >= 75 do "Passed" else "Failed" end
    show($"Status: {status}\n")

    // A branch may also be a multi-line block; its last item is the value
    label = if score >= 90 do
        "A (Excellent)"
    else if score >= 80 do
        "B (Good)"
    else do
        "C / F"
    end
    show($"Label: {label}\n")
    0
end
```

**Nesting** — an `if` may appear inside another `if`'s branch; each nested `if`
is a complete chain with its own single `end`:
```purwa
main() do
    a = true
    b = true

    if a do
        y = if b do 1 else 2 end   // nested value-if
        show_num(y)
        show("\n")
    end

    x = if a do
        if b do                    // nested statement-if
            show("inside\n")
        end
        42
    else do
        0
    end
    show_num(x)
    show("\n")
    0
end
```

Rule of thumb: there is only one shape to remember — **`if c do … end`**, chained
with `else if … do` and closed by a single trailing `end`. A branch is either a
block (`do … end`) or, for the final `else`, a bare expression (`else <expr>`).

### 5.2 Loops (`while` and `for`)

```purwa
main() do
    // While loop
    i = 0
    while i < 5 do
        show_num(i)
        show(" ")
        i = i + 1
    end
    show("\n")
    
    // Range-for loop
    for k in 0..5 do
        show_num(k)
        show(" ")
    end
    show("\n")
end
```

### 5.3 Pattern Matching (`match`)

```purwa
main() do
    status_code = 200
    
    message = match status_code do
        200 => "OK - Request Successful"
        400 => "Bad Request"
        404 => "Resource Not Found"
        500 => "Internal Server Error"
        _   => "Unknown Status Code"
    end
    
    show(message)
    show("\n")
end
```

---

## 6. Structs, Tuples & Multi-Value Returns

### 6.1 Structs & Methods

```purwa
struct Vector2D { x, y }

Vector2D.magnitude_sq(self) do
    self.x * self.x + self.y * self.y
end

main() do
    v = Vector2D(3, 4)
    mag_sq = v.magnitude_sq()
    show_num(mag_sq)
    show("\n")
    drop(v)
end
```

### 6.2 Tuples & Destructuring

```purwa
min_max(a: i64, b: i64) =
    if a < b do (a, b)
    else (b, a) end

main() do
    (mn, mx) = min_max(99, 42)
    show($"Min: {mn}, Max: {mx}\n")
end
```

---

## 7. Arrays & Collections

An array is a fixed-capacity list of 64-bit slots. Purwa infers an array's
**element type** from a homogeneous literal or from the fill value you hand to
`make_array`, so indexing and `show()` on `a[i]` are typed precisely (§3.3) — no
runtime guessing.

```purwa
main() do
    // Array literal (homogeneous -> elements are i64)
    nums = [10, 20, 30, 40, 50]
    show_num(nums[2]) // Prints 30
    show("\n")
    
    // Dynamic array allocation (fill value `0` -> elements are i64)
    arr = make_array(10, 0)
    arr[0] = 100
    arr[9] = 900
    show_num(arr[9])
    show("\n")
    drop(arr)
end
```

> Arrays are fixed capacity; store a string or struct in a slot and it holds that
> value's pointer. `lib/array` adds bounds-safe helpers (`arr_get`/`arr_set`) and
> `map`/`filter`/`reduce`; `lib/ndarray` and `lib/tensor` build on top for
> multi-dimensional and f64 matrix work.

---

## 8. Zero-GC Memory Management & Scoped Arenas

Purwa gives developers complete control over memory without garbage collector pauses.

### 8.1 Scoped Memory Arenas (`region do ... end`)

`region` creates an isolated 1 MB scratch arena. Buffers whose lifetime provably cannot escape the block are **routed into the arena and reclaimed in $O(1)$** when the block exits (v39.11, BL-057): a variable is arena-allocated iff every one of its occurrences is inside the region and is either `X = alloc(K)` or the first argument of a direct-memory byte builtin (`set_byte`, `mem_copy`, ...). Anything that could escape — passed to a function, `drop`ed, aliased, or returned — stays on the normal global heap, so a region can never dangle; `make_array`/string operations inside regions still allocate globally (documented residual):

```purwa
process_batch(data: i64) do
    region do
        temp_buffer = alloc(4096)
        calc = data * 2 + 10
        calc // Returned safely in RAX register
    end
end

main() do
    result = process_batch(100)
    show_num(result) // Prints 210
    show("\n")
end
```

### 8.2 Explicit Bump Arenas (`create_arena`)

```purwa
main() do
    arena = create_arena(65536) // 64 KB Arena
    
    p1 = arena_alloc(arena, 128)
    p2 = arena_alloc(arena, 256)
    
    // Reset all allocations instantly in 1 CPU instruction
    arena_reset(arena)
    
    // Free entire arena back to OS
    drop_arena(arena)
end
```

### 8.3 Defer / Cleanup Guards

```purwa
main() do
    buf = alloc(1024)
    cleanup drop(buf) // Guaranteed to execute before function exits
    
    set_byte(buf, 0, 65)
    show_num(get_byte(buf, 0))
    show("\n")
end
```

---

## 9. Human-Centric File I/O & Path Utilities

Purwa's auto-prelude provides effortless file operations without manual buffer management:

```purwa
main() do
    // Write text to file
    write_text("config.txt", "port=8080\nhost=127.0.0.1\n")
    
    // Read text from file
    if file_exists("config.txt") do
        content = read_text("config.txt")
        show(content)
    end
    
    // Cross-platform path utilities
    p = path_join("data", "logs")
    ext = path_ext("archive.tar.gz")
end
```

---

## 10. Concurrency, Threads & Mutexes

Purwa supports native cross-platform multi-threading (Win32 Threads on Windows, SysV `clone` + `futex` on Linux):

```purwa
global COUNTER = 0
global MTX = 0

worker_thread(arg) do
    for i in 0..1000 do
        lock_mutex(MTX)
        COUNTER = COUNTER + 1
        unlock_mutex(MTX)
    end
    0
end

main() do
    MTX = create_mutex()
    cleanup drop_mutex(MTX)
    
    t1 = spawn_thread(worker_thread, 0)
    t2 = spawn_thread(worker_thread, 0)
    
    join_thread(t1)
    join_thread(t2)
    
    show($"Final Counter = {COUNTER}\n")
end
```

---

## 11. Foreign Function Interface (FFI) & Linux Syscalls

### 11.1 Dynamic Windows DLL FFI

```purwa
main() do
    if not is_linux() do
        hUser = load_dll("user32.dll")
        if hUser != 0 do
            pMsgBox = get_fn(hUser, "MessageBeep")
            if pMsgBox != 0 do
                call_dll(pMsgBox, 0)
            end
            close_dll(hUser)
        end
    end
end
```

### 11.2 Direct Linux SysV Syscalls

```purwa
main() do
    if is_linux() do
        // sys_getpid = syscall 39 on Linux x86-64
        pid = syscall(39, 0, 0, 0, 0, 0, 0)
        show($"Running on Linux with PID = {pid}\n")
    end
end
```

---

## 12. Standard Library Ecosystem Overview (`lib/`)

| Category | Module | Import | Capabilities |
|---|---|---|---|
| **Core & Data** | **`arena`** | `import "arena"` | Explicit arena allocator: `create_arena`, `arena_alloc_*`, `arena_reset`, `drop_arena`. |
| | **`array`** | `import "array"` | Bounds-safe access (`arr_get`/`arr_set`), map/filter/reduce, flatten, search. |
| | **`bytes`** | `import "bytes"` | Multi-byte & endian access (`get_u16`/`u32`/`u64`, `read_u16_be`). |
| | **`collections`** | `import "collections"` | FIFO queue (`queue_new/enqueue/dequeue/len/free`). |
| | **`data`** | `import "data"` | Tagged-value codec: `dt_put_*` / `dt_get_*` — the serialization basis of `kv`. |
| | **`kv`** | `import "kv"` | Embedded Bitcask-style key-value store (CRC + crash recovery, persistent). |
| | **`memory`** | `import "memory"` | Frame allocator & global arena (`frame_alloc`, `arena_reset_all`). |
| | **`str_arena`** | `import "str_arena"` | String arena: concat/slice/repeat without separate allocations. |
| **Strings, Text & Serialization** | **`strings`** | `import "strings"` | Advanced: `pad_left`/`pad_right`, `count_substr`, `char_is_*`. |
| | **`format`** | `import "format"` | `format_num`, `join`. |
| | **`unicode`** | `import "unicode"` | UTF-8 multi-byte decoding, rune count, display width. |
| | **`csv`** | `import "csv"` | CSV parser (quoted fields). |
| | **`json`** | `import "json"` | Nested JSON scanner: dotted paths (`user.name`, `items[2].name`), multi-bracket (`arr[1][0]`), `json_get_bool/null/array_path_str`, flat-key fallback. |
| | **`jsonpath`** | `import "jsonpath"` | JSONPath queries. |
| | **`match`** | `import "match"` | Wildcard & glob matching (`*`, `?`, `[a-z]`, `**`). |
| | **`path`** | `import "path"` | Path utils — **mostly redundant** with the prelude (`path_join/base/dir/ext/stem` are built in; `import "path"` is optional). |
| **Math & Numerics** | **`mathf`** | `import "mathf"` | Transcendental: `sqrt`, `sin`, `cos`, `tan`, `exp`, `log`, `pow`. |
| | **`mathx`** | `import "mathx"` | `is_prime`, `lcm`, `mod_pow`, `sqrt_int`. |
| | **`ndarray`** | `import "ndarray"` | N-dimensional arrays (Python/NumPy-like). |
| | **`tensor`** | `import "tensor"` | f64 matrix arithmetic, transpose, activations (ReLU, Sigmoid). |
| | **`autograd`** | `import "autograd"` | Reverse-mode automatic differentiation DAG + SGD optimizer. |
| | **`stats`** | `import "stats"` | Descriptive statistics + LCG (PRNG). |
| | **`simd`** | `import "simd"` | Mat4 & SIMD array ops: `simd_array_add`, `simd_array_dot`, `mat4_mul`. |
| | **`hrtimer`** | `import "hrtimer"` | High-resolution timer (ms). |
| **Networking** | **`net`** | `import "net"` | Unified networking: raw TCP, HTTP/HTTPS client, streaming server. |
| | **`http`** | `import "http"` | **SHIM** — forwards to `net`; `import "net"` is more direct. |
| | **`tcp`** | `import "tcp"` | **SHIM** — forwards to `net`; `import "net"` is more direct. |
| | **`ws`** | `import "ws"` | WebSocket client/server. |
| | **`tls`** | `import "tls"` | TLS 1.2/1.3 cross-platform: Schannel (Win) / OpenSSL 3.x (Linux, via `dlopen`). |
| **UI & Graphics** | **`otui`** | `import "otui"` | Full terminal UI — ANSI, VT100, 256/RGB truecolor, raw keyboard. |
| | **`flutter`** | `import "flutter"` | Flutter-style UI API (widgets, layout, state). |
| | **`gui`** | `import "gui"` | Desktop GUI (window, widget, event). |
| | **`htmlview`** | `import "htmlview"` | Desktop HTML/CSS engine + canvas rasterizer (~14 KB). |
| | **`pui`** | `import "pui"` | Purwa UI toolkit. |
| | **`nui`** | `import "nui"` | Native UI (bindings). |
| | **`canvas`** | `import "canvas"` | 2D drawing: `canvas_create`, `draw_line`, `draw_circle`, ... |
| | **`minifb`** | `import "minifb"` | Minimal framebuffer (miniFB). |
| **I/O, CLI & Environment** | **`fileio`** | `import "fileio"` | Buffered file I/O: `file_read`, `file_drop`, `FileBuf`. |
| | **`dirlist`** | `import "dirlist"` | Directory listing (cross-platform). |
| | **`env`** | `import "env"` | Environment variables: `env_set`, `env_copy_value`, `env_init`. |
| | **`console`** | `import "console"` | Interactive terminal — ANSI VT100, 256/RGB truecolor, raw keyboard input. |
| | **`cli`** | `import "cli"` | CLI argument parser. |
| | **`time`** | `import "time"` | DateTime calendar, Unix epoch, ISO 8601 parsing & formatting. |
| **Security & Formats** | **`crypto`** | `import "crypto"` | SHA-256, HMAC-SHA256, MD5, Base64, Hex, CRC-32, FNV-1a, UUID v4. |
| | **`wasm`** | `import "wasm"` | WebAssembly generation. |
| | **`elf_loader`** | `import "elf_loader"` | ELF64 loader (FFI `.so` dynamic loading). |
| **Concurrency & Framework** | **`async`** | `import "async"` | Event loop: `async_create_loop`, timers, fd registration. |
| | **`functional`** | `import "functional"` | FP utils: `apply`, `apply2`, `each_array`, `map_array`, `filter_array`, `fold_array`. |
| | **`web`** | `import "web"` | Web framework: REST routing (`web_get/post/put/delete/route`), query/path params, CORS, logger, JSON/HTML responses. |
| **Developer Tooling (v37.39)** | **`test`** | `import "test"` | Mini test framework: `t_begin`/`t_end`, `t_check_*`, `t_summary`, `t_reset` — lihat §12.1. |
| | **`log`** | `import "log"` | Leveled logging: DEBUG/INFO/WARN/ERROR/OFF, console + file sink — lihat §12.2. |
| | **`sort`** | `import "sort"` | Quicksort (median-of-three + insertion), string sort, argsort, dedup, binary search — lihat §12.3. |

### 12.1 `lib/test` — Mini Test Framework (setiap fungsi)

```purwa
import "test"

main() do
    t_begin("arith")                    // mulai konteks test bernama
    t_check_eq(1 + 1, 2)                // angka: lapor expected/actual saat gagal
    t_check_ne(1, 2)                    // harus berbeda
    t_check_lt(1, 2)                    // a < b
    t_check_true(1 == 1, "label")       // asser umum berlabel
    t_check_eq_str("ab", concat("a", "b"))  // perbandingan isi string
    t_end()                             // tutup konteks: cetak [PASS]/[FAIL n]
    if t_summary() == 0 do 0 else 1 end   // 0 = semua hijau, else jumlah gagal
end
```

| Fungsi | perilaku |
|---|---|
| `t_begin(name)` | mulai konteks test; reset penghitung gagal konteks |
| `t_end()` | cetak `[PASS] name` atau `[FAIL n] name` |
| `t_check_eq(a, b)` | `a == b` (i64); gagal → cetak expected/actual |
| `t_check_ne(a, b)` | `a != b` |
| `t_check_lt(a, b)` | `a < b` |
| `t_check_true(cond, label)` | asser umum; gagal → cetak label |
| `t_check_eq_str(a, b)` | perbandingan isi string (`str_eq`) |
| `t_summary()` | cetak `test: X passed, Y failed (Z checks)`; return jumlah gagal |
| `t_reset()` | kosongkan semua counter (untuk self-test framework) |

### 12.2 `lib/log` — Logging Berlevel (setiap fungsi)

Level (global konstanta): `LOG_DEBUG=0`, `LOG_INFO=1`, `LOG_WARN=2`, `LOG_ERROR=3`, `LOG_OFF=4`.
Format baris: `[+ms] [LEVEL] [tag] pesan` — `ms` relatif sejak `log_init()` (nol dependensi).

```purwa
import "log"

main() do
    log_init()                       // mulai jam relatif log
    log_set_level(LOG_WARN)          // INFO/DEBUG tenggelam
    log_info("net", "hidden")        // tidak dicetak
    log_error("db", "refused")       // dicetak: [+ms] [ERROR] [db] refused
    log_info_num("net", "port=", 9876)   // helper angka
    log_set_file("app.log")          // sink file (append per baris, identik console)
    log_set_level(LOG_INFO)          // naikkan lagi
    0
end
```

| Fungsi | perilaku |
|---|---|
| `log_init()` | mulai jam relatif `[+ms]` |
| `log_set_level(l)` / `log_get_level()` | set / baca ambang level |
| `log_enabled(l)` | pre-check: apakah level `l` akan dicetak |
| `log_set_file(path)` | aktifkan sink file (0 = console saja) |
| `log_debug/info/warn/error(tag, msg)` | emisi per level |
| `log_info_num(tag, msg, v)` / `log_error_num(...)` | varian dengan angka (`to_text`) |

### 12.3 `lib/sort` — Sorting & Searching (setiap fungsi)

Bekerja pada array inti Purwa (`size(a)` + `a[i]`), in-place tanpa alokasi tambahan
(kecuali `argsort_asc` & `dedup_sorted` yang mengembalikan array baru).

```purwa
import "sort"

main() do
    a = [5, 3, 9, 1, 7, 3, 8]
    sort_asc(a)                      // [1,3,3,5,7,8,9]
    ix = argsort_asc(a)              // indeks terurut: a[ix[0]] terkecil
    d = dedup_sorted(a)              // [1,3,5,7,8,9] (array baru)
    i = binary_search(a, 7)          // indeks, atau -1 bila tidak ada
    s = ["pear", "apple", "mango"]
    sort_str(s)                      // urut array string (str_cmp)
    0
end
```

| Fungsi | perilaku |
|---|---|
| `sort_asc(a)` | quicksort median-of-three + insertion utk segmen <12; in-place |
| `sort_desc(a)` | menurun (asc lalu dibalik) |
| `sort_str(a)` | urut array string via `str_cmp` |
| `argsort_asc(a)` | array baru berisi INDEKS yang mengurutkan `a` |
| `dedup_sorted(a)` | buang duplikat dari array terurut (array baru) |
| `is_sorted(a)` | 1 bila naik (boleh sama) |
| `binary_search(a, x)` / `binary_search_str(a, s)` | indeks, atau `-1` |

Catatan: comparator tidak bisa jadi parameter — function value internal belum
tersedia (get_fn hanya untuk ekspor DLL). Gunakan varian fixed di atas.

### 12.4 Prelude API (77 fungsi — tersedia tanpa `import`)

Prekompile ke setiap binary via `src/strlib.pw`. Dikelompokkan:

- **Konversi & angka**: `to_string`, `to_str`, `to_text` (integer → text), `parse_int`, `abs`, `min2`, `max2`, `clamp`, `pow_int`, `gcd`, `_int_to_text`, `_float_to_text`
- **String inti**: `str_eq`, `str_cmp`/`strcmp`, `str_len`/`strlen`/`string_len`, `concat`, `slice`/`substring`, `trim`, `starts_with`, `ends_with`, `replace`, `replace_all`, `split`, `index_of`, `contains`, `to_upper`, `to_lower`, `reverse_str`, `pad_left`, `pad_right`, `repeat_str`/`str_repeat`, `str_pad_left`, `str_pad_right`, `str_count`/`count_substr`, `str_join`, `_char_at`, `_find_char`
- **Path (cross-platform)**: `path_is_sep`, `path_is_abs`, `path_join`, `path_base`, `path_dir`, `path_ext`, `path_stem`, `path_normalize`
- **Kontainer mini**: `vec_new/len/get/set/push/pop/free`, `stack_new/push/pop/peek/len/is_empty`
- **File I/O humanis**: `read_text`/`read_all_text`, `write_text`/`write_all_text`, `append_text`, `file_exists`

### 12.5 Indeks API Lengkap `lib/` (setiap fungsi publik, di-generate dari sumber)

```text
arena :: arena_alloc_raw arena_alloc_str arena_fmt_int arena_free arena_get_available arena_get_used arena_new arena_reset_all
array :: arr_contains arr_copy arr_each arr_filter arr_find arr_find_index arr_flatten arr_get arr_join arr_len arr_map arr_max arr_min arr_reduce arr_reverse arr_set arr_sum arr_to_string
async :: async_add_fd async_clear_timer async_create_loop async_destroy_loop async_remove_fd async_run async_run_once async_set_interval async_set_timeout async_stop
autograd :: sgd_new sgd_step sgd_zero_grad tensor_backward
bytes :: read_u16 read_u16_be read_u32 read_u32_be read_u64 read_u8 write_u16 write_u16_be write_u32 write_u32_be write_u64 write_u8
canvas :: canvas_clear canvas_create canvas_destroy canvas_draw_circle canvas_draw_line canvas_draw_rect canvas_fill_circle canvas_fill_rect canvas_get_pixel canvas_save_bmp canvas_set_pixel canvas_write_u16 canvas_write_u32
cli :: nameeq parse_int salin_token show_frac show_mbps show_num_comma show_us_as_ms
collections :: queue_dequeue queue_enqueue queue_free queue_len queue_new stack_len stack_new stack_peek stack_pop stack_push vec_free vec_get vec_len vec_new vec_pop vec_push vec_set
console :: con_bg256 con_bg_rgb con_bold con_clear con_cols con_dim con_erase_down con_fg con_fg256 con_fg_rgb con_goto con_hide con_home con_italic con_key_wait con_linux_esc_seq con_linux_read1 con_now_ms con_poll_key con_raw_off con_raw_on con_read_key con_reset con_restore con_rows con_setup con_show con_sleep csi dout frame_cap_off frame_cap_on sgr
crypto :: base64_decode base64_encode base64_encode_bytes crc32 crc32_bytes crypto_random_bytes crypto_random_int crypto_uuid_v4 fnv1a fnv1a_32 fnv1a_32_bytes hex_decode hex_encode hex_encode_bytes hmac_sha256 md5 md5_bytes md5_bytes_raw sha256 sha256_bytes sha256_bytes_raw
csv :: csv_cell_text csv_double_quotes csv_has_col csv_parse csv_quote csv_row_str csv_split_line csv_to_str
data :: dt_begin_record dt_end_record dt_get_arr dt_get_i64 dt_get_str dt_get_u32 dt_put_arr dt_put_bytes dt_put_i64 dt_put_str dt_put_u32
dirlist :: dir_buf_pos dir_buf_write dir_init dir_linux_list dir_linux_name dir_list dir_raw_copy dir_win_list
elf_loader :: b16 b32 b64 elf_close elf_find elf_load elf_page_prot elf_protect elf_reloc st32 st64
env :: env_copy_value env_init env_linux_find env_linux_load env_prefix_is env_set get_env get_env_str
fileio :: file_drop file_read
flutter :: AppBar Card Checkbox Column Container CupertinoButton ElevatedButton Expanded fl_draw_icon fl_free_tree fl_init_icons fl_layout fl_measure fl_render_canvas_pass fl_render_text_pass FloatingActionButton flutter_app flutter_close flutter_fmt_int flutter_render flutter_running flutter_show_snackbar flutter_slider_val Icon IconColored LinearProgressIndicator ListTile OutlinedButton Placeholder Row SafeArea Scaffold SizedBox Slider Stack Switch Text TextButton TextStyled
format :: format_num join
functional :: apply apply2 each_array filter_array fold_array map_array
gui :: gui_alloc_widget gui_app gui_badge gui_blit_canvas gui_button gui_button_custom gui_button_danger gui_button_primary gui_button_success gui_card_begin gui_checkbox gui_click_pending gui_close gui_close_window gui_draw_app_text gui_draw_text gui_flip_buffer gui_fmt_int gui_frame_begin gui_frame_end gui_is_open gui_key_esc gui_label gui_label_colored gui_mouse_down gui_mouse_x gui_mouse_y gui_open_window gui_panel gui_poll_events gui_pop_click gui_progress_bar gui_read_i32 gui_row_begin gui_row_end gui_running gui_separator gui_slider gui_spacer gui_subtitle gui_text_width gui_title gui_write_ptr
hrtimer :: hrt_init hrt_ms hrt_raw hrt_sleep_us hrt_us
htmlview :: html_add_child html_apply_css html_clean_text html_compute_layout html_create_node html_get_child html_init_system html_parse html_render html_render_node html_render_text html_run_window html_sleep_ms webui_open
json :: json_get_array_num json_get_array_path_str json_get_array_str json_get_bool json_get_null json_get_num json_get_path_num json_get_path_str json_get_str json_has json_is_null json_is_true json_locate json_has jh_hex jh_utf8 json_array json_escape json_field_bool json_field_num json_field_str json_find_array json_find_key json_find_member json_find_path json_key_at json_object json_read_num json_read_str json_skip_value json_skip_ws json_string_end
jsonpath :: jp_find_key jp_get_num jp_get_raw jp_get_str jp_has jp_is_arr_seg jp_nav jp_parse_seg jp_seg_to_int jp_skip_to_elem jp_skip_value jp_skip_ws jp_utf8_write
kv :: kv_append kv_close kv_compact kv_count kv_del kv_get kv_open kv_put kv_sync
log :: _log_emit log_debug log_enabled log_error log_error_num log_get_level log_info log_info_num log_init log_set_file log_set_level log_warn
match :: glob_match glob_match_icase glob_match_path
mathf :: math_abs math_atan math_atan2 math_ceil math_clamp math_cos math_deg2rad math_exp math_floor math_fmod math_hypot math_log math_log10 math_max math_min math_pow math_rad2deg math_round math_sin math_sqrt math_tan
mathx :: is_prime lcm mod_pow sqrt_int
memory :: frame_alloc frame_alloc_str frame_destroy frame_fmt_int frame_init frame_reset
minifb :: mfb_close mfb_open mfb_should_close mfb_update
ndarray :: nd_arange nd_array nd_copy nd_ones nd_zeros
net :: http_json http_not_found http_ok http_response_header https_close https_get https_init https_post net_accept net_cleanup net_close net_connect net_connect_host net_connect_ip net_get net_htons net_init net_listen net_post net_recv net_request net_send net_set_timeout net_socket net_stream_close net_stream_open net_stream_read tcp_accept_client tcp_bind_listener tcp_close_client tcp_close_server tcp_recv_text tcp_send_bytes tcp_send_text wh_wide
nui :: nui_apply_font nui_build_child nui_child_h nui_create_button nui_create_group nui_create_static nui_dark_install nui_emit_stub nui_init_tables nui_make_font nui_poll_click nui_rebuild nui_selftest_offscreen nui_setup nui_start nui_theme_ctl nui_utf16
otui :: otui_add otui_border otui_box otui_boxfill otui_cell otui_cell_fg otui_cell_st otui_children otui_clear otui_cols otui_dump otui_init otui_input otui_input_handle otui_input_len otui_input_val otui_layout otui_layout_box otui_measure otui_present otui_put otui_put_str otui_render otui_render_input otui_render_sgr otui_render_text otui_render_text_wrap otui_rows otui_run otui_runs otui_sgr otui_sgr_count otui_text utf8_at utf8_enc utf8_enc_at
path :: path_base path_dir path_ext path_is_abs path_is_sep path_join path_normalize path_sep path_stem
pui :: align box button card color column height_min page pui_count_color pui_draw_text pui_frame pui_glyph pui_has_flag pui_hit_add pui_hits_init pui_init_font pui_init_theme pui_isqrt pui_measure pui_node pui_place pui_round_rect pui_run pui_selftest_render pui_standard_test pui_start pui_text_width pw2 row small_text spacer text title width_min
simd :: mat4_identity mat4_mul mat4_transform_vec4 simd_array_add simd_array_dot simd_array_scale simd_array_sum simd_find_byte vec4_add vec4_distance_sq vec4_dot vec4_magnitude_sq vec4_mul vec4_new vec4_scale vec4_sub
sort :: argsort_asc binary_search binary_search_str dedup_sorted is_sorted sort_asc sort_desc sort_str
stats :: sorted_copy stats_mean stats_median stats_mode stats_percentile stats_pstd stats_pvar stats_rand stats_rand_int stats_rand_n stats_seed stats_std stats_var
str_arena :: arena_concat arena_reset_strings arena_slice arena_str_repeat create_string_arena drop_string_arena
strings :: char_is_alpha char_is_digit char_is_space count_substr pad_left pad_right repeat_str
tensor :: tensor_add tensor_div tensor_from_array tensor_get tensor_get_grad tensor_item tensor_matmul tensor_mse_loss tensor_mul tensor_new tensor_ones tensor_print tensor_randn tensor_relu tensor_scalar tensor_scale tensor_set tensor_set_grad tensor_sigmoid tensor_sub tensor_tanh tensor_transpose tensor_zero_grad tensor_zeros
test :: t_begin t_check_eq t_check_eq_str t_check_lt t_check_ne t_check_true t_end t_reset t_summary
time :: time_add_days time_add_sec time_datetime_to_epoch time_days_in_month time_diff_sec time_epoch_to_datetime time_format_date time_format_iso time_format_time time_is_leap_year time_now_ms time_pad2 time_pad4 time_parse_iso time_parse_num
tls :: https_response_json https_response_ok tls_close tls_create_client_context tls_create_server_context tls_handshake tls_init tls_recv tls_schannel_cred_in tls_schannel_cred_out tls_send tls_server_accept tls_server_create
unicode :: utf8_char_at utf8_decode_rune utf8_encode_rune utf8_len utf8_rune_at utf8_rune_width utf8_slice utf8_str_width
wasm :: wasm_add_export_func wasm_add_export_memory wasm_add_func_type wasm_add_function_body wasm_add_memory wasm_assemble wasm_create_module wasm_destroy_module wasm_write_file wb_create wb_push_bytes wb_push_i64_leb wb_push_section wb_push_string wb_push_u32_leb wb_push_u8
web :: build_http_response create_empty_context ctx_html ctx_json ctx_param ctx_query ctx_set_param ctx_status ctx_text match_route parse_http_request web_app web_delete web_get web_listen web_post web_put web_route
ws :: ws_accept ws_close ws_close_server ws_handshake ws_listen ws_recv_text ws_send_close ws_send_pong ws_send_text
```

Catatan: fungsi berawalan `_` adalah internal (jangan dipakai langsung). `http`/`tcp`
adalah shim kosong — gunakan `net`. Indeks ini di-generate dari sumber `lib/*.pw`
(Round 141); daftar paling akurat selalu bisa diregenerasi dengan grep pola definisi.

---

## 13. Application Packaging & Native Installer Generation (`purwa-pkg`)

Purwa includes a sovereign application packager and installer generator (`apps/purwa_pkg.pw` / `bin/purwa-pkg.exe`). It allows packaging any Purwa application into a standalone distribution package (`.pwpack`) or generating a self-extracting native installer executable (`<AppName>-Setup.exe`) without needing external tools like NSIS, InnoSetup, or WiX.

### 13.1 Creating a New Packaged Application
```bash
# Initialize a new project structure
purwa-pkg init my_calc

# Enter the project directory
cd my_calc

# Compile the app into a standalone binary
purwa-pkg build

# Package the app + metadata into a SHA-256 encrypted .pwpack file
purwa-pkg pack

# Generate a standalone native Setup Installer (<App>-Setup.exe)
purwa-pkg make-installer
```

---

## 14. Practical Idioms & Quick Reference Table

| Construct | Syntax Example |
|---|---|
| **Entry Point** | `main() do ... end` |
| **Variable** | `x = 42` (tipe terinferensi) · `x: i64 = 42` (anotasi eksplisit) |
| **Type vocabulary** | `i64`/`int` · `f64`/`float` · `bool` · `str`/`string` · `ptr`/`rawptr` · `array`/`array<i64>` · nama struct |
| **Function** | `add(a: i64, b: i64): i64 do a + b end` |
| **Inline Function** | `double(x) = x * 2` |
| **Method** | `Point.dist(self, o) do ... end` |
| **If-Chain** | `if c1 do a else if c2 do b else c end` |
| **Inline Value-If** | `res = if ok do 1 else 0 end` |
| **While Loop** | `while i < n do i = i + 1 end` |
| **For Range** | `for i in 0..10 do ... end` |
| **Match** | `match val do 1 => "A" _ => "B" end` |
| **Multi-Return** | `(a, b) = fn()` ; last expression `(x, y)` (no `return` keyword) |
| **Array Literal** | `arr = [1, 2, 3]` |
| **Dynamic Array** | `arr = make_array(10, 0)` |
| **Scoped Region** | `region do temp = alloc(64); 42 end` |
| **Bump Arena** | `a = create_arena(65536); p = arena_alloc(a, 64); drop_arena(a)` |
| **Cleanup / Defer** | `cleanup drop(buffer)` |
| **String Interpolation** | `$"Hello {name}, count: {n}"` or `$'Val: {v}'` |
| **String Equality** | `if a == b do ... end` (value compare) / `if a != b do ... end`; `str_eq(a, b)` equivalen |
| **File I/O** | `read_text(path)` / `write_text(path, data)` |
| **Threads** | `t = spawn_thread(fn, arg); join_thread(t)` |
| **Mutex** | `m = create_mutex(); lock_mutex(m); unlock_mutex(m); drop_mutex(m)` |
| **FFI / Syscall** | `load_dll("lib.dll")` / `syscall(39, 0, 0, 0, 0, 0, 0)` |