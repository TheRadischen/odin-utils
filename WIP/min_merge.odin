package msort

import "core:fmt"

min_merge :: proc(arr: []int) {

}

// cond_swap :: proc(arr: []int, l, r: int) {
// 	if arr[l] > arr[r] {
// 		arr[l], arr[r] = arr[r], arr[l]
// 	}
// }
@export
branchless_swap_dist2 :: #force_inline proc(arr: []int, l,r: int) #no_bounds_check {
    x := cast(int)(arr[l] > arr[r]) * (r - l)
	arr[l], arr[r] = arr[x + l], arr[r-x]
}
@export
sort4_network :: proc(arr: []int) {
	cond_swap(arr,0,2)
	cond_swap(arr,1,3)
	cond_swap(arr,0,1)
	cond_swap(arr,2,3)
	cond_swap(arr,1,2)
}
cond_swap :: branchless_swap_dist2

cond_swap :: branchless_swap_dist2

smallsort :: proc(arr: []int) {
	assert(len(arr) <= 512)

	swap : []int = 512
	n := len(arr)

	ptr := 0
	for ; ptr < n; ptr += 8 {
		sort8_network(small[ptr:])
	}
	insertion_sort(small[ptr:])

	cur := arr
	block := 8
	for block < n {
		from := cur
		to := swap
		for ; ptr < n; ptr += block * 2 {
			defer {
				from = from[block:]
				to = to[block:]
			}
			if from[block - 1] < from[block] {
				continue
			}
			if from[0] > from[block * 2 - 1] {
				copy(to, from[block:][:block])
				copy(to[block:], from[:block])
				continue
			}
			parity(swap[ptr:], to[ptr:], block, block)
		}
		// go knows where anything is, doing this in 4 blocks like quadsort is easier
		if len(to) > block {
			parity(swap[ptr:], to[ptr:], block)
		}
		swap, cur = cur, swap
		block *= 2
	}
	parity(swap, cur, block)
}


sort_8x2 :: proc(arr: []int) {
	sort8_network(arr[:8])
	sort8_network(arr[8:])
	swap : [16]int  = ---
	parity(swap[:], arr, 16)
	copy(arr, swap[:])
}
sort_16x2 :: proc(arr: []int) {
	sort16_network(arr[:16])
	sort16_network(arr[16:])
	swap : [32]int  = ---
	parity(swap[:], arr, 32)
	copy(arr, swap[:])
}
sort_4x4x2 :: proc(arr: []int) {
	sort_4x4(arr[:16])
	sort_4x4(arr[16:])
	swap : [32]int  = ---
	parity(swap[:], arr, 32)
	copy(arr, swap[:])
	// fmt.println(arr)
}
sort_8x4 :: proc(arr: []int) {
	sort8_network(arr[:8])
	sort8_network(arr[8:][:8])
	sort8_network(arr[16:][:8])
	sort8_network(arr[24:])
	swap : [32]int  = ---
	parity(swap[:], arr, 16)
	parity(swap[16:], arr[16:], 16)
	parity(arr, swap[:], 32)
}
sort_32x4 :: proc(arr: []int) {
	N :: 32
	sort_8x4(arr[:N])
	sort_8x4(arr[N:][:N])
	sort_8x4(arr[N * 2:][:N])
	sort_8x4(arr[N * 3:])
	swap : [N * 4]int  = ---
	parity(swap[:], arr, N * 2)
	parity(swap[N * 2:], arr[N * 2:], N * 2)
	parity(arr, swap[:], N * 4)
}
sort_128x4 :: proc(arr: []int) {
	N :: 128
	sort_32x4(arr[:N])
	sort_32x4(arr[N:][:N])
	sort_32x4(arr[N * 2:][:N])
	sort_32x4(arr[N * 3:])
	swap : [N * 4]int  = ---
	parity(swap[:], arr, N * 2)
	parity(swap[N * 2:], arr[N * 2:], N * 2)
	parity(arr, swap[:], N * 4)
}
sort_4x4 :: proc(arr: []int) {
	sort4_network(arr[:4])
	sort4_network(arr[4:][:4])
	sort4_network(arr[8:][:4])
	sort4_network(arr[12:])
	swap : [16]int = ---
	parity(swap[:], arr, 8)
	parity(swap[8:], arr[8:], 8)
	parity(arr, swap[:], 16)
}

