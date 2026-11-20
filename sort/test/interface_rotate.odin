merge_rotate :: proc(it: Interface, a, b: int) {
	if b - a < 16 {
		_insertion_sort(it, a, b)
		return
	}
		
	mid := int(uint(a + b) / 2)
	merge_rotate(arr, a, mid)
	merge_rotate(arr, mid, b)

	inplace_merge(arr, a, mid, b)
}
inplace_merge :: proc(it: Interface, a, mid, b: int) {
    left := mid - a
    right := b - mid
	if left == 0 || right == 0 {
		return
	}

	if left + right == 2 {
		if it->less(right, left) {
            if->swap(right, left)
        }
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
	rotate(arr, left_cut, mid, right_cut)
	// rotate(arr[left_cut:left + right_cut], left - left_cut)

	// new_mid := left_cut + right_cut
	// inplace_merge(arr[:mid], left_cut)
	// inplace_merge(arr[mid:], left - left_cut)

	new_mid := left_cut + right_cut - mid
	inplace_merge(arr, a, new_mid)
	inplace_merge(arr, new_mid, b)
}

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
			j -= 1
		}
	}
	swap_range(it, m-i, m, i)
}
