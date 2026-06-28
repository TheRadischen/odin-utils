package blit

import "base:runtime"
import "base:intrinsics"

/*
stable out of place adaptive merge-sort; call with len(swap) == len(arr) for optimal performance
doesnt allocate, but needs a swap of at least 32 length
*/
quadsort_swap :: proc(arr, swap: $A, greater: proc($T,T) -> bool){
    if len(arr) <= 96 {
        tail_swap(arr, swap, greater)
    } else if !quad_swap(arr, swap, greater) {
        block := quad_merge(arr, swap, 32, greater)
        rotate_merge(arr, swap, block, greater)
    }
}

/*
entry point
allocates n memory, unless we sort 32 or smaller, with according to rust telemetry  95% of sorts are on arrays of len <= 20
*/
// quadsort :: proc(arr: $A, greater: proc($T,T) -> bool){

//              append(&function,strings.clone_to_cstring(fmt.aprint(caller)))//;append(&function, "quadsort_swap")
//     if len(arr) <= 32 {
//         swap : [32]T
//         tail_swap(arr, swap, greater)
//         return
//     }
//     swap := make(A,len(arr))
//     if swap == nil {
//         inplace_sort(arr, greater)
//     }
//     if !quad_swap(arr, swap, greater) {
//         block := quad_merge(arr, swap, 32, greater)
//         rotate_merge(arr, swap, block, greater)
//     }
// }

