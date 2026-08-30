// script.rs — Rust script benchmark
// Run: rustc -O script.rs && ./script.exe
// Measures: compile + execute (no JIT mode available)

fn fib(n: i64) -> i64 {
    if n < 2 { n } else { fib(n - 1) + fib(n - 2) }
}

fn loop_sum(n: i64) -> i64 {
    let mut total: i64 = 0;
    let mut i: i64 = 0;
    while i < n { total += i; i += 1; }
    total
}

fn sieve(n: usize) -> i64 {
    let mut primes = vec![1i64; n + 1];
    let mut p = 2;
    while p * p <= n {
        if primes[p] == 1 {
            let mut i = p * p;
            while i <= n { primes[i] = 0; i += p; }
        }
        p += 1;
    }
    let mut count = 0i64;
    for j in 2..=n { if primes[j] == 1 { count += 1; } }
    count
}

fn main() {
    let r1 = fib(30);
    let r2 = loop_sum(1000000);
    let r3 = sieve(50000);
    println!("fib={} sum={} sieve={}", r1, r2, r3);
}
