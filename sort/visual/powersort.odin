package sorting

import "core:sort"
import "base:intrinsics"
import "core:fmt"

natural_merge :: proc(arr, buf: []int) {
	if len(arr) < 64 {
		insertion_sort_binary(arr)
		return
	}
	n := len(arr)
	scale := scale_factor(n)

	runs : [dynamic]Run

	
	length := bulk(arr, buf)
	append(&runs,Run{0,length,0})

	read := length
	looping := true if len(arr[read:]) >= 32 else false
	for read + 32 <= n {
		length := bulk(arr[read:], buf)

		power := merge_power(last(runs[:]).start, read, read + length, scale)

		for power <= last(runs[:]).power {
			merge_top(arr, buf, &runs)
		}
		append(&runs, Run{read, length, power})
		read += length
	}
	if read != n {
		lr := last(runs[:])
		if lr.length == 32 {
			insertion_sort_binary(arr[lr.start:], lr.length)
			lr.length += len(arr[read:])
		} else {
			insertion_sort_binary(arr[read:])
			length = len(arr[read:])
			power := merge_power(last(runs[:]).start, read, read + length, scale)

			for power <= last(runs[:]).power {
				merge_top(arr, buf, &runs)
			}
			append(&runs, Run{read, length, power})
		}
	}


	for len(runs) >= 2 {
		merge_top(arr, buf, &runs)
	}
}
natural_merge2 :: proc(arr, buf: []int) {
	if len(arr) < 64 {
		insertion_sort_binary(arr)
		return
	}
	n := len(arr)
	scale := scale_factor(n)

	runs : [dynamic]Run

	
	length := bulk(arr, buf)
	append(&runs,Run{0,length,0})

	read := length
	looping := true if len(arr[read:]) >= 32 else false

	for looping {
		length := bulk(arr[read:], buf)
		if n - read - length < 32 {
			insertion_sort_binary(arr[read:],length)
			length = len(arr[read:])
			looping = false
		}
		power := merge_power(last(runs[:]).start, read, read + length, scale)

		for power <= last(runs[:]).power {
			merge_top(arr, buf, &runs)
		}
		append(&runs, Run{read, length, power})
		read += length
	}


	for len(runs) >= 2 {
		merge_top(arr, buf, &runs)
	}
}

merge_top :: proc(arr, buf: []int, runs: ^[dynamic]Run) {
	assert(len(arr) >= 2)
	r2 := pop_dynamic_array(runs)
	r1 := last(runs^[:])
	merge_cross_swap(arr[r1.start:][:r1.length + r2.length], buf, r1.length)
	r1.length += r2.length
}

Run :: struct {
	start: int,
	length: int,
	power: int,
}

Run_State :: enum u8 {
	Random = 0,
	Ascending = 1,
	Decending = 2,
}

last :: proc(arr: []$T) -> ^T {
	return &arr[len(arr) - 1]
}