sort32_network :: proc(arr: []int) {
	cond_swap(arr,0,1)
	cond_swap(arr,2,3)
	cond_swap(arr,4,5)
	cond_swap(arr,6,7)
	cond_swap(arr,8,9)
	cond_swap(arr,10,11)
	cond_swap(arr,12,13)
	cond_swap(arr,14,15)
	cond_swap(arr,16,17)
	cond_swap(arr,18,19)
	cond_swap(arr,20,21)
	cond_swap(arr,22,23)
	cond_swap(arr,24,25)
	cond_swap(arr,26,27)
	cond_swap(arr,28,29)
	cond_swap(arr,30,31)
	cond_swap(arr,0,2)
	cond_swap(arr,1,3)
	cond_swap(arr,4,6)
	cond_swap(arr,5,7)
	cond_swap(arr,8,10)
	cond_swap(arr,9,11)
	cond_swap(arr,12,14)
	cond_swap(arr,13,15)
	cond_swap(arr,16,18)
	cond_swap(arr,17,19)
	cond_swap(arr,20,22)
	cond_swap(arr,21,23)
	cond_swap(arr,24,26)
	cond_swap(arr,25,27)
	cond_swap(arr,28,30)
	cond_swap(arr,29,31)
	cond_swap(arr,0,4)
	cond_swap(arr,1,5)
	cond_swap(arr,2,6)
	cond_swap(arr,3,7)
	cond_swap(arr,8,12)
	cond_swap(arr,9,13)
	cond_swap(arr,10,14)
	cond_swap(arr,11,15)
	cond_swap(arr,16,20)
	cond_swap(arr,17,21)
	cond_swap(arr,18,22)
	cond_swap(arr,19,23)
	cond_swap(arr,24,28)
	cond_swap(arr,25,29)
	cond_swap(arr,26,30)
	cond_swap(arr,27,31)
	cond_swap(arr,0,8)
	cond_swap(arr,1,9)
	cond_swap(arr,2,10)
	cond_swap(arr,3,11)
	cond_swap(arr,4,12)
	cond_swap(arr,5,13)
	cond_swap(arr,6,14)
	cond_swap(arr,7,15)
	cond_swap(arr,16,24)
	cond_swap(arr,17,25)
	cond_swap(arr,18,26)
	cond_swap(arr,19,27)
	cond_swap(arr,20,28)
	cond_swap(arr,21,29)
	cond_swap(arr,22,30)
	cond_swap(arr,23,31)
	cond_swap(arr,0,16)
	cond_swap(arr,1,8)
	cond_swap(arr,2,4)
	cond_swap(arr,3,12)
	cond_swap(arr,5,10)
	cond_swap(arr,6,9)
	cond_swap(arr,7,14)
	cond_swap(arr,11,13)
	cond_swap(arr,15,31)
	cond_swap(arr,17,24)
	cond_swap(arr,18,20)
	cond_swap(arr,19,28)
	cond_swap(arr,21,26)
	cond_swap(arr,22,25)
	cond_swap(arr,23,30)
	cond_swap(arr,27,29)
	cond_swap(arr,1,2)
	cond_swap(arr,3,5)
	cond_swap(arr,4,8)
	cond_swap(arr,6,22)
	cond_swap(arr,7,11)
	cond_swap(arr,9,25)
	cond_swap(arr,10,12)
	cond_swap(arr,13,14)
	cond_swap(arr,17,18)
	cond_swap(arr,19,21)
	cond_swap(arr,20,24)
	cond_swap(arr,23,27)
	cond_swap(arr,26,28)
	cond_swap(arr,29,30)
	cond_swap(arr,1,17)
	cond_swap(arr,2,18)
	cond_swap(arr,3,19)
	cond_swap(arr,4,20)
	cond_swap(arr,5,10)
	cond_swap(arr,7,23)
	cond_swap(arr,8,24)
	cond_swap(arr,11,27)
	cond_swap(arr,12,28)
	cond_swap(arr,13,29)
	cond_swap(arr,14,30)
	cond_swap(arr,21,26)
	cond_swap(arr,3,17)
	cond_swap(arr,4,16)
	cond_swap(arr,5,21)
	cond_swap(arr,6,18)
	cond_swap(arr,7,9)
	cond_swap(arr,8,20)
	cond_swap(arr,10,26)
	cond_swap(arr,11,23)
	cond_swap(arr,13,25)
	cond_swap(arr,14,28)
	cond_swap(arr,15,27)
	cond_swap(arr,22,24)
	cond_swap(arr,1,4)
	cond_swap(arr,3,8)
	cond_swap(arr,5,16)
	cond_swap(arr,7,17)
	cond_swap(arr,9,21)
	cond_swap(arr,10,22)
	cond_swap(arr,11,19)
	cond_swap(arr,12,20)
	cond_swap(arr,14,24)
	cond_swap(arr,15,26)
	cond_swap(arr,23,28)
	cond_swap(arr,27,30)
	cond_swap(arr,2,5)
	cond_swap(arr,7,8)
	cond_swap(arr,9,18)
	cond_swap(arr,11,17)
	cond_swap(arr,12,16)
	cond_swap(arr,13,22)
	cond_swap(arr,14,20)
	cond_swap(arr,15,19)
	cond_swap(arr,23,24)
	cond_swap(arr,26,29)
	cond_swap(arr,2,4)
	cond_swap(arr,6,12)
	cond_swap(arr,9,16)
	cond_swap(arr,10,11)
	cond_swap(arr,13,17)
	cond_swap(arr,14,18)
	cond_swap(arr,15,22)
	cond_swap(arr,19,25)
	cond_swap(arr,20,21)
	cond_swap(arr,27,29)
	cond_swap(arr,5,6)
	cond_swap(arr,8,12)
	cond_swap(arr,9,10)
	cond_swap(arr,11,13)
	cond_swap(arr,14,16)
	cond_swap(arr,15,17)
	cond_swap(arr,18,20)
	cond_swap(arr,19,23)
	cond_swap(arr,21,22)
	cond_swap(arr,25,26)
	cond_swap(arr,3,5)
	cond_swap(arr,6,7)
	cond_swap(arr,8,9)
	cond_swap(arr,10,12)
	cond_swap(arr,11,14)
	cond_swap(arr,13,16)
	cond_swap(arr,15,18)
	cond_swap(arr,17,20)
	cond_swap(arr,19,21)
	cond_swap(arr,22,23)
	cond_swap(arr,24,25)
	cond_swap(arr,26,28)
	cond_swap(arr,3,4)
	cond_swap(arr,5,6)
	cond_swap(arr,7,8)
	cond_swap(arr,9,10)
	cond_swap(arr,11,12)
	cond_swap(arr,13,14)
	cond_swap(arr,15,16)
	cond_swap(arr,17,18)
	cond_swap(arr,19,20)
	cond_swap(arr,21,22)
	cond_swap(arr,23,24)
	cond_swap(arr,25,26)
	cond_swap(arr,27,28)
}