/*
the first pass over the array when len(arr) > 96
in the first pass sorts the array into blocks of 8 and checks for reverse sorted and sorted
then merges the blocks of 8 into 32
on fully sorted and reverse sorted arr returns early
original c code has wicked gotos everywhere i used a switch to check for sorted, reverse or random
*/
quad_swap :: proc(arr, swap: $A, greater: proc($T,T) -> bool) -> bool {
    x, v1, v2, v3, v4 : int
    pta, pts : int
    State :: enum {Neutral, Ordered, Reversed}
    state := State.Neutral
    count := len(arr) / 8
    skip_end_tail := false

    outer: for ;count > 0; count -= 1 {
        switch state {
            case .Neutral:        
                v1 = cast(int)greater(arr[pta + 0],arr[pta + 1])
                v2 = cast(int)greater(arr[pta + 2],arr[pta + 3])
                v3 = cast(int)greater(arr[pta + 4],arr[pta + 5])
                v4 = cast(int)greater(arr[pta + 6],arr[pta + 7])

                switch v1 + v2 + v3 + v4 {
                    case 0: // partially ordered
                        if  !greater(arr[pta + 1],arr[pta + 2]) && 
                            !greater(arr[pta + 3],arr[pta + 4]) && 
                            !greater(arr[pta + 5],arr[pta + 6]) {
                            state = .Ordered
                            pta += 8
                            continue outer
                        }
                        quad_swap_merge(arr[pta:], swap, greater)
                        pta += 8;
                        continue outer // .Neutral

                    case 4: // partially reverse ordered
                        if  greater(arr[pta + 1],arr[pta + 2]) &&
                            greater(arr[pta + 3],arr[pta + 4]) &&
                            greater(arr[pta + 5],arr[pta + 6]) {
                            pts = pta
                            state = .Reversed
                            pta += 8
                            continue outer
                        }
                        fallthrough
                    case:
                        arr[pta], arr[pta + 1] = arr[pta + v1], arr[pta + 1 - v1]; pta += 2
                        arr[pta], arr[pta + 1] = arr[pta + v2], arr[pta + 1 - v2]; pta += 2
                        arr[pta], arr[pta + 1] = arr[pta + v3], arr[pta + 1 - v3]; pta += 2
                        arr[pta], arr[pta + 1] = arr[pta + v4], arr[pta + 1 - v4]; pta -= 6

                        quad_swap_merge(arr[pta:], swap, greater)
                        pta += 8
                        continue outer // .Neurtal
                }

            case .Ordered:
                v1 = cast(int)greater(arr[pta + 0],arr[pta + 1])
                v2 = cast(int)greater(arr[pta + 2],arr[pta + 3])
                v3 = cast(int)greater(arr[pta + 4],arr[pta + 5])
                v4 = cast(int)greater(arr[pta + 6],arr[pta + 7])
                v := v1 + v2 + v3 + v4
                if v > 0 {
                    if  v == 4 &&
                        greater(arr[pta + 1],arr[pta + 2]) &&
                        greater(arr[pta + 3],arr[pta + 4]) &&
                        greater(arr[pta + 5],arr[pta + 6]) {
                            pts = pta
                            pta += 8
                            state = .Reversed
                            continue outer
                    }
                    arr[pta], arr[pta + 1] = arr[pta + v1], arr[pta + 1 - v1]; pta += 2
                    arr[pta], arr[pta + 1] = arr[pta + v2], arr[pta + 1 - v2]; pta += 2
                    arr[pta], arr[pta + 1] = arr[pta + v3], arr[pta + 1 - v3]; pta += 2
                    arr[pta], arr[pta + 1] = arr[pta + v4], arr[pta + 1 - v4]; pta -= 6

                    quad_swap_merge(arr[pta:], swap, greater)
                    pta += 8
                    state = .Neutral
                    continue outer
                }
                if  !greater(arr[pta + 1],arr[pta + 2]) &&
                    !greater(arr[pta + 3],arr[pta + 4]) &&
                    !greater(arr[pta + 5],arr[pta + 6]) {
                        state = .Ordered
                        pta += 8
                        continue outer
                }
                quad_swap_merge(arr[pta:], swap, greater)
                pta += 8
                state = .Neutral
                continue outer


            case .Reversed:
                v1 = cast(int)!greater(arr[pta + 0],arr[pta + 1])
                v2 = cast(int)!greater(arr[pta + 2],arr[pta + 3])
                v3 = cast(int)!greater(arr[pta + 4],arr[pta + 5])
                v4 = cast(int)!greater(arr[pta + 6],arr[pta + 7])
                v := v1 + v2 + v3 + v4
                if v > 0 {} else {
                    if  greater(arr[pta - 1],arr[pta + 0]) &&
                        greater(arr[pta + 1],arr[pta + 2]) &&
                        greater(arr[pta + 3],arr[pta + 4]) &&
                        greater(arr[pta + 5],arr[pta + 6]) {
                            pta += 8
                            continue outer
                    }
                }
                quad_reversal(arr[pts:pta-0])

                if v == 4 &&
                    !greater(arr[pta + 1],arr[pta + 2]) &&
                    !greater(arr[pta + 3],arr[pta + 4]) &&
                    !greater(arr[pta + 5],arr[pta + 6]) {
                        state = .Ordered
                        pta += 8
                        continue outer
                }
                if v == 0 &&
                    greater(arr[pta + 1],arr[pta + 2]) &&
                    greater(arr[pta + 3],arr[pta + 4]) &&
                    greater(arr[pta + 5],arr[pta + 6]) {
                        state = .Reversed
                        pts = pta
                        pta += 8
                        continue outer
                }
                    arr[pta + 1], arr[pta] = arr[pta + v1], arr[pta + 1 - v1]; pta += 2
                    arr[pta + 1], arr[pta] = arr[pta + v2], arr[pta + 1 - v2]; pta += 2
                    arr[pta + 1], arr[pta] = arr[pta + v3], arr[pta + 1 - v3]; pta += 2
                    arr[pta + 1], arr[pta] = arr[pta + v4], arr[pta + 1 - v4]; pta -= 6
                if  greater(arr[pta + 1],arr[pta + 2]) ||
                    greater(arr[pta + 3],arr[pta + 4]) ||
                    greater(arr[pta + 5],arr[pta + 6]) {
                        quad_swap_merge(arr[pta:], swap, greater)
                }
                pta += 8
                state = .Neutral
                continue outer
        }
    }

    swit: if state == .Reversed {
        switch len(arr) % 8 {
            case 7: if !greater(arr[pta + 5], arr[pta + 6]) {break}; fallthrough
            case 6: if !greater(arr[pta + 4], arr[pta + 5]) {break}; fallthrough
            case 5: if !greater(arr[pta + 3], arr[pta + 4]) {break}; fallthrough
            case 4: if !greater(arr[pta + 2], arr[pta + 3]) {break}; fallthrough
            case 3: if !greater(arr[pta + 1], arr[pta + 2]) {break}; fallthrough
            case 2: if !greater(arr[pta + 0], arr[pta + 1]) {break}; fallthrough
            case 1: if !greater(arr[pta - 1], arr[pta + 0]) {break}; fallthrough
            case 0: 
                quad_reversal(arr[pts:])

                if pts == 0 { // entire thing was reversed
                    return true
                }
                skip_end_tail = true
                break swit
        }

        quad_reversal(arr[pts:pta - 0]) // off by one maybe
    } 
    if !skip_end_tail {
        tail_swap(arr[pta:], swap, greater)
    }
    
    pta = 0

    for count = len(arr) / 32; count > 0; count -= 1 {

        if  !greater(arr[pta +  7], arr[pta +  8]) &&
            !greater(arr[pta + 15], arr[pta + 16]) &&
            !greater(arr[pta + 23], arr[pta + 24]) {
                pta += 32
                continue // already sorted
        }
        parity_merge(swap, arr[pta:], 8, 8, greater)
        parity_merge(swap[16:], arr[16+pta:], 8, 8, greater)
        parity_merge(arr[pta:], swap, 16, 16, greater)

        pta += 32
    }
    if len(arr) % 32 > 8 {
        tail_merge(arr[pta:], swap, 8, greater)
    }

    return false
}

/*
makes increasingly larger blocks of 4 and merges them into 1
*/
quad_merge :: proc(arr, swap: $A, block: int, greater: proc($T,T) -> bool) -> int{    
    block := block * 4

    for block <= len(arr) && block <= len(swap) {
        pta := 0
        for {
            quad_merge_block(arr[pta:], swap, block / 4,  greater)
            pta += block
            if pta + block > len(arr) {break}
        }

        tail_merge(arr[pta:], swap, block / 4, greater)
        block *= 4
    }
    tail_merge(arr, swap, block / 4, greater)

    return block / 2
}

/*
used when we have limited swap memory
splits the array into increasingly larger blocks and merges them with rotate_merge_block
*/
rotate_merge ::  proc(arr, swap: $A, block: int, greater: proc($T,T) -> bool){
    pte := len(arr)
    block := block

    if len(arr) <= block * 2 && len(arr) - block <= len(swap) && len(arr) > block {
        partial_backward_merge(arr, swap, block, greater)
        return
    }

    for block < len(arr) {
        for pta := 0; pta + block < pte; pta += block * 2 {
            if pta + block * 2 < pte {
                rotate_merge_block(arr[pta:][:2*block], swap, block ,greater)
                continue
            }
            rotate_merge_block(arr[pta:], swap, block, greater)
            break
        }
        block *= 2
    }
}

