package sorting

import "base:intrinsics"
import "core:slice"
import "core:sort"
import "core:fmt"
import "core:testing"

arr: []int
aux: []int
temp: int

merge_oop := merge_procs[selected_merge]

stupid_sort :: proc(arr: []int) {
	for i in 0..<len(arr) {
		for j in 0..<len(arr) {
			cond_swap(&arr[i], &arr[j])
		}
	}
}
selection_optimized_sort :: proc(arr: []int) {
	for i in 0..<len(arr) {
		min := i
		for j in i + 1..<len(arr) {
			if less(&arr[j], &arr[min]) {
				min = j
			}
		}
		swap(&arr[i], &arr[min])
	}
}
selection_sort :: proc(arr: []int) {
	for i in 0..<len(arr) {
		for j in i + 1..<len(arr) {
			cond_swap(&arr[j], &arr[i])
		}
	}
}
selection_double :: proc(arr: []int) {
	for i in 0..<len(arr) / 2 {
		min := i
		max := len(arr) - i - 1
		mark(min)
		mark(max)

		for j in i..<len(arr) - i {
			if less(&arr[j], &arr[min]) {
				min = j
			} else if less(&arr[max], &arr[j]) {
				max = j
			}
		}
		if i == max {
			if len(arr) - i - 1 == min {
				swap(&arr[max], &arr[min])
			} else {
				swap(&arr[len(arr) - i - 1], &arr[max])
				swap(&arr[i], &arr[min])
			}
		} else {
			swap(&arr[i], &arr[min])
			swap(&arr[len(arr) - i - 1], &arr[max])
		}
	}
}

poplar_sort :: proc(arr: []int) {
	n := len(arr)
	Poplar :: struct {
		index: int,
		level: int,
	}
	sorted_roots : [dynamic; 32]Poplar
	roots : bit_set[0..<32]
	level := 0

	// heapify
	for i in 1..<n {
		if level not_in roots {
			roots += {level}
			level = 0
		} else {
			roots -= {level}
			level += 1
		}
		sift(arr, i, uint(level))
	}
	
	ind := 0
	#reverse for r in roots {
		s := level_size(uint(r))
		ind += s
		append(&sorted_roots, {ind-1,r})
	}
	append(&sorted_roots, {n-1,level})

	pop_sort(arr, sorted_roots[:])

	for root := n - 1; root > 1; root -= 1 {

		if last(sorted_roots[:]).index == root {
			root_pop := pop(&sorted_roots)
			if root_pop.level > 0 {
				l := left_child(root_pop.index, uint(root_pop.level))
				r := right_child(root_pop.index)
				append(&sorted_roots, {l, root_pop.level - 1})
				append(&sorted_roots, {r, root_pop.level - 1})
				pop_sort(arr, sorted_roots[:], -2)
			}
		} else {
			highest := pop(&sorted_roots)
			swap(&arr[highest.index], &arr[root])
			sift(arr, highest.index, uint(highest.level))
			
			root_index := find(sorted_roots[:], root)
			root_pop := sorted_roots[root_index]
			ordered_remove(&sorted_roots, root_index)

			append(&sorted_roots, highest)
			to_sort := 1

			if root_pop.level > 0 {
				l := left_child(root_pop.index, uint(root_pop.level))
				r := right_child(root_pop.index)
				append(&sorted_roots, {l, root_pop.level - 1})
				append(&sorted_roots, {r, root_pop.level - 1})
				to_sort += 2
			}
			pop_sort(arr, sorted_roots[:], -to_sort)
		}

	}
	cond_swap(&arr[1], &arr[0])

	last :: proc(pops: []Poplar) ->Poplar {
		return pops[len(pops)-1]
	}

	find :: proc(popl: []Poplar, root: int) -> int {
		for p, i in popl {
			if p.index == root {
				return i
			}
		}
		return -1
	}
	pop_sort::pop_insertion_sort

	pop_insertion_sort_binary2 :: proc(data: []int, arr: []Poplar, start := 1) {
		start := start
		if start < 0 {
			start = len(arr) + start - 0
		}
		for i in start..<len(arr) {
			dest := pop_bin_search_left(data, arr[:i], &data[arr[i].index])
			if dest == i { continue }
			t := arr[i]
			for j := i; j > dest; j -= 1{
				arr[j] = arr[j-1]
			}
			arr[dest] = t
		}
	}

	pop_insertion_sort :: proc(data: []int, arr: []Poplar, start := 1) {
		start := start
		if start < 0 {
			start = len(arr) + start - 0
		}
		for i in start..<len(arr) {
			t := arr[i]
			j := i
			for j > 0 && less(&data[t.index], &data[arr[j - 1].index]) {
				arr[j] = arr[j-1]
				j -= 1
			}
			arr[j] = t
		}
	}
	insertion_sort :: proc(arr: []int) {
		for i in 1..<len(arr) {
			move(&temp, &arr[i])
			j := i
			for j > 0 && less(&temp, &arr[j - 1]) {
				move(&arr[j], &arr[j - 1])
				j -= 1
			}
			move(&arr[j], &temp)
		}
	}
	pop_bin_search_left :: proc(data: []int, arr: []Poplar, value: ^int) -> (from: int) {
		n := len(arr)

		for n > 0 {
			half := n / 2
			mid := from + half

			if less(&data[arr[mid].index], value) {
				from = mid + 1
				n -= half + 1
			} else {
				n = half
			}
		}

		return from
	}

	sift :: proc(arr: []int, root: int, level: uint) {
		root := root; level := level
		child : int
		move(&temp, &arr[root])
		for level > 0 {
			l_child := left_child(root, level)
			r_child := right_child(root)
			if less(&arr[l_child], &arr[r_child]) {
				child = r_child
			} else {
				child = l_child
			}
			if less(&temp, &arr[child]) {
				move(&arr[root], &arr[child])
			} else {
				break
			}
			root = child
			level -= 1
		}
		move(&arr[root], &temp)
	}
	left_child :: proc(root: int, level: uint) -> int {
		return root - 1 - level_size(level - 1)
	}
	right_child :: proc(root: int) -> int {
		return root - 1
	}
	level_size :: proc(n: uint) -> int{
		return 1 << (n + 1) - 1
	}
}