sort16_network :: proc(arr: []int) {
    cond_swap(arr,0,13)
    cond_swap(arr,1,12)
    cond_swap(arr,2,15)
    cond_swap(arr,3,14)
    cond_swap(arr,4,8)
    cond_swap(arr,5,6)
    cond_swap(arr,7,11)
    cond_swap(arr,9,10)

	cond_swap(arr,0,5)
	cond_swap(arr,1,7)
	cond_swap(arr,2,9)
	cond_swap(arr,3,4)
	cond_swap(arr,6,13)
	cond_swap(arr,8,14)
	cond_swap(arr,10,15)
	cond_swap(arr,11,12)
	cond_swap(arr,0,1)
	cond_swap(arr,2,3)
	cond_swap(arr,4,5)
	cond_swap(arr,6,8)
	cond_swap(arr,7,9)
	cond_swap(arr,10,11)
	cond_swap(arr,12,13)
	cond_swap(arr,14,15)
	cond_swap(arr,0,2)
	cond_swap(arr,1,3)
	cond_swap(arr,4,10)
	cond_swap(arr,5,11)
	cond_swap(arr,6,7)
	cond_swap(arr,8,9)
	cond_swap(arr,12,14)
	cond_swap(arr,13,15)
	cond_swap(arr,1,2)
	cond_swap(arr,3,12)
	cond_swap(arr,4,6)
	cond_swap(arr,5,7)
	cond_swap(arr,8,10)
	cond_swap(arr,9,11)
	cond_swap(arr,13,14)
	cond_swap(arr,1,4)
	cond_swap(arr,2,6)
	cond_swap(arr,5,8)
	cond_swap(arr,7,10)
	cond_swap(arr,9,13)
	cond_swap(arr,11,14)
	cond_swap(arr,2,4)
	cond_swap(arr,3,6)
	cond_swap(arr,9,12)
	cond_swap(arr,11,13)
	cond_swap(arr,3,5)
	cond_swap(arr,6,8)
	cond_swap(arr,7,9)
	cond_swap(arr,10,12)
	cond_swap(arr,3,4)
	cond_swap(arr,5,6)
	cond_swap(arr,7,8)
	cond_swap(arr,9,10)
	cond_swap(arr,11,12)
	cond_swap(arr,6,7)
	cond_swap(arr,8,9)
}