/*
arr[sorted][sorted][sorted][sorted] -> arr[sorted]
merges 4 blocks into one sorted block, checking if its already sorted/ partially sorted
*/
quad_merge_block :: proc(arr, swap: $A, block: int, greater: proc($T,T) -> bool){
    blockx2 := block * 2
    pt1 := block
    pt2 := block * 2
    pt3 := block * 3
    cmp12 := cast(int)!greater(arr[pt1 - 1], arr[pt1])
    cmp34 := cast(int)!greater(arr[pt3 - 1], arr[pt3])
    switch cmp12 + cmp34 * 2 {
        case 0:
            cross_merge(swap, arr, block, block, greater)
            cross_merge(swap[pt2:], arr[pt2:], block, block, greater)
        case 1:
            quad_copy(swap, arr[:blockx2])
            cross_merge(swap[blockx2:], arr[pt2:], block, block, greater)
        case 2:
            cross_merge(swap, arr, block, block, greater)
            quad_copy(swap[blockx2:], arr[pt2:][:blockx2])
        case 3:
            if !greater(arr[pt2 - 1], arr[pt2]) {
                return
            }
            quad_copy(swap, arr[:block * 4])
    }
    cross_merge(arr, swap, blockx2, blockx2, greater)
}

/*
arr[block][block][block]...[partial [block]] -> arr[sorted]
sorts incresingly larger blocks using partial backwards merge
*/
tail_merge :: proc(arr, swap: $A, block: int, greater: proc($T,T) -> bool) {
    n := len(arr)
    pte := n
    block := block
    for block < n && block <= len(swap) {
        for pta := 0; pta + block < pte; pta += block * 2 {
            if pta + block * 2 < pte {
                partial_backward_merge(arr[pta:][:block * 2],swap, block, greater)
                continue
            }

            partial_backward_merge(arr[pta:],swap, block, greater)
            break
        }
        block *= 2
    }
}

/*
[sorted][sorted] -> [sorted]
we copy the left block into swap memory and then start merging form the left side into arr
*/
partial_forward_merge :: proc(arr, swap: $A, block: int, greater: proc($T,T) -> bool ) {
    arr := arr; swap := swap
    if len(arr) == block {
        return
    } 

    ptr := block
    tpr := len(arr) - 1

    loop : int

    if !greater(arr[ptr - 1],arr[ptr]) {
        return
    }

    quad_copy(swap,arr[:block])

    pta := 0
    ptl := 0 // swap
    tpl := block - 1 // swap

    /*
    see partial backwards merge for explanation 
    */
    left := true

    if ptl < tpl - 1 && ptr < tpr - 1 {
    outer2: for {
        if left {
            for greater(swap[ptl], arr[ptr + 1]) {
                arr[pta] = arr[ptr]; pta += 1; ptr += 1
                arr[pta] = arr[ptr]; pta += 1; ptr += 1
                if ptr >= tpr - 1 {break outer2}
            }

            if !greater(swap[ptl + 1], arr[ptr]) {
                arr[pta] = swap[ptl]; pta += 1; ptl += 1
                arr[pta] = swap[ptl]; pta += 1; ptl += 1
                if ptl >= tpl - 1 {break outer2}
                left = false
                continue outer2
            }
        } else {
            for !greater(swap[ptl + 1], arr[ptr]) {
                arr[pta] = swap[ptl]; pta += 1; ptl += 1
                arr[pta] = swap[ptl]; pta += 1; ptl += 1
                if ptl >= tpl - 1 {break outer2}
            }

            if greater(swap[ptl], arr[ptr + 1]) {
                arr[pta] = arr[ptr]; pta += 1; ptr += 1
                arr[pta] = arr[ptr]; pta += 1; ptr += 1
                if ptr >= tpr - 1 {break outer2}
                left = true
                continue outer2
            }
        }
        x := cast(int)!greater(swap[ptl], arr[ptr])
        arr[pta + x] = arr[ptr]
        ptr += 1
        arr[pta + 1 - x] = swap[ptl]
        ptl += 1
        pta += 2
        arr[pta] = !greater(swap[ptl],arr[ptr]) ? pp(swap, &ptl, T) : pp(arr, &ptr, T); pta += 1
    
        if ptl >= tpl - 1 || ptr >= tpr - 1 {
            break
        }
        left = true
    }
    }
    
    for ptl <= tpl && ptr <= tpr {
        arr[pta] = !greater(swap[ptl], arr[ptr]) ? pp(swap, &ptl, T) : pp(arr, &ptr, T); pta += 1
    }
    for ptl <= tpl {
        arr[pta] = swap[ptl]
        ptl += 1
        pta += 1
    }
}


