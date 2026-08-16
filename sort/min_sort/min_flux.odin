package msort

import "base:intrinsics"

/*
    thanks to scandum for flux partitioning
    https://github.com/scandum
*/

sort :: proc(arr: $A/[]$T, allocator := context.allocator) 
    where intrinsics.type_is_ordered(T) {

    oop_sort(arr, 0, proc(l, r: T, d: int) -> bool{return l < r}, allocator)
}

sort_by :: proc(arr: $A/[]$T, $CMP: proc(T,T) -> bool, allocator := context.allocator) {
    oop_sort(arr, 0, proc(l, r :T, data: int) -> bool {return CMP(l,r)}, allocator)
}

sort_with_indices :: proc(arr: $A/[]$T, allocator := context.allocator) -> []int 
    where intrinsics.type_is_ordered(T) {

    indices := make([]int,len(arr), allocator)
    for &index, i in indices{
        index = i
    }

    oop_sort(indices, arr, proc(l,r: int, data: A) -> bool {
        return data[l] < data[r]
    }, allocator)

    sort_from_permutation_indices(arr, indices)
    return indices
}

sort_by_with_indices :: proc(arr: $A/[]$T, $CMP: proc(T,T) -> bool, allocator := context.allocator) -> []int {
    indices := make([]int,len(arr),allocator)
    for &index, i in indices{
        index = i
    }

    oop_sort(indices, arr, proc(l,r: int, data: A) -> bool {
        return CMP(data[l], data[r])
    }, allocator)

    sort_from_permutation_indices(arr, indices)
    return indices
}

sort_by_with_data :: proc(arr: $A/[]$T, data: $D, $CMP: proc(T,T, D) -> bool, allocator := context.allocator) {
    oop_sort(arr, data, proc(l,r: int, data: D) -> bool {
        return CMP(l, r, data)
    }, allocator)
}

sort_by_with_indices_with_data :: proc(arr: $A/[]$T, data: $D, $CMP: proc(T,T, D) -> bool, allocator := context.allocator) -> []int {
    indices := make([]int,len(arr),allocator)
    for &index, i in indices{
        index = i
    }
    
    Context :: struct {
        arr: A,
        data: D,
    }
    ctx := Context{arr, data}

    oop_sort(indices, &ctx, proc(l,r: int, ctx: ^Context) -> bool {
        return CMP(ctx.arr[l], ctx.arr[r], ctx.data)
    }, allocator)

    sort_from_permutation_indices(arr, indices)
    return indices
}

sort_from_permutation_indices :: proc(data: $T/[]$E, indices: []int) {
	assert(len(data) == len(indices))
	if len(indices) <= 1 {
		return
	}

	for i in 0..<len(indices) {
		index_to_swap := indices[i]

		for index_to_swap < i {
			index_to_swap = indices[index_to_swap]
		}

        data[i], data[index_to_swap] = data[index_to_swap], data[i]
	}
}

oop_sort :: proc(arr: $A/[]$T, data: $D, $CMP: $P, allocator := context.allocator) {
    if len(arr) <= 64 {
        insertion_sort(arr, data)
        return
    }

    swap := make(A, len(arr), allocator)
    oop(arr, swap, arr, data, nil)
    delete(swap, allocator)

    oop :: proc(arr, swap, cur: A, data: D, last_piv: Maybe(T)) #no_bounds_check {
        if len(arr) <= 48 {
            if raw_data(arr) != raw_data(cur) {
                copy(arr, cur)
            }

            insertion_sort(arr, data)
            return
        }

        depth := log2(len(arr) + 100) / 5 
        pivot := med3(cur, data, depth)

        if pivot == last_piv {
            left := partition_reverse(arr, swap, cur, data, pivot)
            right := len(arr) - left
            oop(arr[left:], swap, swap[:right], data, pivot)
            return
        } 

        left := partition(arr, swap, cur, data, pivot)
        right := len(arr) - left
        oop(arr[left:], swap, swap[:right], data, pivot)
        #must_tail oop(arr[:left], swap, arr[:left], data, pivot)
    }

    log2 :: proc(n: int) -> int {
        log := 0
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
        
        x := CMP(swap[0], swap[1], data)
        y := CMP(swap[0], swap[2], data)
        z := CMP(swap[1], swap[2], data)

        return swap[(int)(x == y) + (int)(y ~ z)]
    }

    insertion_sort :: #force_inline proc(arr: A, data: D) #no_bounds_check {
        for i in 1..<len(arr) {
            current := arr[i]
            j := i
            for ; j > 0 && CMP(current, arr[j - 1], data); j -= 1 {
                arr[j] = arr[j - 1]
            }
            arr[j] = current
        }
    }

    partition :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
        less := 0

        #unroll(8) for a,i in cur {
            x := cast(int)CMP(a, piv, data)
            arr[less] = a
            swap[i - less] = a
            less += x
        }
        
        return less
    }

    partition_reverse :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
        less_equal := 0

        #unroll(8) for a,i in cur {
            x := cast(int)!CMP(piv, a, data)
            arr[less_equal] = a
            swap[i - less_equal] = a
            less_equal += x
        }
        
        return less_equal
    }
}

