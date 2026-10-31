package msort

import "base:intrinsics"

/*
	thanks to scandum for flux partitioning
	https://github.com/scandum
*/

// uncomment if used independently

// ORD :: intrinsics.type_is_ordered
// Ordering :: enum {
// 	Less = -1,
// 	Equal = 0,
// 	Greater = 1,
// }

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		arr := []int{3,2,1}
		sort.sort_stable(arr)
	}
*/
sort_stable :: proc(arr: $T/[]$E, allocator := context.allocator) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			base_type :: intrinsics.type_core_type(E)
			mini_flux(transmute([]base_type)arr, rawptr(nil), proc(l, r: base_type, data: rawptr) -> bool { return l < r }, allocator)
		}
	}
}


/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		Data :: struct { rand: int, data: int }
		data_less :: proc(l, r: Data) -> bool { return l.rand < r.rand }
		arr := make([]Data, 10)
		// fill with data
		sort.sort_stable_by(arr, data_less)
	}
*/
sort_stable_by :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool, allocator := context.allocator) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			mini_flux(arr, rawptr(nil), proc(l, r: E, data: rawptr) -> bool { return LESS(l, r) }, allocator)
		}
	}
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		arr := []int{3,2,1}
		indices := sort.sort_stable_with_indices(arr)
		// arr = {1,2,3}
		defer delete(indices)
	}
*/
sort_stable_with_indices :: proc(arr: $T/[]$E, allocator := context.allocator) -> (indices: []int) where ORD(E) {
	indices = non_zero_make([]int, len(arr), allocator)
	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}

			base_type :: intrinsics.type_core_type(E)
			base := transmute([]base_type)arr
			mini_flux(indices, &base, proc(l, r: int, user_data: ^T) -> bool {
				return user_data[l] < user_data[r]
			}, allocator)
			
			sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		Data :: struct { rand: int, data: [10]int }
		data_less :: proc(l, r: Data) -> bool { return l.rand < r.rand }
		arr := non_zero_make([]Data, 10)
		// fill with data
		sort.sort_stable_by_with_indices(arr, data_less, context.temp_allocator)
		free_all(context.temp_allocator)
	}
*/
sort_stable_by_with_indices :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool, allocator := context.allocator) -> (indices: []int) {
	indices = non_zero_make([]int, len(arr), allocator)

	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}

			arr := arr
			mini_flux(indices, &arr, proc(l, r: int, user_data: ^T) -> bool {
				return LESS(user_data[l], user_data[r])
			}, allocator)

			sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		Data :: struct { rand: int, data: [10]int }
		modulus := []int{5,4,6,7,3,2,1,8,9,0}
		less_data_modulus :: proc(l, r: Data, mod: ^[]int)->bool{
			left := l.rand %% 10
			right := r.rand %% 10
			return mod[left] < mod[right]
		}
		arr := non_zero_make([]Data, 10)
		// fill with data
		sort.sort_stable_by_with_data(data, less_data_modulus, &modulus)
	}
*/
sort_stable_by_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: ^$D) -> bool, user_data: ^D, allocator := context.allocator) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			mini_flux(arr, user_data, proc(l, r: E, user_data: ^D) -> bool {
				return LESS(l, r, user_data)
			}, allocator)
		}
	}
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		Data :: struct { rand: int, data: [10]int }
		modulus := []int{5,4,6,7,3,2,1,8,9,0}
		less_data_modulus :: proc(l, r: Data, mod: ^[]int)->bool{
			left := l.rand %% 10
			right := r.rand %% 10
			return mod[left] < mod[right]
		}
		arr := non_zero_make([]Data, 10)
		// fill with data
		indices := sort.sort_stable_by_with_indices_with_data(data, less_data_modulus, &modulus)
		defer delete(indices)
	}
*/
sort_stable_by_with_indices_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: ^$D) -> bool, user_data: ^D, allocator := context.allocator) -> (indices: []int) {
	indices = non_zero_make([]int, len(arr), allocator)
	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}
			
			Context :: struct {
				arr: T,
				user_data: ^D,
			}
			arr := arr
			ctx := &Context{arr, user_data}

			mini_flux(indices, ctx, proc(l, r: int, ctx: ^Context) -> bool {
				return LESS(ctx.arr[l], ctx.arr[r], ctx.user_data)
			}, allocator)

			sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is stable