/*
[sorted][sorted] -> [sorted]
we copy the right block into swap memory and then start merging form the right side into arr
*/
partial_backward_merge :: proc(arr, swap: $A, block: int, greater: proc($T,T) -> bool ) {
    arr := arr; swap := swap
    if len(arr) == block {
        return
    } 

    // arr
    tpl := block - 1
    tpa := len(arr) - 1

    loop : int

    if !greater(arr[tpl],arr[tpl+1]) {
        return
    }

    right := len(arr) - block

    if len(arr) <= len(swap) && right >= 64 {
        cross_merge(swap, arr, block, right, greater)
        quad_copy(arr,swap)
        return
    }

    quad_copy(swap,arr[block:][:right])

    tpr := right - 1 // swap

    // usually right block is much shorter than left so we can often skip ahead here
    outer: for tpl > 16 && tpr > 16 {
        for !greater(arr[tpl], swap[tpr - 15]) {
            for _ in 0..<16 {
                arr[tpa] = swap[tpr]
                tpa -= 1
                tpr -= 1
            }
            if tpr <= 16 {
                break outer
            }
        }

        for greater(arr[tpl - 15], swap[tpr]) {
            for _ in 0..<16 {
                arr[tpa] = arr[tpl]
                tpa -= 1
                tpl -= 1
            }
            if tpl <= 16 {
                break outer
            } 
        }

        for _ in 0..<8 {
            if !greater(arr[tpl], swap[tpr - 1]) {
                arr[tpa] = swap[tpr]; tpa -= 1; tpr -= 1
                arr[tpa] = swap[tpr]; tpa -= 1; tpr -= 1
            } else if greater(arr[tpl - 1], swap[tpr]) {
                arr[tpa] = arr[tpl]; tpa -= 1; tpl -= 1
                arr[tpa] = arr[tpl]; tpa -= 1; tpl -= 1
            } else {
                x := cast(int)!greater(arr[tpl], swap[tpr])
                tpa -= 1
                arr[tpa + x] = swap[tpr]
                tpr -= 1
                arr[tpa + 1 - x] = arr[tpl]
                tpl -= 1
                tpa -= 1
                arr[tpa] = greater(arr[tpl],swap[tpr]) ? nn(arr, &tpl, T) : nn(swap, &tpr, T); tpa -= 1
            }
        }
    }

    /*
        explanation from scandum:
        While a branchless parity merge sorts random data faster, 
        it sorts ordered data slower. 
        One way to solve this problem is by using a method with a 
        resemblance to the galloping merge concept first introduced by timsort.

        The cross merge works in a similar way to the quad swap. 
        Instead of merging two arrays two items at a time, it merges four items at a time.

        ┌───┐┌───┐┌───┐    ┌───┐┌───┐┌───┐            ╭───╮  ┌───┐┌───┐┌───┐
        │ A ││ B ││ C │    │ X ││ Y ││ Z │        ┌───│B<X├──┤ A ││ B ││C/X│
        └─┬─┘└─┬─┘└───┘    └─┬─┘└─┬─┘└───┘        │   ╰─┬─╯  └───┘└───┘└───┘
          └────┴─────────────┴────┴───────────────┘     │  ╭───╮  ┌───┐┌───┐┌───┐
                                                        └──│A>Y├──┤ X ││ Y ││A/Z│
                                                           ╰─┬─╯  └───┘└───┘└───┘
                                                             │    ┌───┐┌───┐┌───┐
                                                             └────│A/X││X/A││B/Y│
                                                                  └───┘└───┘└───┘
        When merging ABC and XYZ it first checks if B is smaller or equal to X. 
        If that's the case A and B are copied to swap. If not, it checks if A is greater than Y. 
        If that's the case X and Y are copied to swap.

        If either check is false it's known that the two remaining distributions are A X and X A. 
        This allows performing an optimal branchless merge. 
        Since it's known each block still has at least 1 item remaining (B and Y)
        and there is a high probability of the data to be random, another (sub-optimal) 
        branchless merge can be performed.
    */
    left := true
    if tpr > 1 && tpl > 1 {
    outer2: for {
        
        if left {
            for !greater(arr[tpl], swap[tpr - 1]) {
                arr[tpa] = swap[tpr]; tpa -= 1; tpr -= 1
                arr[tpa] = swap[tpr]; tpa -= 1; tpr -= 1
                if tpr < 2 {break outer2}
            }

            if greater(arr[tpl - 1], swap[tpr]) {
                arr[tpa] = arr[tpl]; tpa -= 1; tpl -= 1
                arr[tpa] = arr[tpl]; tpa -= 1; tpl -= 1
                if tpl < 2 {break outer2}
                left = false
                continue outer2
            }
        } else {
            for greater(arr[tpl - 1], swap[tpr]){
                arr[tpa] = arr[tpl]; tpa -= 1; tpl -= 1
                arr[tpa] = arr[tpl]; tpa -= 1; tpl -= 1
                if tpl < 2 {break outer2}
            }

            if !greater(arr[tpl], swap[tpr - 1]) {
                arr[tpa] = swap[tpr]; tpa -= 1; tpr -= 1
                arr[tpa] = swap[tpr]; tpa -= 1; tpr -= 1
                if tpr < 2 {break outer2}
                left = true
                continue outer2
            }
        }
        
        x := cast(int)!greater(arr[tpl], swap[tpr])
        tpa -= 1
        arr[tpa + x] = swap[tpr]
        tpr -= 1
        arr[tpa + 1 - x] = arr[tpl]
        tpl -= 1
        tpa -= 1

        arr[tpa] = greater(arr[tpl],swap[tpr]) ? nn(arr, &tpl, T) : nn(swap, &tpr, T); tpa -= 1
        if tpr < 2 || tpl < 2 {
            break
        }        
        left = true // this makes it equivalent to c code in logic, but maybe not updating left is better
        
    }
    }
    
    for tpr >= 0 && tpl >= 0 { 
        arr[tpa] = greater(arr[tpl],swap[tpr]) ? nn(arr, &tpl, T) : nn(swap, &tpr, T); tpa -= 1
    }
    for tpr >= 0 {
        arr[tpa] = swap[tpr]
        tpr -= 1
        tpa -= 1
    }
}

