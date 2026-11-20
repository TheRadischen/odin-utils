package test

import "core:sort"

Interface :: sort.Interface
_insertion_sort :: proc(it: Interface, a, b: int) {
	for i in a+1..<b {
		for j := i; j > a && it->less(j, j-1); j -= 1 {
			it->swap(j, j-1)
		}
	}
}

_merge_rotate :: proc(it: Interface, a, b: int) {
	if b - a < 32 {
		_insertion_sort(it, a, b)
		return
	}
		
	mid := int(uint(a + b) / 2)
	_merge_rotate(it, a, mid)
	_merge_rotate(it, mid, b)

	inplace_merge(it, a, mid, b)
}

inplace_merge_insertion :: proc(it: Interface, a, m, b: int) {
    n := b - a
	right := b - m
	left := m - a
    l := 0
    r := left

	for l < left && right < n {
        if !it->less(r, l) {
            l += 1
            continue
        } else {
            for s := r; s > l; s -= 1 {
				it->swap(s, s-1)
            }
            r += 1
        }
	}
}

// inplace_merge_insertion2 :: proc(arr: []int, left: int) {
//     n := len(arr)
// 	right := n - left
//     l := 0
//     r := left

// 	for l < left && right < n {
//         if !less(&arr[r], &arr[l]) {
//             l += 1
//             continue
//         } else {
//             for s := r; s > l; s -= 1 {
//                 swap(&arr[s], &arr[s-1])
//             }
//             r += 1
//         }
// 	}
// }

_inplace_merge :: proc(it: Interface, a, mid, b: int) {
    left := mid - a
    right := b - mid
	if left == 0 || right == 0 {
		return
	}

	if left + right < 20 {
		inplace_merge_insertion(it, a, mid, b)
		return
	}

	left_cut, right_cut: int
	if left < right {
		right_cut = mid + right / 2

        start := a
        end := mid

		for start < end {
			mid := int(uint(start + end) / 2)

            if it->less(mid, right_cut) {
                start = mid + 1
            } else {
                end  = mid
            }
		}
	} else {
		left_cut = a + left / 2

        start := mid
        end := b

		for start < end {
			mid := int(uint(start + end) / 2)

            if !it->less(right_cut, mid) {
                start = mid + 1
            } else {
                end  = mid
            }
		}
	}

	// rotate(arr[left_cut:left + right_cut], left - left_cut)
	rotate(it, left_cut, mid, right_cut)
	// rotate(arr[left_cut:left + right_cut], left - left_cut)

	// new_mid := left_cut + right_cut
	// inplace_merge(arr[:mid], left_cut)
	// inplace_merge(arr[mid:], left - left_cut)

	new_mid := left_cut + right_cut - mid
	inplace_merge(it, a, left_cut,  new_mid)
	inplace_merge(it, new_mid, right_cut, b)
}
_bin_insertion_sort :: proc(it: Interface, a, b: int, presorted: int = 1) {
	for i in a+presorted..<b {

        start := a
        end := i

		for start < end {
			mid := int(uint(start + end) / 2)

            if it->less(mid, i) {
                start = mid + 1
            } else {
                end  = mid
            }
		}

		for j := i; j > start; j -= 1 {
			it->swap(j, j-1)
		}
	}
}
swap_range :: sort.swap_range
rotate :: proc(it: Interface, a, m, b: int) {
	i := m - a
	j := b - m

    if i <= 0 || j <= 0 { return }

	for i != j {
		if i > j {
			swap_range(it, m-i, m, j)
			i -= j
		} else {
			swap_range(it, m-i, m+j-i, i)
			j -= i
		}
	}
	swap_range(it, m-i, m, i)
}

rotate2 :: proc(it: Interface, a, m, b: int) {
	l := m - a
	r := b - m
    a := a
    m := m
    b := b

	for l > 0 && r > 0 {
		if r < l {
			swap_range(it, m-r, m, r)
			b -= r
            m -= r
            l -= r
		} else {
			swap_range(it, a, m, l)
			a += l
            m += l
            r -= l
		}
	}
}