sort_stable_by_cmp :: proc(arr: $T/[]$E, $CMP: proc(l, r: E) -> Ordering, allocator := context.allocator) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			mini_flux(arr, rawptr(nil), proc(l, r: E, user_data: rawptr) -> bool { return CMP(l, r) == .Less }, allocator)
		}
	}
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is stable
sort_stable_by_cmp_with_data :: proc(arr: $T/[]$E, $CMP: proc(l, r: E, user_data: ^$D) -> Ordering, user_data: ^D, allocator := context.allocator) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			mini_flux(arr, user_data, proc(l, r: E, user_data: ^D) -> bool {
				return CMP(l, r, user_data) == .Less
			}, allocator)
		}
	}
}



mini_flux :: proc(arr: $A/[]$T, data: $D, $LESS: $P, allocator := context.allocator) {
	if len(arr) <= SMALL_THRESHOLD && size_of(T) <= 40 {
		swap : [SMALL_THRESHOLD]T = ---
		pingpong(arr, swap[:], data)
		return
	}
	SMALL_THRESHOLD :: 28 * 4 * 4

	swap := non_zero_make(A, len(arr), allocator)
	loop(arr, swap, arr, data, nil, 0)
	delete(swap, allocator)

	loop :: proc(arr, swap, cur: A, data: D, last_piv: Maybe(T), unbalanced: int) #no_bounds_check {
		arr := arr; cur := cur; last_piv := last_piv; unbalanced := unbalanced
		for {
			if len(arr) <= SMALL_THRESHOLD {
				if raw_data(arr) != raw_data(cur) {
					intrinsics.mem_copy_non_overlapping(raw_data(arr), raw_data(cur), len(cur) * size_of(T))
				}
				pingpong(arr, swap, data)
				return
			}

			median_3_depth := log2(len(arr)) / 5
			rand := 0
			if unbalanced >= 3 {
				unbalanced -= 1
				rand = cast(int)intrinsics.read_cycle_counter() & (63 if len(arr) > 2048 else 3)
			}
			
			pivot := median_3(cur[rand:], data, median_3_depth)

			if pivot == last_piv {
				left := partition_reverse(arr, swap, cur, data, pivot)
				right := len(arr) - left
				arr = arr[left:]
				cur = swap[:right]
				last_piv = nil
				continue
			}

			left := partition(arr, swap, cur, data, pivot)
			right := len(arr) - left

			if left < right / 32 || right < left / 32 {
				unbalanced += 1
			}
			
			loop(arr[left:], swap, swap[:right], data, pivot, unbalanced)
			arr = arr[:left]
			cur = arr[:left]
			last_piv = nil
		}
	}

	log2 :: proc(n: int) -> (log: int) {
		n := n
		for ; n > 0 ;n >>= 1 {
			log += 1
		}
		return log
	}

	median_3 :: proc(arr: A, data: D, depth: int) -> T #no_bounds_check {
		if depth == 0 {
			return arr[0]
		}

		div := len(arr) / 3

		swap := [3]T{
			median_3(arr[:div], data, depth - 1), 
			median_3(arr[div:][:div], data, depth - 1), 
			median_3(arr[div * 2:], data, depth - 1)
		}
		
		x := LESS(swap[0], swap[1], data)
		y := LESS(swap[0], swap[2], data)
		z := LESS(swap[1], swap[2], data)

		return swap[(int)(x == y) + (int)(y ~ z)]
	}

	partition :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
		less := 0

		#unroll(8) for a,i in cur {
			x := cast(int)LESS(a, piv, data)
			arr[less] = a
			swap[i - less] = a
			less += x
		}
		
		return less
	}

	partition_reverse :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
		less_equal := 0

		#unroll(8) for a,i in cur {
			x := cast(int)!LESS(piv, a, data)
			arr[less_equal] = a
			swap[i - less_equal] = a
			less_equal += x
		}
		
		return less_equal
	}

	pingpong :: proc(arr, swap: A, data: D) #no_bounds_check {
		if len(arr) <= 7 {
			networks_stable(arr, data)
			return
		} 

		half1 := len(arr) / 2
		quad1 := half1 / 2
		quad2 := half1 - quad1
		half2 := len(arr) - half1
		quad3 := half2 / 2
		quad4 := half2 - quad3

		pingpong(arr        [:quad1], swap, data)
		pingpong(arr[quad1:][:quad2], swap, data)
		pingpong(arr[half1:][:quad3], swap, data)
		pingpong(arr[half1 + quad3:], swap, data)

		if  !LESS(arr[quad1],         arr[quad1 - 1],         data) &&
		    !LESS(arr[half1],         arr[half1 - 1],         data) &&
		    !LESS(arr[half1 + quad3], arr[half1 + quad3 - 1], data) {
				return
		}

		parity_merge(swap[:half1], arr[:half1], quad1, quad2, data)
		parity_merge(swap[half1:], arr[half1:], quad3, quad4, data)
		parity_merge(arr,          swap,        half1, half2, data)
	}

	parity_merge :: proc(to, from: A, left, right: int, data: D) #no_bounds_check {
		left_low := 0
		left_high := left - 1
		right_low := left
		right_high := left + right - 1
		write_low := 0
		write_high := right_high

		for _ in 0..<left {
			to[inc(&write_low)] = from[inc(&right_low)] if LESS(from[right_low], from[left_low], data) else from[inc(&left_low)]
			to[dec(&write_high)] = from[dec(&left_high)] if LESS(from[right_high], from[left_high], data) else from[dec(&right_high)]
		}

		if left != right {
			to[inc(&write_low)] = from[inc(&right_low)] if LESS(from[right_low], from[left_low], data) else from[inc(&left_low)]
		}
	}

	cond_swap :: #force_inline proc(arr: A, data: D, l, r: int) -> (less: int) #no_bounds_check {
		less = cast(int)LESS(arr[l], arr[r], data) * (r - l)
		arr[l], arr[r] = arr[r - less], arr[l + less]
		return less
	}

	networks_stable :: proc(arr: A, data: D) #no_bounds_check {
		switch len(arr) {
		case 7: 
			cond_swap(arr, data, 0, 1)
			cond_swap(arr, data, 2, 3)
			cond_swap(arr, data, 4, 5)
			x := cond_swap(arr, data, 1, 2)
			y := cond_swap(arr, data, 3, 4)
			z := cond_swap(arr, data, 5, 6)
			if x + y + z == 3 {
				return
			}

			cond_swap(arr, data, 4, 5)

			swap: [7]T = ---

			x = cast(int)LESS(arr[0], arr[1], data)
			swap[0] = arr[1-x]
			swap[1] = arr[x]
			swap[2] = arr[2]

			y = cast(int)LESS(arr[3], arr[4], data)
			swap[3] = arr[4-y]
			swap[4] = arr[3+y]

			z = cast(int)LESS(arr[5], arr[6], data)
			swap[5] = arr[6-z]
			swap[6] = arr[5+z]

			left_low := 0
			left_high := 2
			right_low := 3
			right_high := 6
			write_low := 0
			write_high := 6

			#unroll for _ in 0..<3 {
				arr[inc(&write_low)] = swap[inc(&left_low)] if !LESS(swap[right_low], swap[left_low], data) else swap[inc(&right_low)]
				arr[dec(&write_high)] = swap[dec(&left_high)] if LESS(swap[right_high], swap[left_high], data) else swap[dec(&right_high)]
			}
			arr[inc(&write_low)] = swap[inc(&left_low)] if !LESS(swap[right_low], swap[left_low], data) else swap[inc(&right_low)]
		case 6: 
			cond_swap(arr, data, 0, 1)
			cond_swap(arr, data, 2, 3)
			cond_swap(arr, data, 4, 5)
			x := cond_swap(arr, data, 1, 2)
			y := cond_swap(arr, data, 3, 4)
			if (x + y) == 2 {
				return
			}

			swap: [6]T = ---

			x = cast(int)LESS(arr[0], arr[1], data)
			swap[0] = arr[1-x]
			swap[1] = arr[x]
			swap[2] = arr[2]

			y = cast(int)LESS(arr[4], arr[5], data)
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
				arr[inc(&write_low)] = swap[inc(&left_low)] if !LESS(swap[right_low], swap[left_low], data) else swap[inc(&right_low)]
				arr[dec(&write_high)] = swap[dec(&left_high)] if LESS(swap[right_high], swap[left_high], data) else swap[dec(&right_high)]
			}
		case 5: 
			cond_swap(arr, data, 0, 1)
			cond_swap(arr, data, 2, 3)
			x := cond_swap(arr, data, 1, 2)
			y := cond_swap(arr, data, 3, 4)
			if (x + y) == 2 {
				return
			}
			cond_swap(arr, data, 0, 1)
			cond_swap(arr, data, 2, 3)
			cond_swap(arr, data, 1, 2)
			cond_swap(arr, data, 3, 4)
			cond_swap(arr, data, 0, 1)
			cond_swap(arr, data, 2, 3)
		case 4: 
			cond_swap(arr, data, 0, 1)
			cond_swap(arr, data, 2, 3)
			if !LESS(arr[1], arr[2], data) {
				arr[1], arr[2] = arr[2], arr[1]
				cond_swap(arr, data, 0, 1)
				cond_swap(arr, data, 2, 3)
				cond_swap(arr, data, 1, 2)
			}
		case 3: 
            cond_swap(arr, data, 0, 1)
            cond_swap(arr, data, 1, 2)
            cond_swap(arr, data, 0, 1)
		case 2: 
			cond_swap(arr, data, 0, 1)
		case 0,1:
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
}

