package blit

import "base:runtime"
import "base:intrinsics"


// BLIT_OUT <= BLIT_AUX
// BLIT_OUT >= 32
BLIT_AUX :: 512
BLIT_OUT :: 96

/*
fist pass, checks the array for sortedness, returns early on sorted, reverse sorted, chooses future strategy
*/
blit_analyze :: proc(arr, swap: $A, greater: proc($T,T) -> bool){ 
    arr := arr; swap := swap
    abalance, bbalance, cbalance, dbalance : int
    astreaks, bstreaks, cstreaks, dstreaks : int
    asum, bsum, csum, dsum : int
    cnt : int

    half1 := len(arr) >> 1
    quad1 := half1 >> 1
    quad2 := half1 - quad1
    half2 := len(arr) - half1
    quad3 := half2 >> 1
    quad4 := half2 - quad3

    pta := 0; ptb := quad1; ptc := half1; ptd := half1 + quad3

    for cnt = len(arr); cnt > 132; cnt -= 128 {
        asum, bsum, csum, dsum = 0,0,0,0
        for _ in 0..<32 {
            asum += cast(int)greater(arr[pta], arr[pta+1]); pta += 1
            bsum += cast(int)greater(arr[ptb], arr[ptb+1]); ptb += 1
            csum += cast(int)greater(arr[ptc], arr[ptc+1]); ptc += 1
            dsum += cast(int)greater(arr[ptd], arr[ptd+1]); ptd += 1
        }
        abalance += asum; asum = cast(int)((asum == 0) | (asum == 32)); astreaks += asum
        bbalance += bsum; bsum = cast(int)((bsum == 0) | (bsum == 32)); bstreaks += bsum
        cbalance += csum; csum = cast(int)((csum == 0) | (csum == 32)); cstreaks += csum
        dbalance += dsum; dsum = cast(int)((dsum == 0) | (dsum == 32)); dstreaks += dsum

        if cnt > 516 && asum + bsum + csum + dsum == 0 {
            abalance += 48; pta += 96
            bbalance += 48; ptb += 96
            cbalance += 48; ptc += 96
            dbalance += 48; ptd += 96
            cnt -= 384
        }
    }

    for ;cnt > 7; cnt -= 4 {
        abalance += cast(int)greater(arr[pta], arr[pta+1]); pta += 1
        bbalance += cast(int)greater(arr[ptb], arr[ptb+1]); ptb += 1
        cbalance += cast(int)greater(arr[ptc], arr[ptc+1]); ptc += 1
        dbalance += cast(int)greater(arr[ptd], arr[ptd+1]); ptd += 1
    }

    if quad1 < quad2 {bbalance += cast(int)greater(arr[ptb], arr[ptb + 1]); ptb += 1}
    if quad1 < quad3 {cbalance += cast(int)greater(arr[ptc], arr[ptc + 1]); ptc += 1}
    if quad1 < quad4 {dbalance += cast(int)greater(arr[ptd], arr[ptd + 1]); ptd += 1}

    cnt = abalance + bbalance + cbalance + dbalance

    if cnt == 0 {
        if !greater(arr[pta], arr[pta + 1]) &&
           !greater(arr[ptb], arr[ptb + 1]) &&
           !greater(arr[ptc], arr[ptc + 1]) {
            return
        }
    }

    asum = int((quad1 - abalance) == 1)
    bsum = int((quad2 - bbalance) == 1)
    csum = int((quad3 - cbalance) == 1)
    dsum = int((quad4 - dbalance) == 1)

    if (asum | bsum | csum | dsum) > 0 {
        span1 := int(asum > 0 && bsum > 0) * int(greater(arr[pta], arr[pta+1]))
        span2 := int(bsum > 0 && csum > 0) * int(greater(arr[ptb], arr[ptb+1]))
        span3 := int(csum > 0 && dsum > 0) * int(greater(arr[ptc], arr[ptc+1]))
        switch (span1 + span2 * 2 + span3 * 4) {
            case 0:
            case 1: quad_reversal(arr[:half1]); abalance, bbalance = 0,0
            case 2: quad_reversal(arr[quad1:][:quad2+quad3]); bbalance, cbalance = 0,0
            case 3: quad_reversal(arr[:half1+quad3]); abalance, bbalance, cbalance = 0,0,0
            case 4: quad_reversal(arr[half1:]); cbalance, dbalance = 0,0
            case 5: quad_reversal(arr[:half1]); quad_reversal(arr[half1:]); abalance,bbalance, cbalance,dbalance = 0,0,0,0
            case 6: quad_reversal(arr[quad1:]); bbalance, cbalance, dbalance = 0,0,0
            case 7: quad_reversal(arr); return
        }

        if asum > 0 && abalance > 0 {quad_reversal(arr[:quad1]); abalance = 0}
        if bsum > 0 && bbalance > 0 {quad_reversal(arr[quad1:][:quad2]); bbalance = 0}
        if csum > 0 && cbalance > 0 {quad_reversal(arr[half1:][:quad3]); cbalance = 0}
        if dsum > 0 && dbalance > 0 {quad_reversal(arr[half1+quad3:]); dbalance = 0}
    }

    // cnt = len(arr) / 256 // TODO: test speed
    cnt = len(arr) / 512

    asum = int(astreaks > cnt)
    bsum = int(bstreaks > cnt)
    csum = int(cstreaks > cnt)
    dsum = int(dstreaks > cnt)


    // TODO: test cache cutoff
    // if quad1 > quad_cache {
    //     asum, bsum,csum,dsum = 1,1,1,1
    // }


    switch asum + bsum << 1 + csum << 2 + dsum << 3 {
        case 0: 
            blit_partition(arr, swap, greater)
            return
        case 1:
            if abalance > 0  {quadsort_swap(arr[:quad1], swap, greater)}
            blit_partition(arr[quad1:],swap, greater)
        case 2:
            blit_partition(arr[:quad1],swap, greater)
            if bbalance  > 0 {quadsort_swap(arr[quad1:][:quad2], swap, greater)}
            blit_partition(arr[half1:], swap, greater)
        case 3:
            if abalance > 0 {quadsort_swap(arr[:quad1], swap, greater)}
            if bbalance > 0 {quadsort_swap(arr[quad1:][:quad2], swap, greater)}
            blit_partition(arr[half1:], swap, greater)
        case 4:
            blit_partition(arr[:half1], swap, greater)
            if cbalance > 0  {quadsort_swap(arr[half1:][:quad3], swap, greater)}
            blit_partition(arr[quad3 + half1:], swap, greater)
        case 8:
            blit_partition(arr[:half1+quad3], swap, greater)
            if dbalance > 0  {quadsort_swap(arr[half1+quad3:], swap, greater)}
        case 9:
            if abalance > 0  {quadsort_swap(arr[:quad1], swap, greater)}
            blit_partition(arr[quad1:][:quad2+quad3], swap, greater)
            if dbalance > 0  {quadsort_swap(arr[half1+quad3:], swap, greater)}
        case 12:
            blit_partition(arr[:half1], swap, greater)
            if cbalance > 0  {quadsort_swap(arr[half1:][:quad3], swap, greater)}
            if dbalance > 0  {quadsort_swap(arr[half1+quad3:], swap, greater)}
        case:
            if asum > 0 {
                if abalance > 0  {quadsort_swap(arr[:quad1], swap, greater)}
            } else {blit_partition(arr[:quad1], swap, greater)}
            if bsum > 0 {
                if bbalance > 0  {quadsort_swap(arr[quad1:][:quad2], swap, greater)}
            } else {blit_partition(arr[quad1:][:quad2], swap, greater)}
            if csum > 0 {
                if cbalance > 0  {quadsort_swap(arr[half1:][:quad3], swap, greater)}
            } else {blit_partition(arr[half1:][:quad3], swap, greater)}
            if dsum > 0 {
                if dbalance > 0  {quadsort_swap(arr[half1 + quad3:], swap, greater)}
            } else {blit_partition(arr[half1 + quad3:], swap, greater)}
    }

    if !greater(arr[pta], arr[pta+1]) {
        if !greater(arr[ptc], arr[ptc+1]) {
            if !greater(arr[ptb], arr[ptb+1]) {
                return
            } 
        } else {
            rotate_merge_block(arr[half1:], swap, quad3, greater)
        }
    } else {
        rotate_merge_block(arr[:half1], swap, quad1, greater)
        if greater(arr[ptc], arr[ptc+1]) {
            rotate_merge_block(arr[half1:], swap, quad3, greater)
        }
    }
    rotate_merge_block(arr, swap, half1, greater)
}