leo := [?]int{1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753,
1219, 1973, 3193, 5167, 8361, 13529, 21891, 35421, 57313,
92735, 150049}
smooth_sort :: proc(arr: []int) {
	head := 0
	p := 1
	pshift := 1
	n := len(arr) - 1

	for head < n {
		if p & 3 == 3 {
			sift(arr, pshift, head)
			p >>= 2
			pshift += 2
		} else {
			if leo[pshift - 1] >= n - head {
				trinkle(arr, p, pshift, head, false)
			} else {
				sift(arr, pshift, head)
			}

			if pshift == 1 {
				p <<= 1
				pshift -= 1
			} else {
				p <<= uint(pshift) - 1
				pshift = 1
			}
		}
		p |= 1
		head += 1
	}

	trinkle(arr, p, pshift, head, false)

	for pshift != 1 || p != 1 {
		if pshift <= 1 {
			trail := intrinsics.count_trailing_zeros(p &~ 1)
			p >>= uint(trail)
			pshift += trail
		} else {
			p <<= 2
			p ~= 7
			pshift -= 2

			trinkle(arr, p >> 1, pshift + 1, head - leo[pshift] - 1, true)
			trinkle(arr, p, pshift, head - 1, true)
		}
		head -= 1
	}
		
	sift :: proc(arr: []int, pshift, head: int) {
		head := head; pshift := pshift
		move(&temp, &arr[head])

		for pshift > 1 {
			rt := head - 1
			lf := head - 1 - leo[pshift - 2]

			if !less(&temp, &arr[lf]) && !less(&temp, &arr[rt]) {
				break
			}

			if !less(&arr[lf], &arr[rt]) {
				move(&arr[head], &arr[lf])
				head = lf
				pshift -= 1
			} else {
				move(&arr[head], &arr[rt])
				head = rt
				pshift -= 2
			}
		}
		move(&arr[head], &temp)
	}
	
	trinkle :: proc(arr: []int, p, pshift, head: int, trusty: bool) {
		trusty := trusty; head := head; pshift := pshift; p := p
		move(&temp, &arr[head])

		for p != 1 {
			stepson := head - leo[pshift] 

			if !less(&temp, &arr[stepson]) { break }

			if !trusty && pshift > 1 {
				rt := head  - 1
				lf := head - 1 - leo[pshift - 2]
				if !less(&arr[rt], &arr[stepson]) || !less(&arr[lf], &arr[stepson])  { break }
			}

			move(&arr[head], &arr[stepson])

			head = stepson
			trail := intrinsics.count_trailing_zeros(p &~ 1)
			p >>= uint(trail)
			pshift += trail
			trusty = false
		}

			move(&arr[head], &temp)
		if !trusty {
			sift(arr, pshift, head)
		}
	}
}