sort8_network :: proc(arr: []int) {
	cond_swap(arr,0,2)
	cond_swap(arr,1,3)
	cond_swap(arr,4,6)
	cond_swap(arr,5,7)
	cond_swap(arr,0,4)
	cond_swap(arr,1,5)
	cond_swap(arr,2,6)
	cond_swap(arr,3,7)
	cond_swap(arr,0,1)
	cond_swap(arr,2,3)
	cond_swap(arr,4,5)
	cond_swap(arr,6,7)
	cond_swap(arr,2,4)
	cond_swap(arr,3,5)
	cond_swap(arr,1,4)
	cond_swap(arr,3,6)
	cond_swap(arr,1,2)
	cond_swap(arr,5,6)
	cond_swap(arr,3,4)
}
sort4_network :: proc(arr: []int) {
	cond_swap(arr,0,2)
	cond_swap(arr,1,3)
	cond_swap(arr,0,1)
	cond_swap(arr,2,3)
	cond_swap(arr,1,2)
}
@export
branchless_swap ::  proc(arr: []int) #no_bounds_check {
    x := cast(int)(arr[0] > arr[1])
	arr[0], arr[1] = arr[x], arr[1-x]
}

@export
branchless_swap_dist ::  proc(arr: []int, dist: int) #no_bounds_check {
    x := cast(int)(arr[0] > arr[dist]) * dist
	arr[0], arr[dist] = arr[x], arr[dist-x]
}

@export
branchless_swap_dist2 ::  proc(arr: []int, l,r: int) #no_bounds_check {
    x := cast(int)(arr[l] > arr[r]) * (r - l)
	arr[l], arr[r] = arr[x + l], arr[r-x]
}

@export
branchless_swap_dist_swap ::  proc(arr, swap: []int, dist: int) #no_bounds_check {
    x := cast(int)(arr[0] > arr[dist]) * dist
	swap[0] = arr[x]
	swap[dist] = arr[dist-x]
}

parity_const :: proc(dest, from: []int, $SIZE: int) {
	HALF :: SIZE / 2
	if from[0] > from[SIZE - 1] {
		copy(dest[HALF:], from[:HALF])
		copy(dest[:HALF], from[HALF:])
		return
	}
	write_low := 0
	write_high := SIZE - 1

	read1_low := 0
	read1_high := HALF - 1
	read2_low := HALF
	read2_high := SIZE - 1

	for i in 0..<HALF {
		dest[i] = from[inc(&read1_low)] if from[read1_low] <= from[read2_low] else from[inc(&read2_low)]
		dest[SIZE - 1 - i] = from[dec(&read1_high)] if from[read1_high] > from[read2_high] else from[dec(&read2_high)]
	}
}