binary_median :: #force_inline proc(arr1, arr2: $A, greater: proc($T,T) -> bool) -> T {
    arr1 := arr1; arr2 := arr2
    pt1, pt2 : int
    n := len(arr1)

    for n >>= 1 ;n > 0; n >>= 1 {
        if !greater(arr1[pt1 + n], arr2[pt2 + n]) {
            pt1 += n
        } else {
            pt2 += n
        }
    }

    return greater(arr1[pt1], arr2[pt2]) ? arr1[pt1] : arr2[pt2]
}


trim_four :: #force_inline proc(arr: $A, greater: proc($T,T) -> bool){
    arr := arr
    x := cast(int)greater(arr[0], arr[1]); arr[1], arr[0] = arr[1-x], arr[x]
    x = cast(int)greater(arr[2], arr[3]); arr[3], arr[2] = arr[3-x], arr[x+2]
    
    x = 2*cast(int)!greater(arr[0], arr[2]); arr[2] = arr[x]
    x = 2*cast(int)greater(arr[1], arr[3]); arr[1] = arr[x+1]
}


median_of_nine :: #force_inline proc(arr, swap: $A,  greater: proc($T,T) -> bool) -> T {
    arr := arr; swap := swap

    pta : int
    div := len(arr) / 9

    for x := 0; x < 9; x += 1 {
        swap[x] = arr[pta]
        pta += div
    }

    trim_four(swap,greater)
    trim_four(swap[4:],greater)

    swap[0] = swap[5]
    swap[3] = swap[8]

    trim_four(swap,greater)
    swap[0] = swap[6]

    x := cast(int)greater(swap[0], swap[1])
    y := cast(int)greater(swap[0], swap[2])
    z := cast(int)greater(swap[1], swap[2])

    return swap[cast(int)(x == y) + (y ~ z)]
}