/*
from[sorted][sorted] -> dest[sorted]
first looks 8 elements ahead incase one slice has much larger inputs we skip until we get to actually merging
*/
cross_merge :: proc(dest, from: $A, left, right: int, greater: proc($T,T) -> bool){
    dest := dest; from := from

    ptl := 0
    ptr := left
    tpl := ptr - 1
    tpr := tpl + right

    // check if same length, so we can do parity merge
    if left + 1 >= right && right >= left && left >= 32 {
        if greater(from[ptl + 15], from[ptr]) &&
            !greater(from[ptl], from[ptr + 15]) &&
            greater(from[tpl],from[tpr - 15]) && 
            !greater(from[tpl - 15],from[tpr]) {
                parity_merge(dest, from, left, right, greater)
                return
            }
    }
    // dest
    ptd := 0
    tpd := left + right -1

    outer: for {
        if tpl - ptl > 8 {
            for !greater(from[ptl + 7], from[ptr]) {
                quad_copy(dest[ptd:], from[ptl:][:8])
                ptd += 8
                ptl += 8
                if tpl - ptl <= 8 {continue outer}
            }
            for greater(from[tpl - 7], from[tpr]) {
                tpd -= 7
                tpl -= 7
                quad_copy(dest[tpd:], from[tpl:][:8])
                tpd -= 1
                tpl -= 1
                if tpl - ptl <= 8 {continue outer}
            }
        }
        if tpr - ptr > 8 {
            for greater(from[ptl], from[ptr + 7]) {
                quad_copy(dest[ptd:], from[ptr:][:8])
                ptd += 8
                ptr += 8
                if tpr - ptr <= 8 {continue outer}
            }
            for !greater(from[tpl], from[tpr - 7]) {
                tpd -= 7
                tpr -= 7
                quad_copy(dest[tpd:], from[tpr:][:8])
                tpd -= 1
                tpr -= 1
                if tpr - ptr <= 8 {continue outer}
            }
        }
        if tpd - ptd < 16 {
            break outer
        }
        for _ in 0..<8 {
            dest[ptd] = !greater(from[ptl],from[ptr]) ? pp(from, &ptl, T) : pp(from, &ptr, T); ptd += 1
            dest[tpd] = greater(from[tpl],from[tpr]) ? nn(from, &tpl, T) : nn(from, &tpr, T); tpd -= 1
        }
    }
    for ptl <= tpl && ptr <= tpr {
        dest[ptd] = !greater(from[ptl], from[ptr]) ? pp(from, &ptl, T) : pp(from, &ptr, T)
        ptd += 1
    }
    for ptl <= tpl {
        dest[ptd] = from[ptl]
        ptd += 1
        ptl += 1
    }
    for ptr <= tpr {
        dest[ptd] = from[ptr]
        ptd += 1
        ptr += 1
    }

}


/*
from[[sorted],[sorted]] -> dest[sorted]
takes two sorted slices and merges them into a destination array from both endes at the same time
where left either equal or 1 smaller than right
*/
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
[unsorted] -> [sorted]
splits arr into 4 equal slices and sorts them into 1 slice recursevly
*/
tail_swap :: proc(arr, swap: $A, greater: proc($T,T) -> bool) {
    if len(arr) < 8 {
        tiny_sort(arr,swap,greater)
        return
    }
    half1 := len(arr) >> 1
    quad1 := half1 >> 1
    quad2 := half1 - quad1
    half2 := len(arr) - half1
    quad3 := half2 >> 1
    quad4 := half2 - quad3

    tail_swap(arr[:quad1],swap,greater)
    tail_swap(arr[quad1:][:quad2],swap,greater)
    tail_swap(arr[half1:][:quad3],swap,greater)
    tail_swap(arr[half1 + quad3:],swap,greater)

    if  !greater(arr[quad1 - 1],arr[quad1]) &&
        !greater(arr[half1 - 1], arr[half1]) && 
        !greater(arr[half1 + quad3 - 1], arr[half1 + quad3]) {
        return
    }
    
    parity_merge(swap, arr, quad1, quad2, greater)
    parity_merge(swap[half1:], arr[half1:],quad3, quad4, greater)
    parity_merge(arr,swap, half1, half2, greater)
}

/*
reverses the array
equal to slice.reverse() // TODO: test it on bigger types
*/
quad_reversal :: proc(arr: $A){
    arr := arr

    pta := 0
    ptz := len(arr) - 1
    loop := ptz / 2
    ptb := pta + loop
    pty := ptz - loop

    if loop % 2 == 0 {
        arr[pty], arr[ptb] = arr[ptb], arr[pty]
        ptb -= 1
        pty += 1
        loop -= 1
    }
    loop /= 2

    for {
        arr[ptz], arr[pta] = arr[pta], arr[ptz]
        pta += 1
        ptz -= 1

        arr[pty], arr[ptb] = arr[ptb], arr[pty]
        ptb -= 1
        pty += 1

        if loop == 0 do break
        loop -= 1
    }
}

