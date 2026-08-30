const std = @import("std");

fn fib(n: i64) i64 {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

fn loop_sum(n: i64) i64 {
    var t: i64 = 0;
    var i: i64 = 0;
    while (i < n) : (i += 1) {
        t += i;
    }
    return t;
}

fn tco(n_in: i64, acc_in: i64) i64 {
    var n = n_in;
    var acc = acc_in;
    while (n > 0) : (n -= 1) {
        acc += 1;
    }
    return acc;
}

fn tak(x: i64, y: i64, z: i64) i64 {
    if (y >= x) return z;
    return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
}

fn sieve(n: usize) i64 {
    var primes: [100001]bool = undefined;
    @memset(&primes, true);

    var p: usize = 2;
    while (p * p <= n) : (p += 1) {
        if (primes[p]) {
            var i = p * p;
            while (i <= n) : (i += p) {
                primes[i] = false;
            }
        }
    }

    var count: i64 = 0;
    var j: usize = 2;
    while (j <= n) : (j += 1) {
        if (primes[j]) count += 1;
    }
    return count;
}

fn mandel(n: i64) i64 {
    var count: i64 = 0;
    var y: i64 = 0;
    while (y < n) : (y += 1) {
        var x: i64 = 0;
        while (x < n) : (x += 1) {
            const cr = -2000 + @divTrunc(x * 3000, n);
            const ci = -1500 + @divTrunc(y * 3000, n);
            var zr: i64 = 0;
            var zi: i64 = 0;
            var iter: i32 = 0;
            var inside: bool = true;
            while (iter < 50 and inside) {
                const zr2 = @divTrunc(zr * zr, 1000);
                const zi2 = @divTrunc(zi * zi, 1000);
                if (zr2 + zi2 > 4000) {
                    inside = false;
                } else {
                    const new_zi = @divTrunc(2 * zr * zi, 1000) + ci;
                    zr = zr2 - zi2 + cr;
                    zi = new_zi;
                    iter += 1;
                }
            }
            if (inside) count += 1;
        }
    }
    return count;
}

extern "kernel32" fn GetCommandLineA() callconv(.c) [*:0]const u8;

pub fn main() void {
    const cmd = std.mem.span(GetCommandLineA());

    if (std.mem.indexOf(u8, cmd, "fib") != null) {
        std.debug.print("v={d}\n", .{fib(32)});
    } else if (std.mem.indexOf(u8, cmd, "sum") != null) {
        std.debug.print("v={d}\n", .{loop_sum(5000000)});
    } else if (std.mem.indexOf(u8, cmd, "tco") != null) {
        std.debug.print("v={d}\n", .{tco(20000000, 0)});
    } else if (std.mem.indexOf(u8, cmd, "tak") != null) {
        std.debug.print("v={d}\n", .{tak(24, 16, 8)});
    } else if (std.mem.indexOf(u8, cmd, "sieve") != null) {
        std.debug.print("v={d}\n", .{sieve(100000)});
    } else if (std.mem.indexOf(u8, cmd, "mandel") != null) {
        std.debug.print("v={d}\n", .{mandel(200)});
    } else {
        std.debug.print("v={d}\n", .{fib(32)});
    }
}
