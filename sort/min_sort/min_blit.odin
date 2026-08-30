package msort

import "core:slice"
import "base:intrinsics"

/*
	thanks to scandum for blit partitioning
	https://github.com/scandum
*/

BLIT_SWAP :: 512

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		arr := []int{3,2,1}
		sort.sort_stable_stack(arr)
	}
*/
sort_stable_stack :: proc(arr: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			base_type :: intrinsics.type_core_type(E)
			mini_blit(transmute([]base_type)arr, rawptr(nil), proc(l, r: base_type, data: rawptr) -> bool { return l < r })
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
		sort.sort_stable_stack_by(arr, data_less)
	}
*/
sort_stable_stack_by :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			mini_blit(arr, rawptr(nil), proc(l, r: E, data: rawptr) -> bool { return LESS(l, r) })
		}
	}
}

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		arr := []int{3,2,1}
		indices := sort.sort_stable_stack_with_indices(arr)
		// arr = {1,2,3}
		defer delete(indices)
	}
*/
sort_stable_stack_with_indices :: proc(arr: $T/[]$E, allocator := context.allocator) -> (indices: []int) where ORD(E) {
	indices = make([]int, len(arr), allocator)
	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}

			base_type :: intrinsics.type_core_type(E)
			base := transmute([]base_type)arr
			mini_blit(indices, &base, proc(l, r: int, user_data: ^T) -> bool {
				return user_data[l] < user_data[r]
			})
			
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
		arr := make([]Data, 10)
		// fill with data
		sort.sort_stable_stack_by_with_indices(arr, data_less, context.temp_allocator)
		free_all(context.temp_allocator)
	}
*/
sort_stable_stack_by_with_indices :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool, allocator := context.allocator) -> (indices: []int) {
	indices = make([]int, len(arr), allocator)

	when size_of(E) != 0 {
		if len(arr) > 1 {
			for &index, i in indices{
				index = i
			}

			arr := arr
			mini_blit(indices, &arr, proc(l, r: int, user_data: ^T) -> bool {
				return LESS(user_data[l], user_data[r])
			})

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
		arr := make([]Data, 10)
		// fill with data
		sort.sort_stable_stack_by_with_data(data, less_data_modulus, &modulus)
	}
*/
sort_stable_stack_by_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: ^$D) -> bool, user_data: ^D) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			mini_blit(arr, user_data, proc(l, r: E, user_data: ^D) -> bool {
				return LESS(l, r, user_data)
			})
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
		arr := make([]Data, 10)
		// fill with data
		indices := sort.sort_stable_stack_by_with_indices_with_data(data, less_data_modulus, &modulus)
		defer delete(indices)
	}
*/
sort_stable_stack_by_with_indices_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: ^$D) -> bool, user_data: ^D, allocator := context.allocator) -> (indices: []int) {
	indices = make([]int, len(arr), allocator)
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

			mini_blit(indices, ctx, proc(l, r: int, ctx: ^Context) -> bool {
				return LESS(ctx.arr[l], ctx.arr[r], ctx.user_data)
			})

			sort_from_permutation_indices(arr, indices)
		}
	}
	return indices
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is stable
sort_stable_stack_by_cmp :: proc(arr: $T/[]$E, $CMP: proc(l, r: E) -> Ordering) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			mini_blit(arr, rawptr(nil), proc(l, r: E, user_data: rawptr) -> bool { return CMP(l, r) == .Less })
		}
	}
}

// WARNING: each call generates a new quicksort, only use in performance critical path
//
// This sort is stable
sort_stable_stack_by_cmp_with_data :: proc(arr: $T/[]$E, $CMP: proc(l, r: E, user_data: ^$D) -> Ordering, user_data: ^D) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			mini_blit(arr, user_data, proc(l, r: E, user_data: ^D) -> bool {
				return CMP(l, r, user_data) == .Less
			})
		}
	}
}

mini_blit :: proc(arr: $A/[]$T, data: $D, $LESS: $P) {
	if len(arr) <= 64 {
		insertion_sort(arr, data)
		return
	}

	swap : [BLIT_SWAP]T = ---
	loop(arr, swap[:], data, nil, true)

	loop :: proc(arr, swap: A, data: D, last_piv: Maybe(T), leftmost: bool) #no_bounds_check {
		arr := arr; last_piv := last_piv; leftmost := leftmost
		for {
			if len(arr) <= 32 {
				if leftmost {
					insertion_sort(arr, data)
				} else {
					insertion_sort_unguarded(arr, data)
				}
				return
			}

			depth := log2(len(arr)) / 5 
			pivot := med3(arr, data, depth)

			if pivot == last_piv {
				left := partition_reverse(arr, swap, data, pivot)
				arr = arr[left:]
				leftmost = false
				continue
			} 

			left := partition(arr, swap, data, pivot)
			right := len(arr) - left
			// ips(arr[left:], swap, data, pivot)
			// #must_tail ips(arr[:left], swap, data, pivot)			
			if left < right {
				loop(arr[:left], swap, data, pivot, leftmost)
				arr = arr[left:]
				leftmost = false
				last_piv = pivot
			} else {
				loop(arr[left:], swap, data, pivot, false)
				arr = arr[:left]
				last_piv = pivot
			}
		}
	}

	log2 :: proc(n: int) -> (log: int) {
		n := n
		for ; n > 0 ;n >>= 1 {
			log += 1
		}
		return log
	}

	med3 :: proc(arr: A, data: D, depth: int) -> T #no_bounds_check {
		if depth == 0 {
			return arr[0]
		}

		div := len(arr) / 3

		swap := [3]T{
			med3(arr[:div], data, depth - 1), 
			med3(arr[div:][:div], data, depth - 1), 
			med3(arr[div * 2:], data, depth - 1)
		}
		
		x := LESS(swap[0], swap[1], data)
		y := LESS(swap[0], swap[2], data)
		z := LESS(swap[1], swap[2], data)

		return swap[(int)(x == y) + (int)(y ~ z)]
	}

	insertion_sort :: proc(arr: A, data: D) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	insertion_sort_unguarded :: proc(arr: A, data: D) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	partition :: proc(arr, swap: A, data: D, piv: T) -> int #no_bounds_check {

		if len(arr) > BLIT_SWAP {
			half := len(arr) / 2
			left := partition(arr[:half], swap, data, piv)
			right := partition(arr[half:], swap, data, piv)

			slice.rotate_left(arr[left:half + right], half - left)

			return left + right
		}


		less := 0

		#unroll(8) for a, i in arr {
			x := cast(int)LESS(a, piv, data)
			arr[less] = a
			swap[i - less] = a
			less += x
		}

		copy(arr[less:], swap)
		
		return less
	}

	partition_reverse :: proc(arr, swap: A, data: D, piv: T) -> int #no_bounds_check {

		if len(arr) > BLIT_SWAP {
			half := len(arr) / 2
			left := partition_reverse(arr[:half], swap, data, piv)
			right := partition_reverse(arr[half:], swap, data, piv)

			slice.rotate_left(arr[left:half + right], half - left)

			return left + right
		}


		less := 0

		#unroll(8) for a, i in arr {
			x := cast(int)!LESS(piv, a, data)
			arr[less] = a
			swap[i - less] = a
			less += x
		}

		copy(arr[less:], swap)
		
		return less
	}
}

