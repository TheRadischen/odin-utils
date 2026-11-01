// #+ignore
package sorting

import "base:intrinsics"

ORD :: intrinsics.type_is_ordered
Ordering :: enum {
	Less = -1,
	Equal = 0,
	Greater = 1,
}



sort_inlined :: proc(arr: $T/[]$E) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			// base_type :: intrinsics.type_core_type(E)
			_quick_lomuto(arr, rawptr(nil), proc(left, right: ^E, data: rawptr, loc := #caller_location) -> bool {
				res := left^ < right^


				when !TEST {
					comps += 1
					append(&array_action, Cmp{
						location(left), location(right), res, loc
					})
				}

				return res
			})
		}
	}
}




@private
_quick_lomuto :: proc(arr: $T/[]$E, data: $D, $LESS: $P) #no_bounds_check {
	loop(arr, data, true, 0)

	SMALL_THRESHOLD  :: 28
	
	loop :: proc(arr: T, data: D, leftmost: bool, unbalanced: int) #no_bounds_check {
		arr := arr; leftmost := leftmost; unbalanced := unbalanced

		for {
			if len(arr) <= SMALL_THRESHOLD {
				when size_of(E) > 100 {
					shell_sort(arr, data)
				} else {
					pingpong(arr, data)
				}
				return
			}

			median_3_depth := log2(len(arr)) / 5
			rand := 0
			if unbalanced >= 3 {
				unbalanced -= 1
				rand = cast(int)intrinsics.read_cycle_counter() & (63 if len(arr) > 2048 else 3)
			}
			
			pivot_index := median_3(arr[rand:], data, 0, len(arr) - 1, median_3_depth)

			if !leftmost {
				if !LESS(&arr[-1], &arr[pivot_index], data) {
					left := partition_lomuto_reverse(arr, data, pivot_index)
					arr = arr[left + 1:]
					leftmost = false
					continue					
				}
			} 

			when size_of(E) > 80 || true {
				left := partition_hoare(arr, data, pivot_index)
			} else {
				left := partition_lomuto(arr, data, pivot_index)
			}
			
			right := len(arr) - left

			if left < right {
				loop(arr[:left], data, leftmost, 0)
				
				if left < right / 32 {
					unbalanced += 1
				}
				arr = arr[left + 1:]
				leftmost = false
			} else {
				loop(arr[left + 1:], data, false, 0)

				if right < left / 32 {
					unbalanced += 1
				}
				arr = arr[:left]
			}
		}
	}



	median_3 :: proc(arr: T, data: D, start, end, depth: int) -> int #no_bounds_check {
		if depth == 0 {
			return start
		}

		div := (end - start) / 3

		swap := [3]int{
			median_3(arr, data, start, start + div, depth - 1),
			median_3(arr, data, start + div, start + div * 2, depth - 1),
			median_3(arr, data, start + div * 2, end, depth - 1),
		}
		
		x := LESS(&arr[swap[0]], &arr[swap[1]], data)
		y := LESS(&arr[swap[0]], &arr[swap[2]], data)
		z := LESS(&arr[swap[1]], &arr[swap[2]], data)

		return swap[(int)(x == y) + (int)(y ~ z)]
	}

	// branchless partitioning
	// [  <  |0|  >=  |  ?  ]
	//	    left      j ->
	partition_lomuto :: proc(arr: T, data: D, pivot_index: int) -> (left: int) #no_bounds_check {
		move(&temp, &arr[pivot_index])
		move(&arr[pivot_index], &arr[0])

		j := 0
		#unroll(4) for _ in arr[:len(arr) - 1] {
			move(&arr[j], &arr[left])
			j += 1
			move(&arr[left], &arr[j])
			left += cast(int)LESS(&arr[left], &temp, data)
		}

		move(&arr[j], &arr[left])
		move(&arr[left], &temp)

		return left
	}

	// [  ?  |  <=  |0|  >  ]
	//   <-  j     right
	partition_lomuto_reverse :: proc(arr: T, data: D, pivot_index: int) -> (right: int) #no_bounds_check {
		right = len(arr) - 1

		move(&temp, &arr[pivot_index])
		move(&arr[pivot_index], &arr[right])

		j := right
		for j >= 1 {
			move(&arr[j], &arr[right])
			j -= 1
			move(&arr[right], &arr[j])
			right -= cast(int)LESS(&temp, &arr[right], data)
		}

		move(&arr[j], &arr[right])
		move(&arr[right], &temp)

		return right
	}

	// only used for large types as it uses less data moves
	// [  <  |0|   ?   |  >=  ]
	//	 ->  left    right <-
	partition_hoare :: proc(arr: T, data: D, pivot_index: int) -> (left: int) #no_bounds_check {
		right := len(arr) - 1

		move(&temp, &arr[pivot_index])
		move(&arr[pivot_index], &arr[0])

		for {
			for !LESS(&arr[right], &temp, data) && left < right { right -= 1 }
			if left >= right {
				move(&arr[left], &temp)
				return left 
			}
			move(&arr[left], &arr[right])
			left += 1

			for LESS(&arr[left], &temp, data) && left < right { left += 1 }
			if left >= right {
				move(&arr[right], &temp)
				left = right
				return left
			}
			move(&arr[right], &arr[left])
			right -= 1
		}
	}

	shell_sort :: proc(arr: T, data: D) #no_bounds_check {
		gaps := []int{23, 10, 4, 1}

		for g in gaps {
			for k := g; k < len(arr); k += 1 {
				if !LESS(&arr[k], &arr[k - g], data) {
					continue
				}
				move(&temp, &arr[k])
				move(&arr[k], &arr[k - g])

				t := k - g
				for t >= g && LESS(&temp, &arr[t - g], data) {
					move(&arr[t], &arr[t - g])
					t -= g
				}
				move(&arr[t], &temp)
			}
		}
	}

	pingpong :: proc(arr: T, data: D) #no_bounds_check {
		if len(arr) <= 7 {
			networks(arr, data)
			return
		} 

		half1 := len(arr) / 2
		quad1 := half1 / 2
		quad2 := half1 - quad1
		half2 := len(arr) - half1
		quad3 := half2 / 2
		quad4 := half2 - quad3

		networks(arr        [:quad1], data)
		networks(arr[quad1:][:quad2], data)
		networks(arr[half1:][:quad3], data)
		networks(arr[half1 + quad3:], data)

		if  !LESS(&arr[quad1],         &arr[quad1 - 1],         data) &&
		    !LESS(&arr[half1],         &arr[half1 - 1],         data) &&
		    !LESS(&arr[half1 + quad3], &arr[half1 + quad3 - 1], data) {
				return
		}

		swap := aux
		parity_merge(swap[:half1], arr[:half1], quad1, quad2, data)
		parity_merge(swap[half1:], arr[half1:], quad3, quad4, data)
		parity_merge(arr,          swap[:],     half1, half2, data)
	}

	parity_merge :: proc(to, from: T, left, right: int, data: D) #no_bounds_check {
		left_low := 0
		left_high := left - 1
		right_low := left
		right_high := left + right - 1
		write_low := 0
		write_high := right_high
		for _ in 0..<left {
			if LESS(&from[right_low], &from[left_low], data) {
				move(&to[write_low], &from[inc(&right_low)])
			} else {
				move(&to[write_low], &from[inc(&left_low)])
			}
			write_low += 1
			if LESS(&from[right_high], &from[left_high], data) {
				move(&to[write_high], &from[dec(&left_high)])
			} else {
				move(&to[write_high], &from[dec(&right_high)])
			}
			write_high -= 1
		}

		if left != right {
			if LESS(&from[right_low], &from[left_low], data) {
				move(&to[write_low], &from[inc(&right_low)])
			} else {
				move(&to[write_low], &from[inc(&left_low)])
			}
		}

	}

	_cond_swap :: #force_inline proc(arr: T, data: D, l, r: int) #no_bounds_check {
		cond_swap(&arr[r], &arr[l])
	}

	networks :: proc(arr: T, data: D) #no_bounds_check {
		switch len(arr) {
		case 7: 
			_cond_swap(arr, data, 0, 6)
			_cond_swap(arr, data, 2, 3)
			_cond_swap(arr, data, 4, 5)
			_cond_swap(arr, data, 0, 2)
			_cond_swap(arr, data, 1, 4)
			_cond_swap(arr, data, 3, 6)
			_cond_swap(arr, data, 0, 1)
			_cond_swap(arr, data, 2, 5)
			_cond_swap(arr, data, 3, 4)
			_cond_swap(arr, data, 1, 2)
			_cond_swap(arr, data, 4, 6)
			_cond_swap(arr, data, 2, 3)
			_cond_swap(arr, data, 4, 5)
			_cond_swap(arr, data, 1, 2)
			_cond_swap(arr, data, 3, 4)
			_cond_swap(arr, data, 5, 6)
		case 6: 
			_cond_swap(arr, data, 0, 5)
			_cond_swap(arr, data, 1, 3)
			_cond_swap(arr, data, 2, 4)
			_cond_swap(arr, data, 1, 2)
			_cond_swap(arr, data, 3, 4)
			_cond_swap(arr, data, 0, 3)
			_cond_swap(arr, data, 2, 5)
			_cond_swap(arr, data, 0, 1)
			_cond_swap(arr, data, 2, 3)
			_cond_swap(arr, data, 4, 5)
			_cond_swap(arr, data, 1, 2)
			_cond_swap(arr, data, 3, 4)
		case 5: 
			_cond_swap(arr, data, 0, 3)
			_cond_swap(arr, data, 1, 4)
			_cond_swap(arr, data, 0, 2)
			_cond_swap(arr, data, 1, 3)
			_cond_swap(arr, data, 0, 1)
			_cond_swap(arr, data, 2, 4)
			_cond_swap(arr, data, 1, 2)
			_cond_swap(arr, data, 3, 4)
			_cond_swap(arr, data, 2, 3)
		case 4: 
			_cond_swap(arr, data, 0, 2)
			_cond_swap(arr, data, 1, 3)
			_cond_swap(arr, data, 0, 1)
			_cond_swap(arr, data, 2, 3)
			_cond_swap(arr, data, 1, 2)
		case 3: 
			_cond_swap(arr, data, 0, 2)
			_cond_swap(arr, data, 0, 1)
			_cond_swap(arr, data, 1, 2)
		case 2: 
			_cond_swap(arr, data, 0, 1)
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
log2 :: proc(n: int) -> (log: int) {
	for n := n; n > 0; n >>= 1 {
		log += 1
	}
	return log
}