median_of_cbrt :: #force_inline proc(arr, swap: $A, greater: proc($T,T) -> bool) -> (T, bool) {
    arr := arr; swap := swap

    cbrt : int
    for cbrt = 32; len(arr) > cbrt * cbrt * cbrt; cbrt <<= 1 {}
    div := len(arr) / cbrt

    pta := 0

    for cnt := 0;  cnt < cbrt; cnt += 1 {
        swap[cnt] = arr[pta]
        pta += div
    }

    h1 := 0
    h2 := cbrt / 2
    

    for cnt := cbrt / 8; cnt > 0; cnt -= 1 {
        trim_four(swap[h1:], greater)
        trim_four(swap[h2:], greater)

        swap[h1] = swap[h2 + 1]
        swap[h1+3] = swap[h2 + 2]

        h1 += 4
        h2 += 4
    }
    cbrt /= 4

    quadsort_swap(swap[:cbrt], swap[cbrt*2:], greater)
    quadsort_swap(swap[cbrt:][:cbrt], swap[cbrt*2:], greater)

    return binary_median(swap[:cbrt], swap[cbrt:][:cbrt], greater), !greater(swap[cbrt*2-1], swap[0])
}

reverse_partition :: proc(arr, swap: $A, greater: proc($T,T) -> bool, piv: T) -> int{
    arr := arr; swap := swap

    if len(arr) > len(swap) {
        half := len(arr) / 2
        l := reverse_partition(arr[:half], swap, greater, piv)
        r := reverse_partition(arr[half:], swap, greater, piv)

        trinity_rotation(arr[l:half + r], swap, half - l)

        return l + r
    }

    pta := 0
    m := 0
    val : int
    for cnt := len(arr) / 4; cnt > 0; cnt -= 1 {
        val = cast(int)greater(piv, arr[pta]); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
        val = cast(int)greater(piv, arr[pta]); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
        val = cast(int)greater(piv, arr[pta]); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
        val = cast(int)greater(piv, arr[pta]); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
    }
    for cnt := len(arr) % 4; cnt > 0; cnt -= 1 {
        val = cast(int)greater(piv, arr[pta]); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
    }
    blit_copy(arr[m:], swap)

    return m
}

