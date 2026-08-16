package msort

import "core:slice"
import "base:intrinsics"

/*
    thanks to scandum for blit partitioning
    https://github.com/scandum
*/

BLIT_SWAP :: 512

ipsort :: proc(arr: $A/[]$T) 
    where intrinsics.type_is_ordered(T) {

    ips_sort(arr, 0, proc(l, r: T, d: int) -> bool{return l < r})
}

ipsort_by :: proc(arr: $A/[]$T, $CMP: proc(T,T) -> bool) {
    ips_sort(arr, 0, proc(l, r :T, data: int) -> bool {return CMP(l,r)})
}

// not actually in place, creates indecies array
ipsort_with_indices :: proc(arr: $A/[]$T, allocator := context.allocator) -> []int 
    where intrinsics.type_is_ordered(T) {

    indices := make([]int,len(arr), allocator)
    for &index, i in indices{
        index = i
    }

    ips_sort(indices, arr, proc(l,r: int, data: A) -> bool {
        return data[l] < data[r]
    })

    sort_from_permutation_indices(arr, indices)
    return indices
}

// not actually in place, creates indecies array
ipsort_by_with_indices :: proc(arr: $A/[]$T, $CMP: proc(T,T) -> bool, allocator := context.allocator) -> []int {
    indices := make([]int,len(arr),allocator)
    for &index, i in indices{
        index = i
    }

    ips_sort(indices, arr, proc(l,r: int, data: A) -> bool {
        return CMP(data[l], data[r])
    }, allocator)

    sort_from_permutation_indices(arr, indices)
    return indices
}

ipsort_by_with_data :: proc(arr: $A/[]$T, data: $D, $CMP: proc(T,T, D) -> bool) {
    ips_sort(arr, data, proc(l,r: int, data: D) -> bool {
        return CMP(l, r, data)
    })
}

// not actually in place, creates indecies array
ipsort_by_with_indices_with_data :: proc(arr: $A/[]$T, data: $D, $CMP: proc(T,T, D) -> bool, allocator := context.allocator) -> []int {
    indices := make([]int,len(arr),allocator)
    for &index, i in indices{
        index = i
    }
    
    Context :: struct {
        arr: A,
        data: D,
    }
    ctx := Context{arr, data}

    ips_sort(indices, &ctx, proc(l,r: int, ctx: ^Context) -> bool {
        return CMP(ctx.arr[l], ctx.arr[r], ctx.data)
    }, allocator)

    sort_from_permutation_indices(arr, indices)
    return indices
}

ips_sort :: proc(arr: $A/[]$T, data: $D, $CMP: $P, allocator := context.allocator) {
    if len(arr) <= 64 {
        insertion_sort(arr, data)
        return
    }

    swap : [BLIT_SWAP]T = ---
    ips(arr, swap[:], data, nil)
    // delete(swap)

    ips :: proc(arr, swap: A, data: D, last_piv: Maybe(T)) #no_bounds_check {
        if len(arr) <= 48 {
            // if raw_data(arr) != raw_data(cur) {
            //     copy(arr, cur)
            // }

            insertion_sort(arr, data)
            return
        }

        depth := log2(len(arr) + 100) / 5 
        pivot := med3(arr, data, depth)

        if pivot == last_piv {
            left := partition_reverse(arr, swap, data, pivot)
            right := len(arr) - left
            ips(arr[left:], swap, data, pivot)
            return
        } 

        left := partition(arr, swap, data, pivot)
        right := len(arr) - left
        ips(arr[left:], swap, data, pivot)
        #must_tail ips(arr[:left], swap, data, pivot)
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

    partition :: proc(arr, swap: A, data: D, piv: T) -> int #no_bounds_check {

        if len(arr) > BLIT_SWAP {
            half := len(arr) / 2
            left := partition(arr[:half], swap, data, piv)
            right := partition(arr[half:], swap, data, piv)

            slice.rotate_left(arr[left:half + right], half - left)

            return left + right
        }


        less := 0

        #unroll(8) for a,i in arr {
            x := cast(int)CMP(a, piv, data)
            arr[less] = a
            swap[i - less] = a
            less += x
        }

        copy(arr[less:],swap)
        
        return less
    }

    partition_reverse :: proc(arr, swap: A, data: D, piv: T) -> int #no_bounds_check {

        if len(arr) > BLIT_SWAP {
            half := len(arr) / 2
            left := partition_reverse(arr[:half], swap, data, piv)
            right := partition_reverse(arr[half:], swap, data, piv)

            slice.rotate_left(arr[left:half + right], half - left)

            return left + right
        }


        less := 0

        #unroll(8) for a,i in arr {
            x := cast(int)!CMP(piv, a, data)
            arr[less] = a
            swap[i - less] = a
            less += x
        }

        copy(arr[less:],swap)
        
        return less
    }
}

