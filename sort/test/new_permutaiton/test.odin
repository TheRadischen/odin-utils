package main

import "core:fmt"
import "core:math/rand"
import "core:time"
import "core:slice"
main :: proc(){
	
	for i:= 10; i <= 1_000_000; i*= 10 {
		test(i)
	}
}
Data :: struct{
	rand: int,
	junk: [5]int,
}
data_less :: proc(l, r: Data) -> bool {return l.rand < r.rand}
test :: proc(size: int) {


	arr := make([]int, size)
	arr2 := make([]int, size)
	data := make([]Data, size)
	data2 := make([]Data, size)

	ITER :: 10
	times1 : [ITER]time.Duration
	times2 : [ITER]time.Duration
	times3 : [ITER]time.Duration
	times4 : [ITER]time.Duration
	for i in 0..<ITER {
		for &a in data {
			a.rand = rand.int_max(size)
		}
		for &a in arr {
			a = rand.int_max(size)
		}
		copy(arr2, arr)
		copy(data2, data)

		ind := slice.sort_with_indices(arr)
		ind2 := slice.sort_by_with_indices(data, data_less)

		start := time.tick_now()
		slice.sort_from_permutation_indices(arr2, ind)
		dur := time.tick_since(start)

		start2 := time.tick_now()
		slice.sort_from_permutation_indices(data2, ind2)
		dur2 := time.tick_since(start2)

		if !is_sorted(arr) {
			panic("not sorted")
		}
		if !is_sorted(arr2) {
			panic("not sorted")
		}
		if !is_sorted_by(data, data_less) {
			panic("not sorted")
		}
		if !is_sorted_by(data2, data_less) {
			panic("not sorted")
		}

		for &a in data {
			a.rand = rand.int_max(size)
		}
		for &a in arr {
			a = rand.int_max(size)
		}
		copy(arr2, arr)
		copy(data2, data)

		ind3 := sort_with_indices(arr)
		ind4 := sort_by_with_indices(data, data_less)

		start3 := time.tick_now()
		sort_from_permutation_indices(arr2, ind3)
		dur3 := time.tick_since(start3)

		start4 := time.tick_now()
		sort_from_permutation_indices(data2, ind4)
		dur4 := time.tick_since(start4)

		if !is_sorted(arr) {
			panic("not sorted")
		}
		if !is_sorted(arr2) {
			panic("not sorted")
		}
		if !is_sorted_by(data, data_less) {
			panic("not sorted")
		}
		if !is_sorted_by(data2, data_less) {
			panic("not sorted")
		}


		times1[i] = dur
		times2[i] = dur2
		times3[i] = dur3
		times4[i] = dur4
	}
	slice.sort(times1[:])
	slice.sort(times2[:])
	slice.sort(times3[:])
	slice.sort(times4[:])

	fmt.println("Size:",size)
	fmt.println("new perm on 80 byte",times1[ITER / 4])
	fmt.println("old perm on 80 byte",times3[ITER / 4])
	fmt.println("new perm on 8 byte",times2[ITER / 4])
	fmt.println("old perm on 8 byte",times4[ITER / 4])
	fmt.println()
}