heap_sort :: proc(arr: []int) {
	for i := len(arr) / 2; i >= 0; i -= 1 {
		sift(arr, i)
	}

	for i := len(arr) - 1; i > 0; i -= 1 {
		swap(&arr[0], &arr[i])
		sift(arr[:i], 0)
	}
	
}

sift :: proc(arr: []int, root: int) {
	root := root
	end := len(arr) - 1
	for {
		child := root * 2 + 1
		if child > end { break }
		if child + 1 <= end && less(&arr[child], &arr[child + 1]) {
			child += 1
		}

		if !cond_swap(&arr[root], &arr[child]) {
			break
		}
		root = child
	}
	
}
bubble_sort :: proc(arr: []int) {
	for i in 1..<len(arr) {
		change := false
		for j in 0..<len(arr) - i {
			change |= cond_swap(&arr[j + 1], &arr[j])
		}
		if !change { break }
	}
}

odd_even :: proc(arr: []int) {
	odd := 1
	n := len(arr)
	change := true
	for _ in arr {
		for start := odd; start < n - 1; start += 2{
			if cond_swap(&arr[start + 1], &arr[start]) {
				change = true
			}
		} 
		odd = 1 - odd
		if !change { break }
		change = false
	} 
}

shell_sort :: proc(arr: []int) {
	gaps := []int{69487, 31970, 14842, 6847, 3227, 1408, 644, 301, 132, 57, 23, 10, 4, 1}
    
	for g in gaps {
		for k := g; k < len(arr); k += 1 {
			// if !less(&arr[k], &arr[k - g]) {
			// 	continue
			// }
			// move(&arr[k], &arr[k - g])

			t := k
			move(&temp, &arr[t])
			for t >= g && less(&temp, &arr[t - g]) {
				move(&arr[t], &arr[t - g])
				t -= g
			}
			move(&arr[t], &temp)
		}
	}
}
shell_sort2 :: proc(arr: []int) {
	gaps := []int{69487, 31970, 14842, 6847, 3227, 1408, 644, 301, 132, 57, 23, 10, 4, 1}
    
	for g in gaps {
		for k := g; k < len(arr); k += 1 {
			if !less(&arr[k], &arr[k - g]) {
				continue
			}
			move(&temp, &arr[k])
			move(&arr[k], &arr[k - g])

			t := k - g
			for t >= g && less(&temp, &arr[t - g]) {
				move(&arr[t], &arr[t - g])
				t -= g
			}
			move(&arr[t], &temp)
		}
	}
}

comb_sort :: proc(arr: []int) {
	n := len(arr)
	gap := n * 10 / 13
	for {
		for i := gap; i < n; i += 1 {
			cond_swap(&arr[i], &arr[i - gap])
		}
		gap = gap * 10 / 13
		if gap <= 1 { break }
	}
	bubble_sort(arr)
}





merge_rotate :: proc(arr: []int) {
	if len(arr) < 2 {
		// insertion_sort(arr)
		return
	}
		
	mid := len(arr) / 2
	merge_rotate(arr[:mid])
	merge_rotate(arr[mid:])


	inplace_merge(arr, mid, len(arr) - mid)
}

