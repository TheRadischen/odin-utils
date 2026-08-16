package msort

import "core:fmt"
import "core:slice"
import "base:intrinsics"

/*
    thanks to scandum for blit partitioning
    https://github.com/scandum
*/


soa_ipsort_by :: proc(arr: $A/#soa[]$T, $CMP: proc(T,T) -> bool) {
    soa_ips_sort(arr, 0, proc(l, r :T, data: int) -> bool {return CMP(l,r)})
}

@private
soa_ips_sort :: proc(arr: $A/#soa[]$T, data: $D, $CMP: $P, allocator := context.allocator) {
    if len(arr) <= 64 {
        insertion_sort(arr, data)
        return
    }

    swap : #soa[BLIT_SWAP]T = ---
    ips(arr, swap[:], data, nil)


    ips :: proc(arr, swap: A, data: D, last_piv: Maybe(T)) #no_bounds_check {
        
        if len(arr) <= 48 {
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
        ips(arr[:left], swap, data, pivot)
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

        swap := #soa[3]T{
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
        

        if len(arr) > len(swap) {
            half := len(arr) / 2
            left := partition(arr[:half], swap, data, piv)
            right := partition(arr[half:], swap, data, piv)

            rotate(arr[left:half + right], half - left)

            return left + right
        }

        less := 0

        for a,i in arr {
            x := cast(int)CMP(a, piv, data)
            arr[less] = a
            swap[i - less] = a
            less += x
        }

        soa_copy(arr[less:], swap)
        
        return less
    }

    partition_reverse :: proc(arr, swap: A, data: D, piv: T) -> int #no_bounds_check {
        

        if len(arr) > len(swap) {
            half := len(arr) / 2
            left := partition_reverse(arr[:half], swap, data, piv)
            right := partition_reverse(arr[half:], swap, data, piv)

            rotate(arr[left:half + right], half - left)

            return left + right
        }

        less_equal := 0

        for a,i in arr {
            x := cast(int)!CMP(piv, a, data)
            arr[less_equal] = a
            swap[i - less_equal] = a
            less_equal += x
        }

        soa_copy(arr[less_equal:], swap)
        
        return less_equal
    }
    soa_copy :: proc(dest, src: A) {
        for i in 0..<min(len(dest), len(src)) {
            dest[i] = src[i]
        }   
    }
    // needs a better rotate
    rotate :: proc(arr: A, pos: int) {
        
        reverse(arr[:pos])
        reverse(arr[pos:])
        reverse(arr)
    }
    reverse :: proc(arr: A) {
        last := len(arr) - 1
        for i in 0..<len(arr) / 2 {
            arr[i], arr[last - i] = arr[last - i], arr[i]
        }
    }
}
