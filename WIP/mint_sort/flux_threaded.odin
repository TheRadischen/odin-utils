package msort

import "core:fmt"
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
sort_stable_threaded :: proc(arr: $T/[]$E, allocator := context.allocator) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			base_type :: intrinsics.type_core_type(E)
			mini_flux_threaded(transmute([]base_type)arr, rawptr(nil), proc(l, r: base_type, data: rawptr) -> bool { return l < r }, allocator)
		}
	}
}


mini_flux_threaded :: proc(arr: $A/[]$T, data: $D, $LESS: $P, allocator := context.allocator) {
	if len(arr) <= 64 {
		insertion_sort(arr, data)
		return
	}
	// Task_Data :: struct {
	// 	arr: []int,
	// 	swap: []int,
	// 	cur: []int,
	// 	pivot: int,
	// 	less: int, // out
	// }
	swap := make(A, len(arr), allocator)
	// loop(arr, swap, arr, data, nil, true)
	stacked(arr, swap, arr, data)
	delete(swap, allocator)

	MAX_THREADS :: 8

	stacked :: proc(arr, swap, cur: A, data: D) {
		parts := 1
		stack : [MAX_THREADS][3]A
		stack[0] = {arr, swap, cur}
		for parts <= MAX_THREADS / 2 {

			splits := MAX_THREADS / parts

			for i := parts - 1; i >= 0; i -= 1 {

				arr, swap, cur := stack[i][0], stack[i][1], stack[i][2]
				length := len(arr)
				part_length := length / splits

				for i in 0..<splits - 1 {
					
				}

				fmt.println(parts,i,len(cur))
				
				depth := log2(len(cur)) / 5 // + 1
				pivot := med3(cur, data, depth)

				left : int
				if raw_data(arr) == raw_data(cur) {
					left = partition_reverse(arr, swap, cur, data, pivot)
				} else {
					left = partition_reverse_rev(arr, swap, cur, data, pivot)
				}

				// left := partition(arr, swap, cur, data, pivot)
				right := len(cur) - left

				stack[i*2+1] = {arr[left:], swap[left:], swap[left:]}
				stack[i*2] = {arr[:left], swap[:left], arr[:left]}


			}

			parts *= 2
		}
		sum := 0
		for s,i in stack {
			l := len(s[0])
			fmt.println(l)
			sum += l
		}
		fmt.println(sum)
		
		for i := parts - 1; i >= 0; i -= 1 {

			arr, swap, cur := stack[i][0], stack[i][1], stack[i][2]
			loop(arr, swap, cur, data, nil, true)

		}
	}


	loop :: proc(arr, swap, cur: A, data: D, last_piv: Maybe(T), leftmost: bool)  {
		arr := arr; swap := swap; cur := cur; last_piv := last_piv; leftmost := leftmost
		for {
			// if  raw_data(arr) != raw_data(cur) && raw_data(swap) != raw_data(cur) || 
			// 	len(arr) != len(swap) || len(swap) != len(cur) {
			// 		fmt.println(raw_data(arr), raw_data(cur), raw_data(swap), len(arr), len(swap), len(cur))
			// 	panic("not equal")
			// }
			if len(cur) <= 48 {
				length += len(cur)
				if raw_data(arr) != raw_data(cur) {
					// intrinsics.mem_copy_non_overlapping(raw_data(arr), raw_data(cur), len(cur) * size_of(T))
					i := 0
					#reverse for a in cur {
						arr[i] = a
						i += 1
					}

				}

				if leftmost {
					insertion_sort(arr, data)
				} else {
					insertion_sort_unguarded(arr, data)
				}
				return
			}

			depth := log2(len(cur)) / 5 
			pivot := med3(cur, data, depth)

			if pivot == last_piv {
				left : int
				if raw_data(arr) == raw_data(cur) {
					left = partition_reverse(arr, swap, cur, data, pivot)
				} else {
					left = partition_reverse_rev(arr, swap, cur, data, pivot)
				}
				// left := partition_reverse(arr, swap, cur, data, pivot)
				// right := len(arr) - left
				arr = arr[left:]
				cur = swap[left:]
				swap = swap[left:]
				last_piv = nil
				leftmost = false
				continue
			}

			left : int
			if raw_data(arr) == raw_data(cur) {
				left = partition(arr, swap, cur, data, pivot)
			} else {
				left = partition_rev(arr, swap, cur, data, pivot)
			}

			loop(arr[:left], swap[:left], arr[:left], data, nil, leftmost)
			
			arr = arr[left:]
			cur = swap[left:]
			swap = swap[left:]
			last_piv = pivot
			leftmost = false
		}
	}

	log2 :: proc(n: int) -> (log: int) {
		n := n
		for ; n > 0 ;n >>= 1 {
			log += 1
		}
		return log
	}

	med3 :: proc(arr: A, data: D, depth: int) -> T  {
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

	insertion_sort :: proc(arr: A, data: D)  {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	insertion_sort_unguarded :: proc(arr: A, data: D)  {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			#no_bounds_check for ; LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	partition :: proc(arr, swap, cur: A, data: D, piv: T) -> int  {
		less := 0
		swap := swap[len(swap) - 1:]

		#unroll(8) for a,i in cur {
			x := cast(int)LESS(a, piv, data)
			arr[less] = a
			swap[less] = a
			#no_bounds_check swap = swap[-1:]
			less += x

		}
		
		return less
	}

	partition_rev :: proc(arr, swap, cur: A, data: D, piv: T) -> int  {
		less := 0
		swap := swap[len(swap) - 1:]

		#reverse for a, i in cur {
			x := cast(int)LESS(a, piv, data)
			arr[less] = a
			swap[less] = a
			#no_bounds_check swap = swap[-1:]
			less += x
		}
		
		return less
	}

	partition_reverse :: proc(arr, swap, cur: A, data: D, piv: T) -> int  {
		less_equal := 0
		swap := swap[len(swap) - 1:]

		#unroll(8) for a in cur {
			x := cast(int)!LESS(piv, a, data)
			arr[less_equal] = a
			swap[less_equal] = a
			#no_bounds_check swap = swap[-1:]
			less_equal += x
		}
		
		return less_equal
	}

	partition_reverse_rev :: proc(arr, swap, cur: A, data: D, piv: T) -> int  {
		less_equal := 0
		swap := swap[len(swap) - 1:]

		#reverse for a in cur {
			x := cast(int)!LESS(piv, a, data)
			arr[less_equal] = a
			swap[less_equal] = a
			#no_bounds_check swap = swap[-1:]
			less_equal += x
		}
		
		return less_equal
	}
}