/*
used to sort 4 sorted pairs arr: [[2],[2],[2],[2]] -> [8]
*/
quad_swap_merge :: proc(arr, swap: $A, greater: proc($T,T) -> bool){
    parity_merge_two(arr,swap,greater)
    parity_merge_two(arr[4:],swap[4:],greater)

    parity_merge_four(swap,arr,greater)
}

/*
used to sort 2 sorted quads arr: [[4],[4]] -> [8]
*/
parity_merge_four :: #force_inline proc(arr, swap: $A, greater: proc($T,T) -> bool) #no_bounds_check {
    arr := arr; swap := swap

    pts := 0; ptl := 0; ptr := 4
    swap[pts] = !greater(arr[ptl],arr[ptr]) ? pp(arr, &ptl, T) : pp(arr, &ptr, T); pts += 1
    swap[pts] = !greater(arr[ptl],arr[ptr]) ? pp(arr, &ptl, T) : pp(arr, &ptr, T); pts += 1
    swap[pts] = !greater(arr[ptl],arr[ptr]) ? pp(arr, &ptl, T) : pp(arr, &ptr, T); pts += 1
    swap[pts] = !greater(arr[ptl],arr[ptr]) ? arr[ptl] : arr[ptr]

    pts = 7; ptl = 3; ptr = 7
    swap[pts] = greater(arr[ptl],arr[ptr]) ? nn(arr, &ptl, T) : nn(arr, &ptr, T); pts -= 1
    swap[pts] = greater(arr[ptl],arr[ptr]) ? nn(arr, &ptl, T) : nn(arr, &ptr, T); pts -= 1
    swap[pts] = greater(arr[ptl],arr[ptr]) ? nn(arr, &ptl, T) : nn(arr, &ptr, T); pts -= 1
    swap[pts] = greater(arr[ptl],arr[ptr]) ? arr[ptl] : arr[ptr]
}

/*
used to sort 2 sorted pairs arr: [[2],[2]] -> [4]
*/
parity_merge_two :: #force_inline proc(arr, swap: $A, greater: proc($T,T) -> bool){
    arr := arr; swap := swap

    pts := 0; ptl := 0; ptr := 2
    swap[pts] = !greater(arr[ptl],arr[ptr]) ? pp(arr, &ptl, T) : pp(arr, &ptr, T); pts += 1
    swap[pts] = !greater(arr[ptl],arr[ptr]) ? arr[ptl] : arr[ptr]

    pts = 3; ptl = 1; ptr = 3
    swap[pts] = greater(arr[ptl],arr[ptr]) ? nn(arr, &ptl, T) : nn(arr, &ptr, T); pts -= 1
    swap[pts] = greater(arr[ptl],arr[ptr]) ? arr[ptl] : arr[ptr]
}

/*
sorts 0-7 elements
*/
tiny_sort :: proc(arr, swap: $A, greater: proc($T,T) -> bool){
    switch len(arr) {
        case 0:
        case 1:
        case 2:
            branchless_swap(arr, greater) 
        case 3:
            branchless_swap(arr, greater) 
            branchless_swap(arr[1:], greater) 
            branchless_swap(arr, greater) 
        case 4:
            paritry_swap_four(arr, greater) 
        case 5:
            paritry_swap_five(arr, greater) 
        case 6:
            paritry_swap_six(arr, swap, greater) 
        case 7:
            paritry_swap_seven(arr, swap, greater) 
    }
}
/*
sorting network for 4 elements
early return if mostly sorted
*/
paritry_swap_four :: #force_inline proc(arr: $A, greater: proc($T,T) -> bool){
    branchless_swap(arr,greater)
    branchless_swap(arr[2:],greater)
    if greater(arr[1],arr[2]) {
        arr[1], arr[2] = arr[2], arr[1]
        branchless_swap(arr,greater)
        branchless_swap(arr[2:],greater)
        branchless_swap(arr[1:],greater)
    }
}
/*
sorting network for 5 elements
early return if mostly sorted
*/
paritry_swap_five :: #force_inline proc(arr: $A, greater: proc($T,T) -> bool){
    branchless_swap(arr,greater)
    branchless_swap(arr[2:],greater)
    x := branchless_swap(arr[1:],greater)
    y := branchless_swap(arr[3:],greater)
    if (x + y) > 0 {
        branchless_swap(arr,greater)
        branchless_swap(arr[2:],greater)
        branchless_swap(arr[1:],greater)
        branchless_swap(arr[3:],greater)
        branchless_swap(arr,greater)
        branchless_swap(arr[2:],greater)
    }

}
/*
sorting network for 6 elements
early return if mostly sorted
*/
paritry_swap_six :: #force_inline proc(arr, swap:$A, greater: proc($T,T) -> bool){
    arr := arr; swap := swap
    
    branchless_swap(arr,greater) 
    branchless_swap(arr[1:],greater) 
    branchless_swap(arr[4:],greater)
    branchless_swap(arr[3:],greater)

    if !greater(arr[2],arr[3]) {
        branchless_swap(arr,greater)
        branchless_swap(arr[4:],greater)
        return
    }

    x := cast(int)(greater(arr[0],arr[1]))
    y := 1 - x
    swap[0] = arr[x]
    swap[1] = arr[y]
    swap[2] = arr[2]

    a := arr[4:]
    x = cast(int)(greater(a[0],a[1]))
    y = 1 - x
    swap[4] = a[x]
    swap[5] = a[y]
    swap[3] = arr[3]

    pta := 0; ptl := 0; ptr := 3
    arr[pta] = !greater(swap[ptl],swap[ptr]) ? pp(swap, &ptl, T) : pp(swap, &ptr, T); pta += 1
    arr[pta] = !greater(swap[ptl],swap[ptr]) ? pp(swap, &ptl, T) : pp(swap, &ptr, T); pta += 1
    arr[pta] = !greater(swap[ptl],swap[ptr]) ? pp(swap, &ptl, T) : pp(swap, &ptr, T); pta += 1
    
    pta = 5; ptl = 2; ptr = 5
    arr[pta] = greater(swap[ptl],swap[ptr]) ? nn(swap, &ptl, T) : nn(swap, &ptr, T); pta -= 1
    arr[pta] = greater(swap[ptl],swap[ptr]) ? nn(swap, &ptl, T) : nn(swap, &ptr, T); pta -= 1
    arr[pta] = greater(swap[ptl],swap[ptr]) ? swap[ptl] : swap[ptr]
}