bin_search_left :: proc(arr: []int, value: ^int) -> (from: int) {
	n := len(arr)

	for n > 0 {
		half := n / 2
		mid := from + half

		if less(&arr[mid], value) {
			from = mid + 1
			n -= half + 1
		} else {
			n = half
		}
	}

	return from
}

bin_search_right :: proc(arr: []int, value: ^int) -> (from: int) {
	n := len(arr)

	for n > 0 {
		half := n / 2
		mid := from + half

		if less(value, &arr[mid]) {
			n = half
		} else {
			from = mid + 1
			n -= half + 1
		}
	}

	return from
}

inplace_merge :: proc(arr: []int, left, right: int) {
	if left == 0 || right == 0 {
		return
	}

	if left + right == 2 {
		cond_swap(&arr[1],&arr[0])
		return
	}

	if !less(&arr[left], &arr[left - 1]) { return }

	first_cut, second_cut: int
	left2, right2: int

	if left > right {
		left2 = left / 2
		first_cut = left2

		second_cut = left + bin_search_left(arr[left:], &arr[first_cut])
		right2 = second_cut - left
	} else {
		right2 = right / 2
		second_cut = left + right2
		
		first_cut = bin_search_right(arr[:left], &arr[second_cut])
		left2 = first_cut
	}

	rotate_reverse(arr[first_cut:second_cut], left - first_cut)
	new_mid := first_cut + right2

	inplace_merge(arr[:new_mid], left2       , right2        )
	inplace_merge(arr[new_mid:], left - left2, right - right2)
}

rotate_reverse :: proc(arr: []int, left: int) {
	reverse(arr[left:])
	reverse(arr[:left])
	reverse(arr)
}
reverse :: proc(arr: []int) {
	n := len(arr)
	for i in 0..<n / 2 {
		swap(&arr[i], &arr[n - i - 1])
	}
}


cycle_sort :: proc(arr: []int) {
	n := len(arr)
	for i in 0..<n {
		move(&temp, &arr[i])
		dest := i
		for j in i+1..<n {
			if less(&arr[j], &temp) {
				dest += 1
			}
		}
		if dest != i {
			for {

				for !less(&arr[dest], &temp) && !less(&temp, &arr[dest]) { dest += 1}
				swap(&arr[dest], &temp)

				dest = i

				for j in i+1..<n {
					if less(&arr[j], &temp) {
						dest += 1
					}
				}

				if dest == i { break }
			}
		}
		move(&arr[i], &temp)
	}
}

circle_sort :: proc(arr: []int) {
	for circle_sort_rec(arr, 0, len(arr) - 1) {}

	circle_sort_rec :: proc(arr: []int, s, e: int) -> (change: bool) {
		if s >= e  {return false}
		m := (e + s) / 2
		l := s
		r := e
		for l < r {
			change |= cond_swap(&arr[r], &arr[l])
			l += 1; r -= 1
		}
		if l == r {
			change |= cond_swap(&arr[m + 1], &arr[m]);
		}
		change |= circle_sort_rec(arr, s, m)
		change |= circle_sort_rec(arr, m + 1, e)
		return change
	}
}


insertion_sort :: proc(arr: []int) {
	for i in 1..<len(arr) {
		move(&temp, &arr[i])
		j := i
		for j > 0 && less(&temp, &arr[j - 1]) {
			move(&arr[j], &arr[j - 1])
			j -= 1
		}
		move(&arr[j], &temp)
	}
}

insertion_sort_binary :: proc(arr: []int) {
	for i in 1..<len(arr) {
		dest := bin_search_left(arr[:i], &arr[i])
		if dest == i { continue }
		move(&temp, &arr[i])
		for j := i; j > dest; j -= 1{
			move(&arr[j], &arr[j - 1])
		}
		move(&arr[dest], &temp)
	}
}

