use std::env;

fn fib(n: i64) -> i64 {
    if n < 2 { n } else { fib(n - 1) + fib(n - 2) }
}

fn loop_sum(n: i64) -> i64 {
    let mut t = 0i64;
    let mut i = 0i64;
    while i < n {
        t += i;
        i += 1;
    }
    t
}

fn tco(mut n: i64, mut acc: i64) -> i64 {
    while n > 0 {
        acc += 1;
        n -= 1;
    }
    acc
}

fn tak(x: i64, y: i64, z: i64) -> i64 {
    if y >= x { z } else { tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y)) }
}

fn sieve(n: usize) -> i64 {
    let mut primes = vec![true; n + 1];
    let mut p = 2;
    while p * p <= n {
        if primes[p] {
            let mut i = p * p;
            while i <= n {
                primes[i] = false;
                i += p;
            }
        }
        p += 1;
    }
    let mut count = 0;
    for j in 2..=n {
        if primes[j] { count += 1; }
    }
    count
}

fn mandel(n: i64) -> i64 {
    let mut count = 0;
    for y in 0..n {
        for x in 0..n {
            let cr = -2000 + (x * 3000) / n;
            let ci = -1500 + (y * 3000) / n;
            let mut zr = 0i64;
            let mut zi = 0i64;
            let mut iter = 0;
            let mut inside = true;
            while iter < 50 && inside {
                let zr2 = (zr * zr) / 1000;
                let zi2 = (zi * zi) / 1000;
                if zr2 + zi2 > 4000 {
                    inside = false;
                } else {
                    let new_zi = (2 * zr * zi) / 1000 + ci;
                    zr = zr2 - zi2 + cr;
                    zi = new_zi;
                    iter += 1;
                }
            }
            if inside { count += 1; }
        }
    }
    count
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let w = if args.len() > 1 { args[1].as_str() } else { "fib" };
    match w {
        "fib" => println!("v={}", fib(32)),
        "sum" => println!("v={}", loop_sum(5000000)),
        "tco" => println!("v={}", tco(20000000, 0)),
        "tak" => println!("v={}", tak(24, 16, 8)),
        "sieve" => println!("v={}", sieve(100000)),
        "mandel" => println!("v={}", mandel(200)),
        _ => std::process::exit(1),
    }
}