function fib(n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

function loopSum(n) {
    let t = 0, i = 0;
    while (i < n) { t += i; i++; }
    return t;
}

function tco(n, acc) {
    while (n > 0) { acc++; n--; }
    return acc;
}

function tak(x, y, z) {
    return y >= x ? z : tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
}

function sieve(n) {
    const primes = new Uint8Array(n + 1);
    primes.fill(1);
    for (let p = 2; p * p <= n; p++) {
        if (primes[p]) {
            for (let i = p * p; i <= n; i += p) primes[i] = 0;
        }
    }
    let count = 0;
    for (let j = 2; j <= n; j++) {
        if (primes[j]) count++;
    }
    return count;
}

function mandel(n) {
    let count = 0;
    for (let y = 0; y < n; y++) {
        for (let x = 0; x < n; x++) {
            const cr = -2000 + Math.trunc((x * 3000) / n);
            const ci = -1500 + Math.trunc((y * 3000) / n);
            let zr = 0, zi = 0;
            let iter = 0, inside = 1;
            while (iter < 50 && inside) {
                const zr2 = Math.trunc((zr * zr) / 1000);
                const zi2 = Math.trunc((zi * zi) / 1000);
                if (zr2 + zi2 > 4000) {
                    inside = 0;
                } else {
                    const new_zi = Math.trunc((2 * zr * zi) / 1000) + ci;
                    zr = zr2 - zi2 + cr;
                    zi = new_zi;
                    iter++;
                }
            }
            if (inside) count++;
        }
    }
    return count;
}

const w = process.argv[2] || "fib";
if (w === "fib") console.log(`v=${fib(32)}`);
else if (w === "sum") console.log(`v=${loopSum(5000000)}`);
else if (w === "tco") console.log(`v=${tco(20000000, 0)}`);
else if (w === "tak") console.log(`v=${tak(24, 16, 8)}`);
else if (w === "sieve") console.log(`v=${sieve(100000)}`);
else if (w === "mandel") console.log(`v=${mandel(200)}`);
else process.exit(1);