quick_sort_ll :: proc(arr: []int) {
	if len(arr) <= 1 { return }

	li := 0
	
	for i in 1..<len(arr) {
		if less(&arr[i], &arr[0]) {
			li += 1
			swap(&arr[i], &arr[li])
		}
	}
	swap(&arr[0], &arr[li])

	quick_sort_ll(arr[:li])
	quick_sort_ll(arr[li + 1:])
	
}

quick_sort_lr2 :: proc(arr: []int) {
	if len(arr) <= 1 { return }

	temp = arr[len(arr) / 2]
	left := 0
	right := len(arr) - 1
	
	for {
		for less(&arr[left], &temp) { left += 1 }
		for less(&temp, &arr[right]) { right -= 1 }
		if left >= right { break }
		swap(&arr[left], &arr[right])
		left += 1; right -= 1
	}

	quick_sort_lr2(arr[:left])
	quick_sort_lr2(arr[left:])
}
quick_sort_lr :: proc(arr: []int) {
	if len(arr) <= 1 { return }

	p_index := len(arr) / 2
	left := 1
	right := len(arr) - 1
	
	swap(&arr[0], &arr[p_index])
	for {
		for left < right && less(&arr[left], &temp) { left += 1 }
		for left < right && less(&temp, &arr[right]) { right -= 1 }
		if left >= right { break }
		swap(&arr[left], &arr[right])
		left += 1; right -= 1
	}
	swap(&arr[0], &arr[left-1])

	quick_sort_lr(arr[:left-1])
	quick_sort_lr(arr[left:])
}

networks :: proc(arr: []int) {
	assert(len(arr) <= 32)
	switch len(arr) {
	case:
	case 2: sort_network_2(arr)
	case 3: sort_network_3(arr)
	case 4: sort_network_4(arr)
	case 5: sort_network_5(arr)
	case 6: sort_network_6(arr)
	case 7: sort_network_7(arr)
	case 8: sort_network_8(arr)
	case 9: sort_network_9(arr)
	case 10: sort_network_10(arr)
	case 11: sort_network_11(arr)
	case 12: sort_network_12(arr)
	case 13: sort_network_13(arr)
	case 14: sort_network_14(arr)
	case 15: sort_network_15(arr)
	case 16: sort_network_16(arr)
	case 17: sort_network_17(arr)
	case 18: sort_network_18(arr)
	case 19: sort_network_19(arr)
	case 20: sort_network_20(arr)
	case 21: sort_network_21(arr)
	case 22: sort_network_22(arr)
	case 23: sort_network_23(arr)
	case 24: sort_network_24(arr)
	case 25: sort_network_25(arr)
	case 26: sort_network_26(arr)
	case 27: sort_network_27(arr)
	case 28: sort_network_28(arr)
	case 29: sort_network_29(arr)
	case 30: sort_network_30(arr)
	case 31: sort_network_31(arr)
	case 32: sort_network_32(arr)
	}
}


pipo_sort :: proc(arr, swap: []int) {
	assert(len(swap) > 0)
	if len(arr) <= 7 {
		networks(arr)
		return
	} 

	half1 := len(arr) / 2
	quad1 := half1 / 2
	quad2 := half1 - quad1
	half2 := len(arr) - half1
	quad3 := half2 / 2
	quad4 := half2 - quad3

	pipo_sort(arr        [:quad1], swap)
	pipo_sort(arr[quad1:][:quad2], swap)
	pipo_sort(arr[half1:][:quad3], swap)
	pipo_sort(arr[half1 + quad3:], swap)

	if  !less(&arr[quad1],         &arr[quad1 - 1]) &&
		!less(&arr[half1],         &arr[half1 - 1]) &&
		!less(&arr[half1 + quad3], &arr[half1 + quad3 - 1]) {
			return
	}
	merge_oop(swap[:half1], arr[:half1], quad1, quad2)
	merge_oop(swap[half1:], arr[half1:], quad3, quad4)
	merge_oop(arr,          swap[:],     half1, half2)
}

