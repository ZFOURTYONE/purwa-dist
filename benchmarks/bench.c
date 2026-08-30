#include <stdio.h>
#include <string.h>
#include <stdlib.h>

long long fib(int n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

long long loop_sum(long long n) {
    long long t = 0, i = 0;
    while (i < n) { t += i; i++; }
    return t;
}

long long tco(long long n, long long acc) {
    while (n > 0) { acc++; n--; }
    return acc;
}

long long tak(long long x, long long y, long long z) {
    return y >= x ? z : tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
}

long long sieve(int n) {
    char *primes = (char*)malloc(n + 1);
    memset(primes, 1, n + 1);
    for (int p = 2; p * p <= n; p++) {
        if (primes[p]) {
            for (int i = p * p; i <= n; i += p) primes[i] = 0;
        }
    }
    long long count = 0;
    for (int j = 2; j <= n; j++) {
        if (primes[j]) count++;
    }
    free(primes);
    return count;
}

long long mandel(int n) {
    long long count = 0;
    for (int y = 0; y < n; y++) {
        for (int x = 0; x < n; x++) {
            long long cr = -2000 + (x * 3000) / n;
            long long ci = -1500 + (y * 3000) / n;
            long long zr = 0, zi = 0;
            int iter = 0, inside = 1;
            while (iter < 50 && inside) {
                long long zr2 = (zr * zr) / 1000;
                long long zi2 = (zi * zi) / 1000;
                if (zr2 + zi2 > 4000) {
                    inside = 0;
                } else {
                    long long new_zi = (2 * zr * zi) / 1000 + ci;
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

int main(int argc, char **argv) {
    const char *w = argc > 1 ? argv[1] : "fib";
    if (!strcmp(w, "fib")) { printf("v=%lld\n", fib(32)); return 0; }
    if (!strcmp(w, "sum")) { printf("v=%lld\n", loop_sum(5000000)); return 0; }
    if (!strcmp(w, "tco")) { printf("v=%lld\n", tco(20000000, 0)); return 0; }
    if (!strcmp(w, "tak")) { printf("v=%lld\n", tak(24, 16, 8)); return 0; }
    if (!strcmp(w, "sieve")) { printf("v=%lld\n", sieve(100000)); return 0; }
    if (!strcmp(w, "mandel")) { printf("v=%lld\n", mandel(200)); return 0; }
    return 1;
}