bulk :: proc(base, buf: []int) -> (length: int) {

	assert(len(base) >= 32)


	length = 32

	states: [4]Run_State = .Random

	for i in 0..<4 {
		arr := base[i*8:]
		r1 := cast(int)less(&arr[1], &arr[0])
		r2 := cast(int)less(&arr[3], &arr[2])
		r3 := cast(int)less(&arr[5], &arr[4])
		r4 := cast(int)less(&arr[7], &arr[6])

		switch r1 + r2 + r3 + r4 {
		case 0: // ordered
			r5 := cast(int)less(&arr[2], &arr[1])
			r6 := cast(int)less(&arr[4], &arr[3])
			r7 := cast(int)less(&arr[6], &arr[5])
			if r5 + r6 + r7 == 0 { states[i] = .Ascending; continue }
			merge8(arr, buf)
			assert(is_sorted_int(arr[:8]),"merge failed a")
			
		case 4: // reverse
			r5 := cast(int)less(&arr[2], &arr[1])
			r6 := cast(int)less(&arr[4], &arr[3])
			r7 := cast(int)less(&arr[6], &arr[5])
			if r5 + r6 + r7 == 3 { states[i] = .Decending; continue }
			swap(&arr[1], &arr[0])
			swap(&arr[3], &arr[2])
			swap(&arr[5], &arr[4])
			swap(&arr[7], &arr[6])
			merge8(arr, buf)
			assert(is_sorted_int(arr[:8]),"merge failed d")

		case: // random
			if r1 == 1 { swap(&arr[1], &arr[0]) }
			if r2 == 1 { swap(&arr[3], &arr[2]) }
			if r3 == 1 { swap(&arr[5], &arr[4]) }
			if r4 == 1 { swap(&arr[7], &arr[6]) }
			merge8(arr, buf)
			assert(is_sorted_int(arr[:8]),"merge failed r")

		}
	}

	outer: switch states {
		case .Ascending:
			r1 := cast(int)less(&base[8], &base[7])
			r2 := cast(int)less(&base[16], &base[15])
			r3 := cast(int)less(&base[24], &base[23])
			if r1 + r2 + r3 == 0 {
				for i in 32..<len(base) {
					if less(&base[i], &base[i-1]) {
						length = i
	assert(is_sorted_int(base[:length]))
						break outer
					}
				}
				length = len(base)
	assert(is_sorted_int(base[:length]))
			} else {
				parity_merge(buf, base, 8, 8)
				parity_merge(buf[16:], base[16:], 8, 8)
				parity_merge(base, buf, 16, 16)
	assert(length == 32)
	assert(is_sorted_int(base[:length]))
			}
			
		case .Decending:
			r1 := cast(int)less(&base[8], &base[7])
			r2 := cast(int)less(&base[16], &base[15])
			r3 := cast(int)less(&base[24], &base[23])
			if r1 + r2 + r3 == 3 {
				for i in 32..<len(base) {
					if !less(&base[i], &base[i-1]) {
						length = i
						reverse(base[:length])
	assert(is_sorted_int(base[:length]))
						break outer
					}
				}
				reverse(base)
				length = len(base)
	assert(is_sorted_int(base[:length]))
			} else {
				reverse(base[0:8])
				reverse(base[8:16])
				reverse(base[16:24])
				reverse(base[24:32])
				parity_merge(buf, base, 8, 8)
				parity_merge(buf[16:], base[16:], 8, 8)
				parity_merge(base, buf, 16, 16)
	assert(length == 32)
	assert(is_sorted_int(base[:length]))
			}
		case:
			if states[0] | states[1] | states[2] | states[3] == .Decending {
				for s, i in states {
					if s == .Decending {
						reverse(base[8*i:8*(i+1)])
					}
				}
			}


			parity_merge(buf[:16], base[:16], 8, 8)
				// fmt.println(base[:16])
			parity_merge(buf[16:][:16], base[16:][:16], 8, 8)
				// fmt.println(base[16:32])
			parity_merge(base[:32], buf[:32], 16, 16)
	assert(length == 32)
	if !is_sorted_int(base[:length]) {
		fmt.println(base[:length])
	}
	}

	assert(is_sorted_int(base[:length]))
	return length
}

bulk_any :: proc(base, buf: []int, n: int) -> (length: int) {
	assert(8 <= n && n < 16)

	h1 := n / 2 
	q1 := h1 / 2
	q2 := h1 - q1

	h2 := n - h1
	q3 := h2 / 2
	q4 := h2 - q3
	quarts := [?]int{q1,q2,q3,q4}

	for q in quarts {
		switch q {
			case 2:
			case 3:
			case 4:
		}
	}

	
	/*
	32 : 8x4
	36 : 9x4 ?
	40 : 10x4 ?
	...
	60 : 15x4 ?
	*/

	return
}


merge8 :: proc(arr, buf: []int) {
	merge2x2(buf, arr)
	merge2x2(buf[4:], arr[4:])

	merge4x4(arr, buf)
}

merge4x4 :: proc(arr, buf: []int) {
	parity_merge(arr, buf, 4, 4)
}
merge2x2 :: proc(arr, buf: []int) {
	parity_merge(arr, buf, 2, 2)
}

scale_factor :: proc(n: int) -> int {
	return (1 << 62) / n
}

merge_power :: proc(left, mid, right: int, factor: int) -> int {
	x := left + mid
	y := mid + right
	return intrinsics.count_leading_zeros(((factor * x) ~ (factor * y)))
}








PP_Run :: struct {
	start: int,
	length: int,
	power: int,
	in_main: bool,
}

merge_top_pp :: proc(arr, buf: []int, runs: ^[dynamic]PP_Run) {
	assert(len(arr) >= 2)
	r2 := pop_dynamic_array(runs)
	r1 := last(runs^[:])
	merge_cross_swap(arr[r1.start:][:r1.length + r2.length], buf, r1.length)
	r1.length += r2.length
	r1.in_main = false
}

ping_pong_power :: proc(arr, buf: []int) {
	if len(arr) <= 32 {
		insertion_sort_binary(arr)
		return
	}
	n := len(arr)
	scale := scale_factor(n)

	runs : [dynamic]PP_Run

	
	length := bulk(arr, buf)
	append(&runs,PP_Run{0, length, 0, true})

	read := length
	for read + 32 <= n {
		length := bulk(arr[read:], buf)
		power := merge_power(last(runs[:]).start, read, read + length, scale)

		for power <= last(runs[:]).power {
			merge_top_pp(arr, buf, &runs)
		}
		append(&runs, PP_Run{read, length, power, true})
		read += length
	}
	insertion_sort_binary(arr[read:])
	length = len(arr[read:])
	power := merge_power(last(runs[:]).start, read, read + length, scale)

	for power <= last(runs[:]).power {
		merge_top_pp(arr, buf, &runs)
	}
	append(&runs, PP_Run{read, length, power, true})

	for len(runs) >= 2 {
		merge_top_pp(arr, buf, &runs)
	}
}