/*
sorting network for 7 elements
early return if mostly sorted
*/
paritry_swap_seven :: #force_inline proc(arr, swap:$A, greater: proc($T,T) -> bool){
    arr := arr; swap := swap
     
    branchless_swap(arr,greater) 
    branchless_swap(arr[2:],greater) 
    branchless_swap(arr[4:],greater) 
    x := branchless_swap(arr[1:],greater)
    x += branchless_swap(arr[3:],greater)
    x += branchless_swap(arr[5:],greater)

    if x == 0 do return

    branchless_swap(arr[4:],greater)

    x = cast(int)(greater(arr[0],arr[1])) 
    swap[0] = arr[x]
    swap[1] = arr[1-x]
    swap[2] = arr[2]

    a := arr[3:]
    x = cast(int)(greater(a[0],a[1])) 
    swap[3] = a[x]
    swap[4] = a[1-x]

    a = arr[5:]
    x = cast(int)(greater(a[0],a[1])) 
    swap[5] = a[x]
    swap[6] = a[1-x]

    pta := 0; ptl := 0; ptr := 3
    arr[pta] = !greater(swap[ptl],swap[ptr]) ? pp(swap, &ptl, T) : pp(swap, &ptr, T); pta += 1
    arr[pta] = !greater(swap[ptl],swap[ptr]) ? pp(swap, &ptl, T) : pp(swap, &ptr, T); pta += 1
    arr[pta] = !greater(swap[ptl],swap[ptr]) ? pp(swap, &ptl, T) : pp(swap, &ptr, T); pta += 1
    
    pta = 6; ptl = 2; ptr = 6
    arr[pta] = greater(swap[ptl],swap[ptr]) ? nn(swap, &ptl, T) : nn(swap, &ptr, T); pta -= 1
    arr[pta] = greater(swap[ptl],swap[ptr]) ? nn(swap, &ptl, T) : nn(swap, &ptr, T); pta -= 1
    arr[pta] = greater(swap[ptl],swap[ptr]) ? nn(swap, &ptl, T) : nn(swap, &ptr, T); pta -= 1

    arr[pta] = greater(swap[ptl],swap[ptr]) ? swap[ptl] : swap[ptr]
}

/*
swap, but branchless
*/
branchless_swap :: #force_inline  proc(arr: $A, greater: proc($T,T) -> bool) -> int {
    arr := arr
    x := cast(int)greater(arr[0], arr[1])
	arr[0], arr[1] = arr[x], arr[1-x]
    return x
}

