
package msort

import "base:intrinsics"


piposort :: proc(arr: $A, $cmp: $P, allocator := context.allocator) {
	CONST_SORT :: 28
	swap := non_zero_make(A, len(arr), allocator)
	ping_pong(arr, swap)
	delete(swap, allocator)
	
	ping_pong :: proc(arr, swap: A) #no_bounds_check {
		n := len(arr)

		if n <= 7 {
			networks(arr, swap)
			return
		}

		half1 := n / 2
		quad1 := half1 / 2
		quad2 := half1 - quad1
		half2 := n - half1
		quad3 := half2 / 2
		quad4 := half2 - quad3

		ping_pong(arr[:quad1],         swap)
		ping_pong(arr[quad1:][:quad2], swap)
		ping_pong(arr[half1:][:quad3], swap)
		ping_pong(arr[half1 + quad3:], swap)

		s1 := cast(int)!cmp(arr[quad1],         arr[quad1 - 1])
		s2 := cast(int)!cmp(arr[half1],         arr[half1 - 1])
		s3 := cast(int)!cmp(arr[half1 + quad3], arr[half1 + quad3 - 1])

		switch s1 + s2 * 2 + s3 * 4 {
			case 1, 3: {
				my_copy(swap[:half1], arr[:half1])
				merge_parity(arr[half1:], swap[half1:], quad3, quad4)
				merge_parity(swap,        arr,          half1, half2)
			}
			case 4, 6: {
				merge_parity(arr,         swap,         quad1, quad2)
				my_copy(swap[half1:], arr[half1:])
				merge_parity(swap,        arr,          half1, half2)
			}
			case 5: {
				my_copy(swap[:half1], arr[:half1])
				my_copy(swap[half1:], arr[half1:])
				merge_parity(swap,        arr,          half1, half2)
			}
			case 7: return
			case:
		}
		merge_parity(arr,         swap,         quad1, quad2)
		merge_parity(arr[half1:], swap[half1:], quad3, quad4)
		merge_parity(swap,        arr,          half1, half2)
	}
	
	pipo_small :: proc(arr, swap: A, $N: int) #no_bounds_check {
		half1 :: N / 2
		quad1 :: half1 / 2
		quad2 :: half1 - quad1
		half2 :: N - half1
		quad3 :: half2 / 2
		quad4 :: half2 - quad3

		networks_stable(arr[:quad1]        , swap, quad1)
		networks_stable(arr[quad1:][:quad2], swap, quad2)
		networks_stable(arr[half1:][:quad3], swap, quad3)
		networks_stable(arr[half1 + quad3:], swap, quad4)

		s1 := cast(int)!cmp(arr[quad1],         arr[quad1 - 1])
		s2 := cast(int)!cmp(arr[half1],         arr[half1 - 1])
		s3 := cast(int)!cmp(arr[half1 + quad3], arr[half1 + quad3 - 1])

		if !cmp(arr[quad1],         arr[quad1 - 1]) &&
		   !cmp(arr[half1],         arr[half1 - 1]) &&
		   !cmp(arr[half1 + quad3], arr[half1 + quad3 - 1]) {
			return
		}

		merge_parity_const(arr,         swap,         quad1, quad2)
		merge_parity_const(arr[half1:], swap[half1:], quad3, quad4)
		merge_parity_const(swap,        arr,          half1, half2)
	}

	merge_parity_const :: proc(from, to: A, $left, $right: int) #no_bounds_check {
		left_low := 0
		left_high := left - 1
		right_low := left
		right_high := left + right - 1
		write_low := 0
		write_high := right_high

		#unroll for _ in 0..<left {
			to[inc(&write_low)] = from[inc(&left_low)] if !cmp(from[right_low], from[left_low]) else from[inc(&right_low)]
			to[dec(&write_high)] = from[dec(&left_high)] if cmp(from[right_high], from[left_high]) else from[dec(&right_high)]
		}

		when left != right {
			to[inc(&write_low)] = from[inc(&left_low)] if !cmp(from[right_low], from[left_low]) else from[inc(&right_low)]
		}
	}

	merge_parity :: proc(from, to: A, left, right: int) #no_bounds_check {
		left_low := 0
		left_high := left - 1
		right_low := left
		right_high := left + right - 1
		write_low := 0
		write_high := right_high

		for _ in 0..<left {
			to[inc(&write_low)] = from[inc(&left_low)] if !cmp(from[right_low], from[left_low]) else from[inc(&right_low)]
			to[dec(&write_high)] = from[dec(&left_high)] if cmp(from[right_high], from[left_high]) else from[dec(&right_high)]
		}

		if left != right {
			to[inc(&write_low)] = from[inc(&left_low)] if !cmp(from[right_low], from[left_low]) else from[inc(&right_low)]
		}
	}

	inc :: #force_inline proc(ptr: ^int) -> int {
		defer ptr^ += 1
		return ptr^
	}

	dec :: #force_inline proc(ptr: ^int) -> int {
		defer ptr^ -= 1
		return ptr^
	}

	aux_rotation :: proc(arr, swap: A, left, right: int) #no_bounds_check {
		my_copy(swap,        arr[:left])
		my_copy(arr,         arr[left:][:right])
		my_copy(arr[right:], swap[:left])
	}

	networks :: proc(arr, swap: A) {
		switch len(arr) {
		case 7: networks_stable(arr, swap, 7)
		case 6: networks_stable(arr, swap, 6)
		case 5: networks_stable(arr, swap, 5)
		case 4: networks_stable(arr, swap, 4)
		case 3: networks_stable(arr, swap, 3)
		case 2: networks_stable(arr, swap, 2)
		case 0,1:
		}
	}

	networks_stable :: #force_inline proc(arr, swap: A, $N: int) #no_bounds_check {
		when N == 0 || N == 1 {
			return
		} else when N == 2 {
            cond_swap(arr, 0, 1)
		} else when N == 3 {
            cond_swap(arr, 0, 1)
            cond_swap(arr, 1, 2)
            cond_swap(arr, 0, 1)
		} else when N == 4 {
			cond_swap(arr, 0, 1)
			cond_swap(arr, 2, 3)
			if !cmp(arr[1], arr[2]) {
				arr[1], arr[2] = arr[2], arr[1]
				cond_swap(arr, 0, 1)
				cond_swap(arr, 2, 3)
				cond_swap(arr, 1, 2)
			}
		} else when N == 5 {
			cond_swap(arr, 0, 1)
			cond_swap(arr, 2, 3)
			x := cond_swap(arr, 1, 2)
			y := cond_swap(arr, 3, 4)
			if (x + y) == 2 {
				return
			}
			cond_swap(arr, 0, 1)
			cond_swap(arr, 2, 3)
			cond_swap(arr, 1, 2)
			cond_swap(arr, 3, 4)
			cond_swap(arr, 0, 1)
			cond_swap(arr, 2, 3)
			
		} else when N == 6 {
			cond_swap(arr, 0, 1)
			cond_swap(arr, 2, 3)
			cond_swap(arr, 4, 5)
			x := cond_swap(arr, 1, 2)
			y := cond_swap(arr, 3, 4)
			if (x + y) == 2 {
				return
			}

			x = cast(int)cmp(arr[0], arr[1])
			swap[0] = arr[1-x]
			swap[1] = arr[x]
			swap[2] = arr[2]

			y = cast(int)cmp(arr[4], arr[5])
			swap[3] = arr[3]
			swap[4] = arr[5-y]
			swap[5] = arr[4+y]

			left_low := 0
			left_high := 2
			right_low := 3
			right_high := 5
			write_low := 0
			write_high := 5

			#unroll for _ in 0..<3 {
				arr[inc(&write_low)] = swap[inc(&left_low)] if !cmp(swap[right_low], swap[left_low]) else swap[inc(&right_low)]
				arr[dec(&write_high)] = swap[dec(&left_high)] if cmp(swap[right_high], swap[left_high]) else swap[dec(&right_high)]
			}

		} else when N == 7 {
			cond_swap(arr, 0, 1)
			cond_swap(arr, 2, 3)
			cond_swap(arr, 4, 5)
			x := cond_swap(arr, 1, 2)
			y := cond_swap(arr, 3, 4)
			z := cond_swap(arr, 5, 6)
			if x + y + z == 3 {
				return
			}

			cond_swap(arr,4,5)

			x = cast(int)cmp(arr[0], arr[1])
			swap[0] = arr[1-x]
			swap[1] = arr[x]
			swap[2] = arr[2]

			y = cast(int)cmp(arr[3], arr[4])
			swap[3] = arr[4-y]
			swap[4] = arr[3+y]

			z = cast(int)cmp(arr[5], arr[6])
			swap[5] = arr[6-z]
			swap[6] = arr[5+z]

			left_low := 0
			left_high := 2
			right_low := 3
			right_high := 6
			write_low := 0
			write_high := 6

			#unroll for _ in 0..<3 {
				arr[inc(&write_low)] = swap[inc(&left_low)] if !cmp(swap[right_low], swap[left_low]) else swap[inc(&right_low)]
				arr[dec(&write_high)] = swap[dec(&left_high)] if cmp(swap[right_high], swap[left_high]) else swap[dec(&right_high)]
			}
			arr[inc(&write_low)] = swap[inc(&left_low)] if !cmp(swap[right_low], swap[left_low]) else swap[inc(&right_low)]
		} else {
			#panic(" unreachable")
		}
    }

	cond_swap :: #force_inline proc(arr: A, l, r: int) -> int #no_bounds_check {
		x := cast(int)cmp(arr[l], arr[r]) * (r - l)
		arr[l], arr[r] = arr[r - x], arr[l + x]
		return x
	}

	my_copy :: #force_inline proc(to, from: A) #no_bounds_check {
		when intrinsics.type_is_slice(A) {
			copy(to, from)
		} else {
			length := min(len(to), len(from))
			for i in 0..<length {
				to[i] = from[i]
			}
		}
	}
}