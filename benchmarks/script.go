// script.go — Go script benchmark
// Run: go run script.go
// Measures: compile (go build) + execute

package main

import "fmt"

func fib(n int) int {
	if n < 2 { return n }
	return fib(n-1) + fib(n-2)
}

func loopSum(n int) int {
	total := 0
	for i := 0; i < n; i++ { total += i }
	return total
}

func sieve(n int) int {
	primes := make([]int, n+1)
	for i := range primes { primes[i] = 1 }
	p, count := 2, 0
	for p*p <= n {
		if primes[p] == 1 {
			for i := p * p; i <= n; i += p { primes[i] = 0 }
		}
		p++
	}
	for j := 2; j <= n; j++ {
		if primes[j] == 1 { count++ }
	}
	return count
}

func main() {
	r1, r2, r3 := fib(30), loopSum(1000000), sieve(50000)
	fmt.Printf("fib=%d sum=%d sieve=%d\n", r1, r2, r3)
}