default_partition :: proc(arr, swap: $A, greater: proc($T,T) -> bool, piv: T) -> int{
    arr := arr; swap := swap

    if len(arr) > len(swap) {
        half := len(arr) / 2
        l := default_partition(arr[:half], swap, greater, piv)
        r := default_partition(arr[half:], swap, greater, piv)

        trinity_rotation(arr[l:half + r], swap, half - l)

        return l + r
    }

    pta := 0
    m := 0
    val : int
    for cnt := len(arr) / 4; cnt > 0; cnt -= 1 {
        val = cast(int)!greater(arr[pta], piv); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
        val = cast(int)!greater(arr[pta], piv); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
        val = cast(int)!greater(arr[pta], piv); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
        val = cast(int)!greater(arr[pta], piv); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
    }
    for cnt := len(arr) % 4; cnt > 0; cnt -= 1 {
        val = cast(int)!greater(arr[pta], piv); swap[pta-m], arr[m] = arr[pta], arr[pta]; pta += 1; m += val
    }
    blit_copy(arr[m:], swap)

    return m
}

blit_partition :: proc(arr, swap: $A, greater: proc($T,T) -> bool){
    arr := arr; swap := swap
    n := len(arr)

    piv, max : T
    a_size, s_size : int = 0,0
    generic : bool
    for {
        if n <= 2048 {
            piv = median_of_nine(arr[:n], swap, greater)
        } else {
            piv, generic = median_of_cbrt(arr[:n], swap, greater)
            if generic {
                quadsort_swap(arr[:n], swap, greater)
                return
            }
        }

        if a_size > 0 && !greater(max, piv) {
            a_size = reverse_partition(arr[:n], swap, greater, piv)
            s_size = n - a_size

            if s_size <= a_size / 16 || a_size <= BLIT_OUT {
                quadsort_swap(arr[:a_size], swap, greater)
                return
            }
            n = a_size
            a_size = 0
            continue
        }

        a_size = default_partition(arr[:n], swap, greater, piv)
        s_size = n - a_size

        if a_size <= s_size / 16 || s_size <= BLIT_OUT {
            if s_size == 0 {
                a_size = reverse_partition(arr[:a_size], swap, greater, piv)
                s_size = n - a_size

                if s_size <= a_size / 16 || a_size <= BLIT_OUT {
                    quadsort_swap(arr[:a_size], swap, greater)
                    return 
                }
                n = a_size
                a_size = 0
                continue
            }

            quadsort_swap(arr[a_size:][:s_size], swap, greater)
        } else {
            blit_partition(arr[a_size:][:s_size], swap, greater)
        }

        if s_size <= a_size / 16 || a_size <= BLIT_OUT {
            quadsort_swap(arr[:a_size], swap, greater)
            return
        }
        n = a_size
        max = piv
    }

    
}

// arr can be either slice or #soa
// stable, inplace sorting algorithm, [512]T stack space used
// greater sort in ascending order when l > r | proc(l,t:int)->bool{return l > r}
blitsort :: proc(arr: $A, greater: proc($T,T) -> bool){
    when intrinsics.type_is_slice(A) {
        swap : [BLIT_AUX]T
    } else {
        swap : #soa[BLIT_AUX]T
    }

    if len(arr) <= 132 {
        quadsort_swap(arr, swap[:], greater)
        return
    }
    blit_analyze(arr, swap[:], greater)
}

// can be called with more than 512 space, but this isnt tested, but there shouldnt be a reason this doesnt work
// blitsort_swap :: proc(arr, swap: $A, greater: proc($T,T) -> bool){
//     if len(arr) <= 132 {
//         quadsort_swap(arr, swap, greater)
//         return
//     }
//     blit_analyze(arr, swap, greater)
// }

blit_copy :: quad_copy
