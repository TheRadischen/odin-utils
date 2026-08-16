package msort


/*
    thanks to scandum for flux partitioning
    https://github.com/scandum
*/

soa_sort_by :: proc(arr: $A/#soa[]$T, $CMP: proc(T,T) -> bool, allocator := context.allocator) {
    soa_oop_sort(arr, 0, proc(l, r :T, data: int) -> bool {return CMP(l,r)}, allocator)
}

soa_oop_sort :: proc(arr: $A/#soa[]$T, data: $D, $CMP: $P, allocator := context.allocator) {

    if len(arr) <= 64 {
        insertion_sort(arr, data)
        return
    }

    swap := make(A, len(arr), allocator)
    oop(arr, swap, arr, data, nil)
    delete(swap, allocator)

    oop :: proc(arr, swap, cur: A, data: D, last_piv: Maybe(T)) #no_bounds_check {
        arr := arr; cur := cur; swap := swap
        if len(arr) <= 48 {
            if (^rawptr)(&arr)^ != (^rawptr)(&cur)^ {
                for i in 0..<len(arr) {
                    arr[i] = cur[i]
                }                
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
        oop(arr[:left], swap, arr[:left], data, pivot)
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
        arr := arr
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
        arr := arr
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
        arr := arr; cur := cur; swap := swap
        less := 0
        
        for i in 0..<len(cur) {
            x := cast(int)CMP(cur[i], piv, data)
            arr[less] = cur[i]
            swap[i - less] = cur[i]
            less += x
        }
        
        return less
    }

    partition_reverse :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
        arr := arr; cur := cur; swap := swap
        less_equal := 0

        for i in 0..<len(cur) {
            x := cast(int)!CMP(piv, cur[i], data)
            arr[less_equal] = cur[i]
            swap[i - less_equal] = cur[i]
            less_equal += x
        }
        
        return less_equal
    }
}