parity2 :: proc(dest, from: []int, SIZE: int) {
	HALF := SIZE / 2

	write_low := 0
	write_high := SIZE - 1

	read1_low := 0
	read1_high := HALF - 1
	read2_low := HALF
	read2_high := SIZE - 1

	dest[inc(&write_low)] = from[inc(&read1_low)] if from[read1_low] <= from[read2_low] else from[inc(&read2_low)]
	for i in 0..<HALF - 1 {
		dest[inc(&write_low)] = from[inc(&read1_low)] if from[read1_low] <= from[read2_low] else from[inc(&read2_low)]
		dest[dec(&write_high)] = from[dec(&read1_high)] if from[read1_high] > from[read2_high] else from[dec(&read2_high)]
	}
	dest[write_high] = from[read1_high] if from[read1_high] > from[read2_high] else from[read2_high]
}


parity :: proc(dest, from: []int, left, right: int) {
	size := left + right
	half := size / 2

	write_low := 0
	write_high := size - 1

	read1_low := 0
	read1_high := left - 1
	read2_low := left
	read2_high := size - 1

	if size %% 2 == 1 {
		dest[inc(&write_low)] = from[inc(&read1_low)] if from[read1_low] <= from[read2_low] else from[inc(&read2_low)]
	}

	dest[inc(&write_low)] = from[inc(&read1_low)] if from[read1_low] <= from[read2_low] else from[inc(&read2_low)]
	for i in 0..<HALF - 1 {
		dest[inc(&write_low)] = from[inc(&read1_low)] if from[read1_low] <= from[read2_low] else from[inc(&read2_low)]
		dest[dec(&write_high)] = from[dec(&read1_high)] if from[read1_high] > from[read2_high] else from[dec(&read2_high)]
	}
	dest[write_high] = from[read1_high] if from[read1_high] > from[read2_high] else from[read2_high]
}

inc :: proc(i: ^int) -> int {
	defer i^ += 1
	return i^
}
dec :: proc(i: ^int) -> int {
	defer i^ -= 1
	return i^
}

parity_merge :: proc(dest, from: $A, left, right: int, greater: proc($T,T) -> bool){
    dest := dest; from := from
    
    ptl := 0
    ptr := left
    ptd := 0 
    tpl := ptr - 1
    tpr := tpl + right
    tpd := left + right - 1

    if left < right {
        dest[ptd] = !greater(from[ptl],from[ptr]) ? pp(from, &ptl, T) : pp(from, &ptr, T); ptd += 1    
    }
    dest[ptd] = !greater(from[ptl],from[ptr]) ? pp(from, &ptl, T) : pp(from, &ptr, T); ptd += 1

    for left := left - 1; left > 0; left -= 1 {
        dest[ptd] = !greater(from[ptl],from[ptr]) ? pp(from, &ptl, T) : pp(from, &ptr, T); ptd += 1
        dest[tpd] = greater(from[tpl],from[tpr]) ? nn(from, &tpl, T) : nn(from, &tpr, T); tpd -= 1
    }
    
    dest[tpd] = greater(from[tpl],from[tpr]) ? from[tpl] : from[tpr]
}

/*

cond_swap(arr,0,2)
cond_swap(arr,1,3)
cond_swap(arr,4,6)
cond_swap(arr,5,7)
cond_swap(arr,0,4)
cond_swap(arr,1,5)
cond_swap(arr,2,6)
cond_swap(arr,3,7)
cond_swap(arr,0,1)
cond_swap(arr,2,3)
cond_swap(arr,4,5)
cond_swap(arr,6,7)
cond_swap(arr,2,4)
cond_swap(arr,3,5)
cond_swap(arr,1,4)
cond_swap(arr,3,6)
cond_swap(arr,1,2)
cond_swap(arr,5,6)
cond_swap(arr,3,4)

*/