parity_merge :: proc(to, from: []int, left, right: int) {
	left_low := 0
	left_high := left - 1
	right_low := left
	right_high := left + right - 1
	write_low := 0
	write_high := right_high

	for _ in 0..<left {
		if less(&from[right_low], &from[left_low]) {
			move(&to[write_low], &from[inc(&right_low)])
		} else {
			move(&to[write_low], &from[inc(&left_low)])
		}
		write_low += 1
		if less(&from[right_high], &from[left_high]) {
			move(&to[write_high], &from[dec(&left_high)])
		} else {
			move(&to[write_high], &from[dec(&right_high)])
		}
		write_high -= 1
	}

	if left != right {
		if less(&from[right_low], &from[left_low]) {
			move(&to[write_low], &from[inc(&right_low)])
		} else {
			move(&to[write_low], &from[inc(&left_low)])
		}
	}
}

inc :: proc(ptr: ^int) -> int {
	defer ptr^ += 1
	return ptr^
}

dec :: proc(ptr: ^int) -> int {
	defer ptr^ -= 1
	return ptr^
}





merge_cross :: proc(to, from: []int, left, right: int) {
	l := 0
	r := left
	i := 0

	for l + 1 < left && r + 1 < left + right {
		if !less(&from[r], &from[l + 1]) {
			move(&to[inc(&i)], &from[inc(&l)])
			move(&to[inc(&i)], &from[inc(&l)])
		} else if less(&from[r + 1], &from[l]) {
			move(&to[inc(&i)], &from[inc(&r)])
			move(&to[inc(&i)], &from[inc(&r)])
		} else {
			if !less(&from[r], &from[l]) {
				move(&to[inc(&i)], &from[inc(&l)])
				move(&to[inc(&i)], &from[inc(&r)])
			} else {
				move(&to[inc(&i)], &from[inc(&r)])
				move(&to[inc(&i)], &from[inc(&l)])
			}
			if !less(&from[r], &from[l]) {
				move(&to[inc(&i)], &from[inc(&l)])
			} else {
				move(&to[inc(&i)], &from[inc(&r)])
			}
		}
	}
	for l < left && r < left + right {			
		if !less(&from[r], &from[l]) {
			move(&to[inc(&i)], &from[inc(&l)])
		} else {
			move(&to[inc(&i)], &from[inc(&r)])
		}
	}


	for l < left {
		move(&to[inc(&i)], &from[inc(&l)])
	} 
	for r < left + right {
		move(&to[inc(&i)], &from[inc(&r)])
	}
}







cond_swap :: proc(left, right: ^int, loc := #caller_location) -> bool {
	res := left^ < right^

	when !TEST {
		comps += 1
		append(&array_action, Cmp{
			location(left), location(right), res, loc
		})
	}
	if res {
		moves += 3
		when !TEST {
			append(&array_action, Swap{
				location(left), location(right)
			})
		}
		left^, right^ = right^, left^	
	}
	return res
}

move :: proc(left, right: ^int, loc := #caller_location) {
	when !TEST {
		moves += 1
		append(&array_action, Move {
			location(left), location(right)
		})
	}
	left^ = right^
}

swap :: proc(left, right: ^int, loc := #caller_location) {
	when !TEST {
		moves += 3
		append(&array_action, Swap{
			location(left), location(right)
		})
	}
	left^, right^ = right^, left^	
}
less :: proc(left, right: ^int, loc := #caller_location) -> (res: bool) {
	res = left^ < right^

	when !TEST {
		comps += 1
		append(&array_action, Cmp{
			location(left), location(right), res, loc
		})
	}

	return res
}

location :: proc(n: ^int) -> (type: Arr_Type, ind: int) {
	main := cast(uintptr)raw_data(arr)
	swap := cast(uintptr)raw_data(aux)
	t := cast(uintptr)&temp
	n := uintptr(n)

	if n == t {
		return .Temp, 0
	}
	diff := int((n - main) / size_of(int))
	if diff >= 0 && diff < len(arr) {
		return .Main, diff
	}
	diff = int((n - swap) / size_of(int))
	return .Swap, diff
}

mark :: proc(int) {}