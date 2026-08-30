// script.js — Node.js script benchmark
// Run: node script.js
// Measures: startup + JIT (V8) + execute

function fib(n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

function loopSum(n) {
    let total = 0;
    for (let i = 0; i < n; i++) total += i;
    return total;
}

function sieve(n) {
    const primes = new Array(n + 1).fill(1);
    let p = 2, count = 0;
    while (p * p <= n) {
        if (primes[p] === 1) {
            for (let i = p * p; i <= n; i += p) primes[i] = 0;
        }
        p++;
    }
    for (let j = 2; j <= n; j++) {
        if (primes[j] === 1) count++;
    }
    return count;
}

const r1 = fib(30);
const r2 = loopSum(1000000);
const r3 = sieve(50000);
console.log(`fib=${r1} sum=${r2} sieve=${r3}`);
