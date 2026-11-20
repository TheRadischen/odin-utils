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
		length := bulk(arr[read:], buf[read:])

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
		length := bulk(arr[read:], buf[read:])
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
						break outer
					}
				}
				length = len(base)
			} else {
				parity_merge(buf, base, 8, 8)
				parity_merge(buf[16:], base[16:], 8, 8)
				parity_merge(base, buf, 16, 16)
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
						break outer
					}
				}
				reverse(base)
				length = len(base)
			} else {
				reverse(base[0:8])
				reverse(base[8:16])
				reverse(base[16:24])
				reverse(base[24:32])
				parity_merge(buf, base, 8, 8)
				parity_merge(buf[16:], base[16:], 8, 8)
				parity_merge(base, buf, 16, 16)
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
			parity_merge(buf[16:][:16], base[16:][:16], 8, 8)
			parity_merge(base[:32], buf[:32], 16, 16)
		}

	return length
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
	if r2.in_main == r1.in_main {
		to,f1,f2 : []int
		if r1.in_main {
			to = buf[r1.start:][:r1.length + r2.length]
			f1 = arr[r1.start:][:r1.length]
			f2 = arr[r2.start:][:r2.length]
		} else {
			to = arr[r1.start:][:r1.length + r2.length]
			f1 = buf[r1.start:][:r1.length]
			f2 = buf[r2.start:][:r2.length]
		}
		merge_cross_right_erm(to, f1, f2)
		r1.in_main = !r1.in_main

	} else {
		if r1.length > r2.length {
			to := arr if r1.in_main else buf
			from := buf if r1.in_main else arr
			dest := to[r1.start:][:r1.length + r2.length]
			f1 := to[r1.start:][:r1.length]
			f2 := from[r2.start:][:r2.length]
			merge_cross_right_erm(dest, f1, f2)
		} else {
			to := arr if r2.in_main else buf
			from := buf if r2.in_main else arr
			dest := to[r1.start:][:r1.length + r2.length]
			f1 := from[r1.start:][:r1.length]
			f2 := to[r2.start:][:r2.length]
			merge_cross_left_erm(dest, f1, f2)
			r1.in_main = r2.in_main
		}
	}
	r1.length += r2.length
}
merge_top_pp_last :: proc(arr, buf: []int, runs: ^[dynamic]PP_Run) {
	assert(len(arr) >= 2)
	r2 := runs[1]
	r1 := runs[0]
	if r2.in_main == r1.in_main {
		if r1.in_main {
			merge_cross_swap(arr, buf, r1.length)
		} else {
			to := arr[r1.start:][:r1.length + r2.length]
			f1 := buf[r1.start:][:r1.length]
			f2 := buf[r2.start:][:r2.length]
			merge_cross_right_erm(to, f1, f2)
		}
	} else {
		if r1.in_main {
			to := arr
			f1 := arr[r1.start:][:r1.length]
			f2 := buf[r2.start:][:r2.length]
			merge_cross_right_erm(to, f1, f2)
		} else {
			to := arr
			f1 := buf[r1.start:][:r1.length]
			f2 := arr[r2.start:][:r2.length]
			merge_cross_left_erm(to, f1, f2)
		}
	}
	r1.length += r2.length
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
		length := bulk(arr[read:], buf[read:])
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

	for len(runs) > 2 {
		merge_top_pp(arr, buf, &runs)
	}
	if len(runs) == 2 {
		merge_top_pp_last(arr, buf, &runs)
	}
}