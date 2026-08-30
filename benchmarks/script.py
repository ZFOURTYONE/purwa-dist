#!/usr/bin/env python3
# script.py — Python script benchmark
# Run: python script.py
# Measures: startup + interpret + execute

def fib(n):
    if n < 2: return n
    return fib(n - 1) + fib(n - 2)

def loop_sum(n):
    total = 0
    for i in range(n):
        total += i
    return total

def sieve(n):
    primes = [1] * (n + 1)
    p = 2
    count = 0
    while p * p <= n:
        if primes[p] == 1:
            i = p * p
            while i <= n:
                primes[i] = 0
                i += p
        p += 1
    for j in range(2, n + 1):
        if primes[j] == 1:
            count += 1
    return count

r1 = fib(30)
r2 = loop_sum(1000000)
r3 = sieve(50000)
print(f"fib={r1} sum={r2} sieve={r3}")
