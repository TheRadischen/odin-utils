package main

MIN_RUN_LEN :: 32  // magic number

// unstable sort
quick_sort :: proc(arr: $A/[]$T) {
    arr := arr
	length := len(arr)
	if length < MIN_RUN_LEN {
        insertion_sort(arr)
		return
	}

	p := arr[length/2]
	l, r := 0, length-1

	loop: for {
		for arr[l] < p { l += 1 }
		for p < arr[r] { r -= 1 }

		if l >= r {
			break loop
		}

		arr[l], arr[r] = arr[r], arr[l]
		l += 1
		r -= 1
	}

	quick_sort(arr[0:l])
	quick_sort(arr[l:length])
}

insertion_sort :: proc(arr: $A/[]$T) {
    for i in 1..<len(arr) {
        x := arr[i]
        j := i
        for ; j > 0 && arr[j - 1] > x; j -= 1 {
            arr[j] = arr[j - 1]
        }
        arr[j] = x
    }
}
quick_sort_cmp :: proc(arr: $A/[]$T, cmp: proc(T, T) -> bool) {
    arr := arr
	length := len(arr)
	if length < MIN_RUN_LEN {
        insertion_sort_cmp(arr, cmp)
		return
	}

	p := arr[length/2]
	l, r := 0, length-1

	loop: for {
		for cmp(arr[l], p) { l += 1 }
		for cmp(p, arr[r]) { r -= 1 }

		if l >= r {
			break loop
		}

		arr[l], arr[r] = arr[r], arr[l]
		l += 1
		r -= 1
	}

	quick_sort_cmp(arr[0:l],ins, cmp)
	quick_sort_cmp(arr[l:length],ins, cmp)
}

insertion_sort_cmp :: proc(arr: $A/[]$T, cmp: proc(T, T) -> bool) {
    for i in 1..<len(arr) {
        x := arr[i]
        j := i
        for ; j > 0 && cmp(x, arr[j - 1]); j -= 1 {
            arr[j] = arr[j - 1]
        }
        arr[j] = x
    }
}