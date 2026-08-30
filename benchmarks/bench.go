package main

import (
	"fmt"
	"os"
)

func fib(n int64) int64 {
	if n < 2 {
		return n
	}
	return fib(n-1) + fib(n-2)
}

func loopSum(n int64) int64 {
	var t, i int64
	for i < n {
		t += i
		i++
	}
	return t
}

func tco(n, acc int64) int64 {
	for n > 0 {
		acc++
		n--
	}
	return acc
}

func tak(x, y, z int64) int64 {
	if y >= x {
		return z
	}
	return tak(tak(x-1, y, z), tak(y-1, z, x), tak(z-1, x, y))
}

func sieve(n int) int64 {
	primes := make([]bool, n+1)
	for i := range primes {
		primes[i] = true
	}
	for p := 2; p*p <= n; p++ {
		if primes[p] {
			for i := p * p; i <= n; i += p {
				primes[i] = false
			}
		}
	}
	var count int64
	for j := 2; j <= n; j++ {
		if primes[j] {
			count++
		}
	}
	return count
}

func mandel(n int64) int64 {
	var count int64
	for y := int64(0); y < n; y++ {
		for x := int64(0); x < n; x++ {
			cr := -2000 + (x*3000)/n
			ci := -1500 + (y*3000)/n
			var zr, zi int64
			iter := 0
			inside := true
			for iter < 50 && inside {
				zr2 := (zr * zr) / 1000
				zi2 := (zi * zi) / 1000
				if zr2+zi2 > 4000 {
					inside = false
				} else {
					newZi := (2*zr*zi)/1000 + ci
					zr = zr2 - zi2 + cr
					zi = newZi
					iter++
				}
			}
			if inside {
				count++
			}
		}
	}
	return count
}

func main() {
	w := "fib"
	if len(os.Args) > 1 {
		w = os.Args[1]
	}
	switch w {
	case "fib":
		fmt.Printf("v=%d\n", fib(32))
	case "sum":
		fmt.Printf("v=%d\n", loopSum(5000000))
	case "tco":
		fmt.Printf("v=%d\n", tco(20000000, 0))
	case "tak":
		fmt.Printf("v=%d\n", tak(24, 16, 8))
	case "sieve":
		fmt.Printf("v=%d\n", sieve(100000))
	case "mandel":
		fmt.Printf("v=%d\n", mandel(200))
	default:
		os.Exit(1)
	}
}