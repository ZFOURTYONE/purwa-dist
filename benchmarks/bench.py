import sys

sys.setrecursionlimit(50000000)

def fib(n):
    return n if n < 2 else fib(n - 1) + fib(n - 2)

def loop_sum(n):
    t = 0
    i = 0
    while i < n:
        t += i
        i += 1
    return t

def tco(n, acc):
    while n > 0:
        acc += 1
        n -= 1
    return acc

def tak(x, y, z):
    return z if y >= x else tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y))

def sieve(n):
    primes = [True] * (n + 1)
    p = 2
    while p * p <= n:
        if primes[p]:
            for i in range(p * p, n + 1, p):
                primes[i] = False
        p += 1
    return sum(1 for j in range(2, n + 1) if primes[j])

def mandel(n):
    count = 0
    for y in range(n):
        for x in range(n):
            cr = -2000 + int((x * 3000) / n)
            ci = -1500 + int((y * 3000) / n)
            zr = 0
            zi = 0
            iter = 0
            inside = 1
            while iter < 50 and inside:
                zr2 = int((zr * zr) / 1000)
                zi2 = int((zi * zi) / 1000)
                if zr2 + zi2 > 4000:
                    inside = 0
                else:
                    new_zi = int((2 * zr * zi) / 1000) + ci
                    zr = zr2 - zi2 + cr
                    zi = new_zi
                    iter += 1
            if inside:
                count += 1
    return count

w = sys.argv[1] if len(sys.argv) > 1 else "fib"
if w == "fib":
    print(f"v={fib(32)}")
elif w == "sum":
    print(f"v={loop_sum(5000000)}")
elif w == "tco":
    print(f"v={tco(20000000, 0)}")
elif w == "tak":
    print(f"v={tak(24, 16, 8)}")
elif w == "sieve":
    print(f"v={sieve(100000)}")
elif w == "mandel":
    print(f"v={mandel(200)}")
else:
    sys.exit(1)