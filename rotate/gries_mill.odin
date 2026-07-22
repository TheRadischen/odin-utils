package basic


import "core:slice"
import "base:runtime"


rotate_left :: proc "contextless" (array: $T/[]$E, mid: int) {
	if len(array) <= 0 {
		return
	}
	n := len(array)
	m := mid %% n
	k := n - m

	// FIXME: (ap29600) this cast is a temporary fix for the compiler not matching
	// [^T] with $P/^$T
	p := cast(^E)raw_data(array)
	ptr_rotate(m, slice.ptr_add(p, m), k)
}
rotate_right ::  proc  "contextless" (array: $T/[]$E, k: int) {
	rotate_left(array, -k)
}


ptr_rotate :: proc  "contextless"  (left: int, mid: ^$T, right: int) {
	when size_of(T) != 0 {
		left, mid, right := left, mid, right

		SWAP :: 256

		for left * size_of(T) > SWAP && right * size_of(T)  > SWAP {
			if left >= right {
				for {
					slice.ptr_swap_non_overlapping(slice.ptr_sub(mid, right), mid, right * size_of(T))
					mid = slice.ptr_sub(mid, right)

					left -= right
					if left < right {
						break
					}
				}
			} else {
				for {
					slice.ptr_swap_non_overlapping(slice.ptr_sub(mid, left), mid, left * size_of(T))
					mid = slice.ptr_add(mid, left)

					right -= left
					if right < left {
						break
					}
				}
			}
		}
		
		swap : [SWAP]byte = ---
		start := slice.ptr_sub(mid, left)
		end := slice.ptr_add(start, right)

		if left <= right {
			runtime.mem_copy(&swap, start, left * size_of(T))
			runtime.mem_copy(start, mid, right * size_of(T))
			runtime.mem_copy(end, &swap, left * size_of(T))
		} else {
			runtime.mem_copy(&swap, mid, right * size_of(T))
			runtime.mem_copy(end, start, left * size_of(T))
			runtime.mem_copy(start, &swap, right * size_of(T))
		}
	}
}
