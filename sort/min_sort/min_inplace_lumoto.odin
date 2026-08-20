package msort


import "base:intrinsics"


sort_inplace :: proc(arr: $A/[]$T) 
	where intrinsics.type_is_ordered(T) {
	quick_lumoto(arr, nil, proc(l, r :T, data: rawptr) -> bool{return l < r})
}

sort_inplace_by :: proc(arr: $A/[]$T, $CMP: proc(T,T) -> bool) {
    quick_lumoto(arr, nil, proc(l, r: T, data: rawptr) -> bool {return CMP(l, r)})
}

quick_lumoto :: proc(arr: $A/[]$T, data: rawptr, $CMP: $P) {
	loop(arr, data, 0)
	
	loop :: proc(arr: A, data: rawptr, last_piv: int) #no_bounds_check {
		if len(arr) <= 32 {
			insertion_sort(arr, data)
			return
		}
		
		depth := log2(len(arr)) / 5
		pivot_index := median_3(arr, data, 0, len(arr) - 1, depth)

		if last_piv != 0 && arr[pivot_index] == arr[last_piv] {
			left := partition_lumoto_reverse(arr, data, pivot_index)
			loop(arr[left + 1:], data, 0)
			return
		} 

		when size_of(T) > 80 {
			left := prtition_hoare(arr, data, pivot_index)
		} else {
			left := partition_lumoto(arr, data, pivot_index)
		}
		
		right := len(arr) - left

		if left < right {
			loop(arr[:left], data, left)
			#must_tail loop(arr[left + 1:], data, -1)
			return
		} else {
			loop(arr[left + 1:], data, -1)
			#must_tail loop(arr[:left], data, left)
			return
		}
	}

	log2 :: proc(n: int) -> (log: int) {
		for n := n; n > 0; n >>= 1 {
			log += 1
		}
		return
	}

	median_3 :: proc(arr: A, data: rawptr, start, end, depth: int) -> int #no_bounds_check {
		if depth == 0 {
			return start
		}

		div := (end - start) / 3

		swap := [3]int{
			median_3(arr, data, start, start + div, depth - 1),
			median_3(arr, data, start + div, start + div * 2, depth - 1),
			median_3(arr, data, start + div * 2, end, depth - 1),
		}
		
		x := CMP(arr[swap[0]], arr[swap[1]], data)
		y := CMP(arr[swap[0]], arr[swap[2]], data)
		z := CMP(arr[swap[1]], arr[swap[2]], data)

		return swap[(int)(x == y) + (int)(y ~ z)]
	}

	insertion_sort :: #force_inline proc(arr: A, data: rawptr) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && CMP(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	partition_lumoto :: #force_no_inline proc(arr: A, data: rawptr, pivot_index: int) -> (left: int) #no_bounds_check {
		pivot := arr[pivot_index]
		arr[pivot_index] = arr[0]

		j := 0
		#unroll(8) for _ in arr[:len(arr) - 1] {
			arr[j] = arr[left]
			j += 1
			arr[left] = arr[j]
			left += cast(int)CMP(arr[left], pivot, data)
		}

		arr[j] = arr[left]
		arr[left] = pivot

		return
	}

	partition_lumoto_reverse :: proc(arr: A, data: rawptr, pivot_index: int) -> (right: int) #no_bounds_check {
		pivot := arr[pivot_index]
		arr[pivot_index] = arr[len(arr) - 1]

		right = len(arr) - 1
		j := right
		for j >= 1 {
			arr[j] = arr[right]
			j -= 1
			arr[right] = arr[j]
			right -= cast(int)CMP(pivot, arr[right], data)
		}

		arr[j] = arr[right]
		arr[right] = pivot

		return
	}

	prtition_hoare :: proc(arr: A, data: rawptr, pivot_index: int) -> (left: int) #no_bounds_check {
		right := len(arr) - 1

		pivot := arr[pivot_index]
		arr[pivot_index] = arr[0]

		for {
			for !CMP(arr[right], pivot, data) && left < right {right -= 1}
			if left >= right {
				arr[left] = pivot
				return left 
			}
			arr[left] = arr[right]
			left += 1

			for CMP(arr[left], pivot, data) && left < right {left += 1}
			if left >= right {
				arr[right] = pivot
				left = right
				return  
			}
			arr[right] = arr[left]
			right -= 1
		}
	}
}

