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
	indices = make([]int, len(arr), allocator)
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
		arr := make([]Data, 10)
		// fill with data
		sort.sort_stable_by_with_indices(arr, data_less, context.temp_allocator)
		free_all(context.temp_allocator)
	}
*/
sort_stable_by_with_indices :: proc(arr: $T/[]$E, $LESS: proc(l, r: E) -> bool, allocator := context.allocator) -> (indices: []int) {
	indices = make([]int, len(arr), allocator)

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
		arr := make([]Data, 10)
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
		arr := make([]Data, 10)
		// fill with data
		indices := sort.sort_stable_by_with_indices_with_data(data, less_data_modulus, &modulus)
		defer delete(indices)
	}
*/
sort_stable_by_with_indices_with_data :: proc(arr: $T/[]$E, $LESS: proc(l, r: E, user_data: ^$D) -> bool, user_data: ^D, allocator := context.allocator) -> (indices: []int) {
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
	if len(arr) <= 64 {
		insertion_sort(arr, data)
		return
	}

	swap := make(A, len(arr), allocator)
	loop(arr, swap, arr, data, nil, true)
	delete(swap, allocator)

	loop :: proc(arr, swap, cur: A, data: D, last_piv: Maybe(T), leftmost: bool) #no_bounds_check {
		arr := arr; cur := cur; last_piv := last_piv; leftmost := leftmost
		for {
			if len(arr) <= 48 {
				if raw_data(arr) != raw_data(cur) {
					copy(arr, cur)
				}

				if leftmost {
					insertion_sort(arr, data)
				} else {
					insertion_sort_unguarded(arr, data)
				}
				return
			}

			depth := log2(len(arr)) / 5 
			pivot := med3(cur, data, depth)

			if pivot == last_piv {
				left := partition_reverse(arr, swap, cur, data, pivot)
				right := len(arr) - left
				arr = arr[left:]
				cur = swap[:right]
				last_piv = nil
				leftmost = false
				continue
			}

			left := partition(arr, swap, cur, data, pivot)
			right := len(arr) - left

			loop(arr[left:], swap, swap[:right], data, pivot, false)
			arr = arr[:left]
			cur = arr[:left]
			last_piv = nil
			leftmost = leftmost
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
}