/*
to emulate  pointer++ behavior in c; x = cond() ? y++ : z++
*/
pp :: #force_inline proc(arr: $A, pointer: ^int, $T: typeid) -> T  #no_bounds_check {
    res := arr[pointer^]
    pointer^ += 1
    return res
}
/*
to emulate  pointer-- behavior in c; x = cond() ? y-- : z--
*/
nn :: #force_inline proc(arr: $A, pointer: ^int, $T: typeid) -> T #no_bounds_check {
    res := arr[pointer^]
    pointer^ -= 1
    return res
}
/*
functionally the same as any other rotate like slice.rotate() but slightly faster
// TODO: test on bigger types, bill is sneaky
*/
trinity_rotation :: proc(arr, swap: $A, left: int){
    bridge : int
    right := len(arr) - left
    left := left
    swap_size := min(len(swap), 65536)
    
    if left < right {
        if left <= swap_size {
            quad_copy(swap, arr[:left])
            quad_copy(arr, arr[left:])
            quad_copy(arr[right:], swap[:left])
        } else {
            pta, ptb, ptc, ptd : int
            pta = 0
            ptb = left
            bridge := right - left

            if bridge <= swap_size && bridge > 3 {
                ptc = right
                ptd = ptc + left

                quad_copy(swap, arr[ptb:][:bridge])

                for _ in 0..<left {
                    ptc -= 1
                    ptd -= 1
                    arr[ptc] = arr[ptd]
                    ptb -= 1
                    arr[ptd] = arr[ptb]
                }

                quad_copy(arr[pta:][:bridge], swap)
            } else {
                ptc = ptb
                ptd = ptc + right

                bridge = left / 2

                for ; bridge > 0; bridge -= 1 {
                    ptb -= 1
                    ptd -= 1
                    temp := arr[ptb];
                    arr[ptb] = arr[pta]
                    arr[pta] = arr[ptc]
                    arr[ptc] = arr[ptd]
                    arr[ptd] = temp
                    pta += 1
                    ptc += 1    
                }

                bridge = (ptd - ptc) / 2

                for ; bridge > 0; bridge -= 1 {
                    ptd -= 1
                    temp := arr[ptc];
                    arr[ptc] = arr[ptd]
                    arr[ptd] = arr[pta]
                    arr[pta] = temp
                    pta += 1
                    ptc += 1
                }

                bridge = (ptd - pta) / 2

                for ; bridge > 0; bridge -= 1 {
                    ptd -= 1
                    temp := arr[pta]
                    arr[pta] = arr[ptd]
                    arr[ptd] = temp
                    pta += 1
                }
            }
        }
    } else if right < left {
        if right <= swap_size {
            quad_copy(swap, arr[left:][:right])
            quad_copy(arr[right:], arr[:left])
            quad_copy(arr, swap[:right])
        }else {
            pta, ptb, ptc, ptd : int
            pta = 0
            ptb = left
            bridge := left - right

            if bridge <= swap_size && bridge > 3 {
                ptc = right
                ptd = ptc + left

                quad_copy(swap, arr[ptc:][:bridge])

                for _ in 0..<right {
                    arr[ptc] = arr[pta]
                    arr[pta] = arr[ptb]
                    pta += 1
                    ptb += 1
                    ptc += 1
                }

                quad_copy(arr[ptd - bridge:][:bridge], swap)
            } else {
                ptc = ptb
                ptd = ptc + right

                bridge = right / 2

                for ; bridge > 0; bridge -= 1 {
                    ptb -= 1
                    ptd -= 1
                    temp := arr[ptb];
                    arr[ptb] = arr[pta]
                    arr[pta] = arr[ptc]
                    arr[ptc] = arr[ptd]
                    arr[ptd] = temp
                    pta += 1
                    ptc += 1
                }

                bridge = (ptb - pta) / 2

                for ; bridge > 0; bridge -= 1 {
                    ptb -= 1
                    ptd -= 1
                    temp := arr[ptb]
                    arr[ptb] = arr[pta]
                    arr[pta] = arr[ptd]
                    arr[ptd] = temp
                    pta += 1
                }

                bridge = (ptd - pta) / 2

                for ; bridge > 0; bridge -= 1 {
                    ptd -= 1
                    temp := arr[pta]
                    arr[pta] = arr[ptd]
                    arr[ptd] = temp
                    pta += 1
                }
            }
        }
    } else {
        for i in 0..<left {
            arr[i], arr[i + left] = arr[i + left], arr[i]
        }
    }
}

/*
unfortunatly llvm doesnt produce branchless code for this by default
-mllvm -x86-cmov-converter=false works for c equivalent code

binary search that finds the first instance of val
*/
mono_bound_binary_first :: #force_inline proc(arr: $A, greater: proc($T,T) -> bool, val: T) -> int #no_bounds_check {

    end := len(arr)
    top := len(arr)

    for top > 1 {
        mid := top / 2

        if !greater(val, arr[end-mid]) {
            end -= mid
        }
        top -= mid
    }

    // this can read at arr[-1], but that is safe since arr is always right of more data and arr[-1] > val 
    if !greater(val,arr[end - 1]){
        end -= 1
    }

    return end
}

rotate_merge_block :: proc(arr, swap: $A, lblock: int, greater: proc($T,T) -> bool){
    if !greater(arr[lblock - 1], arr[lblock]) {
        return
    }

    rblock := lblock / 2
    lblock := lblock - rblock

    // take 1st element in rblock and search the first on the 2nd half where to rotate into
    // swap rblock with left until they can be merged
    // [ lblock ] [ rblock ] [ left ] [ right ]
    left := mono_bound_binary_first(arr[lblock + rblock:], greater, arr[lblock])


    right := len(arr) - left - rblock - lblock 
    if left > 0 {
        if lblock + left <= len(swap) {
            quad_copy(swap, arr[:lblock])
            quad_copy(swap[lblock:], arr[lblock+rblock:][:left])
            quad_copy(arr[lblock+left:],arr[lblock:][:rblock])

            cross_merge(arr, swap, lblock, left, greater)
        } else {
            trinity_rotation(arr[lblock:][:rblock+left], swap, rblock)
            unbalanced := (left * 2 < lblock) || (lblock * 2 < left)
            if unbalanced && left <= len(swap){
                partial_backward_merge(arr[:lblock + left], swap, lblock, greater)
            } else if unbalanced && lblock <= len(swap) {
                partial_forward_merge(arr[:lblock + left], swap, lblock, greater)
            } else {
                rotate_merge_block(arr[:lblock + left], swap, lblock, greater)
            }
        }
    }

    if right > 0 {
        unbalanced := (right * 2 < rblock) || (rblock * 2 < right) 
        if unbalanced && right <= len(swap) || right + rblock <= len(swap) {
            partial_backward_merge(arr[lblock + left:], swap, rblock  , greater)
        } else if unbalanced && rblock <= len(swap) {
            partial_forward_merge(arr[lblock + left:], swap, rblock , greater)
        } else {
            rotate_merge_block(arr[lblock + left:], swap, rblock, greater)
        }
    }

}

quad_copy :: proc(arr, swap: $A){
    when intrinsics.type_is_slice(A) {
        copy(arr, swap)
    } else {
        arr := arr; swap := swap
        length := min(len(arr),len(swap))
        for i in 0..<length {
            arr[i] = swap[i]
        }
    }
}
