package ref

import "base:builtin"

Ordering :: enum {
	Less    = -1,
	Equal   =  0,
	Greater = +1,
}

Generic_Cmp :: #type proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering


qsort :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr) {
    if width <= 16 {
        prev_pivot : [16]byte
        quicksort_small(data, length, width, cmp, arg, prev_pivot[:])
    } else {
        quicksort_big(data, length, width, cmp, arg)
    }
}



swap_small :: proc(left, right: [^]byte, width: uint) {
    assert(width <= 16)
    swap : [16]byte = ---
    copy(swap[:],left[:width])
    copy(left[:width],right[:width])
    copy(right[:width], swap[:])
}
move :: proc(to, from: [^]byte, width: uint) {
    copy(to[:width],from[:width])
}

// joinked from _smoothsort, thanks bill
cycle :: proc "contextless" (width: uint, data: [][^]byte, n: int) {
    if len(data) < 2 {
        return
    }
    buf: [256]u8 = ---
    data[n] = raw_data(buf[:])
    width := width
    for width != 0 {
        l := builtin.min(size_of(buf), int(width))
        copy(data[n][:l], data[0][:l])
        for i in 0..<n {
            copy(data[i][:l], data[i+1][:l])
            data[i] = data[i][l:]
        }
        width -= uint(l)
    }
}
swap_big :: proc "contextless" (left, right: [^]byte, width: uint) {
    buf: [256]u8 = ---
    data : [3][^]byte = ---
    data[0] = left
    data[1] = right
    n := 2
    data[2] = raw_data(buf[:])
    width := width
    for width != 0 {
        l := builtin.min(size_of(buf), int(width))
        copy(data[n][:l], data[0][:l])
        for i in 0..<n {
            copy(data[i][:l], data[i+1][:l])
            data[i] = data[i][l:]
        }
        width -= uint(l)
    }
}



piposort_big :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg: rawptr) {
    indecies : [64][^]byte = ---
    for i in 0..<length {
        indecies[i] = data[i*width:]
    }

    pipo_rec_indecies(indecies[:length], length, cmp, arg)

    for i in 0..<length {
        cur_index := indecies[i]
        base_index := data[i*width:]
        if cur_index == base_index {continue}
        buf : [65][^]byte = ---
        n := 0
        buf[n] = cur_index
        for {
            n += 1
            diff := uint(uintptr(cur_index) - uintptr(data)) / width
            cur_index = indecies[diff]
            indecies[diff] = data[diff*width:]
            buf[n] = cur_index
            if cur_index == base_index {break}
        }

        cycle(width,buf[:],n+1)
    }
}

pipo_rec_indecies :: proc(indecies:[][^]byte, length: uint, cmp: Generic_Cmp, arg: rawptr) {
    if length <= 8 {
        odd_even_sort_indecies(indecies, length, cmp, arg)
        return
    }
    half1 := length >> 1
    quad1 := half1 >> 1
    quad2 := half1 - quad1
    half2 := length - half1
    quad3 := half2 >> 1
    quad4 := half2 - quad3

    pipo_rec_indecies(indecies,quad1,cmp,arg)
    pipo_rec_indecies(indecies[quad1:],quad2,cmp,arg)
    pipo_rec_indecies(indecies[half1 :],quad3,cmp,arg)
    pipo_rec_indecies(indecies[half1 + quad3:],quad4,cmp,arg)

    s : [64][^]byte = ---
    swap := s[:]

    parity_merge_indecies(swap, indecies, quad1, quad2, cmp, arg)
    parity_merge_indecies(swap[half1:], indecies[half1:], quad3, quad4, cmp, arg)
    parity_merge_indecies(indecies, swap, half1, half2, cmp, arg)
}

pipo_rec_swap :: proc(data: [^]byte,swap:[]byte, length, width: uint, cmp: Generic_Cmp, arg: rawptr) {
    if length <= 8 {
        odd_even_sort(data, length, width, cmp, arg)
        return
    }

    half1 := length >> 1
    quad1 := half1 >> 1
    quad2 := half1 - quad1
    half2 := length - half1
    quad3 := half2 >> 1
    quad4 := half2 - quad3

    pipo_rec_swap(data,swap,quad1,width,cmp,arg)
    pipo_rec_swap(data[quad1 * width:],swap,quad2,width,cmp,arg)
    pipo_rec_swap(data[half1 * width:],swap,quad3,width,cmp,arg)
    pipo_rec_swap(data[(half1 + quad3) * width:],swap,quad4,width,cmp,arg)

    swap := raw_data(swap[:])
    parity_merge(swap, data, quad1, quad2, width, cmp, arg)
    parity_merge(swap[half1 * width:], data[half1 * width:], quad3, quad4, width, cmp, arg)
    parity_merge(data, swap, half1, half2, width, cmp, arg)

}

piposort_small :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg: rawptr) {
    if length <= 8 {
        odd_even_sort(data, length, width, cmp, arg)
        return
    }
    half1 := length >> 1
    quad1 := half1 >> 1
    quad2 := half1 - quad1
    half2 := length - half1
    quad3 := half2 >> 1
    quad4 := half2 - quad3

    piposort_small(data,quad1,width,cmp,arg)
    piposort_small(data[quad1 * width:],quad2,width,cmp,arg)
    piposort_small(data[half1 * width:],quad3,width,cmp,arg)
    piposort_small(data[(half1 + quad3) * width:],quad4,width,cmp,arg)

    s : [64 * 16]byte = ---
    swap := raw_data(s[:])

    parity_merge(swap, data, quad1, quad2, width, cmp, arg)
    parity_merge(swap[half1 * width:], data[half1 * width:], quad3, quad4, width, cmp, arg)
    parity_merge(data, swap, half1, half2, width, cmp, arg)
}

parity_merge :: proc(dest, from: [^]byte, left, right, width: uint, cmp: Generic_Cmp, arg: rawptr) {
    head_left := from
    head_right := from[left * width:]
    head_dest := dest
    tail_left := head_right[-width:]
    tail_right := tail_left[right * width:]
    tail_dest := dest[(left + right - 1) * width:]

    if left < right {
        head_merge(&head_dest,&head_left,&head_right,width,cmp,arg)
    }
    head_merge(&head_dest,&head_left,&head_right,width,cmp,arg)

    left := left - 1
    for left > 0 {
        head_merge(&head_dest,&head_left,&head_right,width,cmp,arg)
        tail_merge(&tail_dest,&tail_left,&tail_right,width,cmp,arg)
        left -= 1
    }
    last := cmp(tail_left, tail_right, arg) == .Greater ? tail_left : tail_right
    copy(tail_dest[:width],last[:width])
}

parity_merge_indecies :: proc(dest, from: [][^]byte, left, right: uint, cmp: Generic_Cmp, arg: rawptr) {
    head_left :uint= 0
    head_right :uint= left
    head_dest :uint= 0
    tail_left :uint= head_right - 1
    tail_right :uint= tail_left + right
    tail_dest :uint= left + right - 1

    if left < right {
        dest[head_dest] = cmp(from[head_left],from[head_right], arg) != .Greater ? ppp(from, &head_left) : ppp(from, &head_right); head_dest += 1    
    }
    dest[head_dest] = cmp(from[head_left],from[head_right], arg) != .Greater ? ppp(from, &head_left) : ppp(from, &head_right); head_dest += 1

    for left := left - 1; left > 0; left -= 1 {
        dest[head_dest] = cmp(from[head_left],from[head_right], arg) != .Greater ? ppp(from, &head_left) : ppp(from, &head_right); head_dest += 1
        dest[tail_dest] = cmp(from[tail_left],from[tail_right], arg) == .Greater ? nnn(from, &tail_left) : nnn(from, &tail_right); tail_dest -= 1
    }
    
    dest[tail_dest] = cmp(from[tail_left],from[tail_right], arg) == .Greater ? from[tail_left] : from[tail_right]
}

ppp :: #force_inline proc(arr: [][^]byte, pointer: ^uint) -> [^]byte  #no_bounds_check {
    res := arr[pointer^]
    pointer^ += 1
    return res
}
/*
to emulate  pointer-- behavior in c; x = cond() ? y-- : z--
*/
nnn :: #force_inline proc(arr: [][^]byte, pointer: ^uint) -> [^]byte #no_bounds_check {
    res := arr[pointer^]
    pointer^ -= 1
    return res
}

head_merge :: proc(dest, left, right: ^[^]byte, width: uint, cmp: Generic_Cmp, arg: rawptr){
    x := width * cast(uint)(cmp(left^, right^, arg) != .Greater)
    copy(dest[:width],left[:width])
    left^ = left[x:]
    copy(dest[x:][:width], right[:width])
    right^ = right[width - x:]
    dest^ = dest[width:]
}

tail_merge :: proc(dest, left, right: ^[^]byte, width: uint, cmp: Generic_Cmp, arg: rawptr){
    y := width * cast(uint)(cmp(left^, right^, arg) != .Greater)
    copy(dest[:width],left[:width])
    left^ = left[-(width - y):]
    dest^ = dest[-width:]
    copy(dest[y:][:width], right[:width])
    right^ = right[-y:]
}


odd_even_sort :: proc(arr: [^]byte, length, width: uint, cmp: Generic_Cmp, arg: rawptr) {
    switch length {
        case 0,1: return
        case 2:
            branchless_swap(arr,width,cmp,arg)
        case 3:
            branchless_swap(arr,width,cmp,arg)
            branchless_swap(arr[width:],width,cmp,arg)
            branchless_swap(arr,width,cmp,arg)
        case:
            odd :uint= 0
            change :uint= 1
            for {
                for i := odd; i < length * width - width; i += 2 * width {
                    array := arr[i:]
                    x := branchless_swap(array,width,cmp,arg)
                    change |= x
                }
                if change == 0 {break}
                odd = width - odd
                change = 0
            }
    }
}
branchless_swap :: #force_inline  proc(arr: [^]byte, width: uint, cmp: Generic_Cmp, arg: rawptr) -> uint #no_bounds_check  {
    x := width * cast(uint)(cmp(arr, arr[width:],arg) == .Greater)
    y := width - x
    swap : [16]byte = ---
    copy(swap[:],arr[y:][:width])
    copy(arr[:width],arr[x:][:width])
    copy(arr[width:][:width], swap[:])
    return x
}

odd_even_sort_indecies :: proc(indecies: [][^]byte, length: uint, cmp: Generic_Cmp, arg: rawptr) {
    switch length {
        case 0,1: return
        case 2:
            branchless_swap_indecies(indecies,cmp,arg)
        case 3:
            branchless_swap_indecies(indecies,cmp,arg)
            branchless_swap_indecies(indecies[1:],cmp,arg)
            branchless_swap_indecies(indecies,cmp,arg)
        case:
            odd :uint= 0
            change :uint= 1
            for {
                for i := odd; i < length - 1; i += 2 {
                    array := indecies[i:]
                    x := branchless_swap_indecies(array,cmp,arg)
                    change |= x
                }
                if change == 0 {break}
                odd = 1 - odd
                change = 0
            }
    }
}
branchless_swap_indecies :: #force_inline  proc(indecies: [][^]byte, cmp: Generic_Cmp, arg: rawptr) -> uint #no_bounds_check  {
    x := cast(uint)(cmp(indecies[0], indecies[1],arg) == .Greater)
    indecies[0],indecies[1] = indecies[x], indecies[1-x]
    return x
}


quicksort_small :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg: rawptr, prev_pivot: []byte) {
    length := length
    data := data

    for {
        if length <= 64 {
            piposort_small(data, length, width, cmp, arg)
            return
        }

        generic : bool
        pivot : [16]byte = ---
        if length <= 2048  {
            median_9_small(data, length, width, cmp, arg, &generic, pivot[:])
        } else {
            median_cbrt_small(data, length, width, cmp, arg, &generic, pivot[:])

        }

        // the first time we dont have a priv pivot, i could add acheck for that, but this should happen so rarly it doesnt really matter
        // also its only a small slowdown nothing to worry about
        if !generic && cmp(raw_data(pivot[:]), raw_data(prev_pivot[:]),arg) == .Equal {
            generic = true
        }

        copy(prev_pivot[:], pivot[:])

        data_offset, new_length : uint
        
        if generic {
            left_len, right_len := partition_generic_small(data, length, width, cmp, arg, pivot[:])

            data_offset = width * (length - right_len)
            new_length = right_len

            length = left_len
        } else {
            left_len := partition_small(data, length, width, cmp, arg, pivot[:])

            data_offset = width * left_len
            new_length = length - left_len

            length = left_len
        }

        // we recurse into the small partition, no stack explosion
        if new_length < length {
            quicksort_small(data[data_offset:], new_length, width, cmp, arg, prev_pivot)
        } else {
            quicksort_small(data, length, width, cmp, arg, prev_pivot)
            data = data[data_offset:]
            length = new_length
        }
    }
}

median_cbrt_small  :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr, generic: ^bool, pivot: []byte) {
    cbrt : uint
    switch {
        case length < 32 * 32 * 32: cbrt = 32 / 4
        case length < 64 * 64 * 64: cbrt = 64 / 4
        case length < 128 * 128 * 128: cbrt = 128 / 4
        case: cbrt = 256 / 4
    }
    div := length / (cbrt * 4) * width
    ptr := data

    s : [64 * 16]byte = ---
    swap := raw_data(s[:])
    s2 : [8 * 16]byte = ---
    swap_t := raw_data(s2[:])
    swap_ptr := swap
    for i in uint(0)..<cbrt/2 {
        for j in uint(0)..<8 {
            copy(swap_t[j*width:][:width],ptr[:width])
            ptr = ptr[div:]
            
        }
        trim_four(swap_t,width,cmp,arg)
        trim_four(swap_t[width * 4:],width,cmp,arg)
        copy(swap_t[3*width:][:2*width],swap_t[5*width:][:2*width])
        trim_four(swap_t[width * 1:],width,cmp,arg)

        copy(swap_ptr[:width*2],swap_t[2*width:][:width*2])
        swap_ptr = swap_ptr[width*2:]
    }

    piposort_small(swap,cbrt,width,cmp,arg)
    cbrt = cbrt / 2
    copy(pivot,swap[cbrt * width:][:width])
    cbrt = cbrt / 2

    if cmp(swap[cbrt * 3 * width:], swap[cbrt * 1 * width:], arg) == .Equal { // this might need a lot of tuning -_-
        generic^ = true
    }
}

trim_four :: proc(data: [^]byte, width: uint, cmp: Generic_Cmp, arg:rawptr){
    branchless_swap(data,width,cmp,arg)
    branchless_swap(data[width*2:],width,cmp,arg)

    x := 2 * width * cast(uint)(cmp(data, data[width*2:],arg) != .Greater)
    copy(data[width*2:][:width],data[x:][:width])

    data := data[width:]
    y := 2 * width * cast(uint)(cmp(data, data[width*2:],arg) == .Greater)
    copy(data[:width],data[y:][:width])
}


median_9_small :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr, generic: ^bool, pivot: []byte) {
    div := length / 9
    s : [9 * 16]byte = ---
    swap := raw_data(s[:])

    ptr := data[div / 2 * width:]
    div *=  width
    for i in uint(0)..<9 {
        
        s := swap[width * i:]
        copy(s[:width], ptr[:width])

        ptr = ptr[div:]
    }

    odd_even_sort(swap,9,width,cmp,arg)

    // this might need tuning -_-
    if cmp(swap[3*width:], swap[5*width:], arg) == .Equal {
        generic^ = true
    }

    copy(pivot[:width],swap[4*width:][:width])
}

partition_small :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr, pivot: []byte) -> uint {
    left := data
    right := data[(length-1)*width:]
    pivot := raw_data(pivot)
    BLOCK_SIZE :: 64
    offset_l, offset_r : [BLOCK_SIZE][^]byte
    num_l, num_r : uint = 0, 0
    
    for int(uintptr(right)) - int(uintptr(left)) >= int(BLOCK_SIZE * width - width) {
        if num_l == 0 {
            for i in 0..<BLOCK_SIZE {
                offset_l[num_l] = left
                num_l += cast(uint)(cmp(left,pivot,arg) == .Greater)
                left = left[width:]
            }
        } else {
            for i in 0..<BLOCK_SIZE {
                offset_r[num_r] = right
                num_r += cast(uint)(cmp(right,pivot,arg) == .Less)
                right = right[-width:]
            }
        }
        
        num := builtin.min(num_l, num_r)
    
        if num > 0 {
            block_swap(data, width,offset_l,offset_r,num_l,num_r,num)
        }
        num_l -= num
        num_r -= num
    }

    unknown := (int(uintptr(right)) - int(uintptr(left))) / int(width) + 1

    if num_l == 0 {
        for i in 0..<unknown {
            offset_l[num_l] = left
            num_l += cast(uint)(cmp(left,pivot,arg) == .Greater)
            left = left[width:]
        }
    } else {
        for i in 0..<unknown {
            offset_r[num_r] = right
            num_r += cast(uint)(cmp(right,pivot,arg) == .Less)
            right = right[-width:]
        }
    }

    num := builtin.min(num_l, num_r)
    if num > 0 {
        block_swap(data, width,offset_l,offset_r,num_l,num_r,num)
    }
    num_l -= num
    num_r -= num

    if num_l > 0 {
        for num_l > 0 {
            num_l -= 1
            left = left[-width:]
            swap_small(left, offset_l[num_l], width)
        }
        return uint(uintptr(left) - uintptr(data)) / width
    }

    if num_r > 0 {
        for num_r > 0 {
            num_r -= 1
            right = right[width:]
            swap_small(right, offset_r[num_r], width)
        }
        return uint(uintptr(right) - uintptr(data)) / width + 1
    }

    return uint(uintptr(left) - uintptr(data)) / width
}

partition_generic_small :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr, pivot: []byte) -> (uint, uint) {
    left := data
    right := data[(length-1)*width:]
    k := data
    pivot := raw_data(pivot)

    for ; uintptr(k) < uintptr(right) + uintptr(width); k = k[width:] {
        if cmp(k, pivot, arg) == .Less {
            swap_small(left, k, width)
            left = left[width:]
            continue
        }
        if cmp(k, pivot, arg) == .Greater {
            for cmp(right, pivot, arg) == .Greater {
                right = right[- width:]
            }
            if uintptr(k) > uintptr(right) {break}
            swap_small(k, right, width)
            right = right[- width:]
            k = k[- width:]
        }
    }

    left_len := uintptr(left) - uintptr(data)
    right_len := uintptr(right) - uintptr(data)
    return uint(left_len) / width, length - uint(right_len) / width - 1
}

block_swap :: proc(data: [^]byte, width: uint,left,right: [64][^]byte,num_l,num_r,num: uint){
    t1 : [16]byte = ---
    copy(t1[:], left[num_l-1][:width])
    t2 : [16]byte = ---
    copy(t2[:], right[num_r-1][:width])

    for i in 1..<num {
        copy(left[num_l - i][:width],right[num_r - i-1][:width])
        copy(right[num_r - i][:width],left[num_l - i-1][:width])
    }
    copy(left[num_l - num][:width],t2[:width])
    copy(right[num_r - num][:width],t1[:width])
    
}

quicksort_big :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg: rawptr){
    length := length
    data := data

    for {
        if length <= 64 {
            piposort_big(data, length, width, cmp, arg)
            return
        }

        generic : bool = false
        pivot : [^]byte = ---
        if length <= 2048  {
            median_9_big(data, length, width, cmp, arg, &generic, &pivot)
        } else {
            median_cbrt_big(data, length, width, cmp, arg, &generic, &pivot)
        }

        data_offset, new_length : uint

        if generic {
            left_len, right_len := partition_generic_big(data, length, width, cmp, arg, pivot)

            data_offset = width * (length - right_len)
            new_length = right_len

            length = left_len
        } else {
            left_len := partition_big(data, length, width, cmp, arg, pivot)

            data_offset = width * left_len
            new_length = length - left_len

            length = left_len
        }

        if new_length < length {
            quicksort_big(data[data_offset:], new_length, width, cmp, arg)
        } else {
            quicksort_big(data, length, width, cmp, arg)
            data = data[data_offset:]
            length = new_length
        }
    }
}


// put pivot at 0 so it doesnt fly around
// TODO: test this ...
partition_generic_big :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr, pivot: [^]byte) -> (uint, uint) {
    left := data[width:]
    right := data[(length-1)*width:]
    k := data[width:]
    swap_big(data,pivot,width)
    pivot := data

    for ; uintptr(k) < uintptr(right) + uintptr(width); k = k[width:] {

        if cmp(k, pivot, arg) == .Less {
            swap_big(left, k, width)
            left = left[width:]
            continue
        }
        if cmp(k, pivot, arg) == .Greater {
            for cmp(right, pivot, arg) == .Greater {
                right = right[- width:]
            }
            if uintptr(k) > uintptr(right) {break}
            swap_big(k, right, width)
            right = right[- width:]
            k = k[- width:]
        }
    }

    // swap pivot back 
    left = left[-width:]
    swap_big(left, pivot,width)

    left_len := uintptr(left) - uintptr(data)
    right_len := uintptr(right) - uintptr(data)
    return uint(left_len) / width, length - uint(right_len) / width - 1
}

partition_big :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr, pivot: [^]byte) -> uint {
    left := data
    right := data[(length-1)*width:]
    BLOCK_SIZE :: 64
    offset_l, offset_r : [BLOCK_SIZE][^]byte
    num_l, num_r : uint = 0, 0

    for int(uintptr(right)) - int(uintptr(left)) >= int(BLOCK_SIZE * width - width) {
        if num_l == 0 {
            for i in 0..<BLOCK_SIZE {
                offset_l[num_l] = left
                num_l += cast(uint)(cmp(left,pivot,arg) == .Greater)
                left = left[width:]
            }
        } else {
            for i in 0..<BLOCK_SIZE {
                offset_r[num_r] = right
                num_r += cast(uint)(cmp(right,pivot,arg) == .Less)
                right = right[-width:]
            }
        }
        num := builtin.min(num_l, num_r)
    
        if num > 0 {
            block_swap_big(data, width,offset_l,offset_r,num_l,num_r,num)
        }
        num_l -= num
        num_r -= num

    }

    unknown := (int(uintptr(right)) - int(uintptr(left))) / int(width) + 1

    if num_l == 0 {
        for i in 0..<unknown {
            offset_l[num_l] = left
            num_l += cast(uint)(cmp(left,pivot,arg) == .Greater)
            left = left[width:]
        }
    } else {
        for i in 0..<unknown {
            offset_r[num_r] = right
            num_r += cast(uint)(cmp(right,pivot,arg) == .Less)
            right = right[-width:]
        }
    }

    num := builtin.min(num_l, num_r)
    if num > 0 {
        block_swap_big(data, width,offset_l,offset_r,num_l,num_r,num)
    }
    num_l -= num
    num_r -= num

    if num_l > 0 {
        for num_l > 0 {
            num_l -= 1
            left = left[-width:]
            swap_big(left, offset_l[num_l], width)
        }
        return uint(uintptr(left) - uintptr(data)) / width
    }

    if num_r > 0 {
        for num_r > 0 {
            num_r -= 1
            right = right[width:]
            swap_big(right, offset_r[num_r], width)
        }
        return uint(uintptr(right) - uintptr(data)) / width + 1
    }

    return uint(uintptr(left) - uintptr(data)) / width
}


median_cbrt_big  :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr, generic: ^bool, pivot: ^[^]byte) {
    cbrt : uint
    switch {
        case length < 32 * 32 * 32: cbrt = 32 / 4
        case length < 64 * 64 * 64: cbrt = 64 / 4
        case length < 128 * 128 * 128: cbrt = 128 / 4
        case: cbrt = 256 / 4
    }
    div := length / (cbrt * 4)
    ptr := data

    swap : [64][^]byte = ---
    swap_t : [8][^]byte = ---

    for i in uint(0)..<cbrt/2 {
        for j in uint(0)..<8 {
            swap_t[j] = data[(i*8+j) * width:]
        }
        trim_four_big(swap_t[:],cmp,arg)
        trim_four_big(swap_t[4:],cmp,arg)
        swap_t[3] = swap_t[5]
        swap_t[4] = swap_t[6]
        trim_four_big(swap_t[1:],cmp,arg)

        swap[i*2] = swap_t[2]
        swap[i*2+1] = swap_t[3]
    }

    pipo_rec_indecies(swap[:],cbrt,cmp,arg)
    cbrt = cbrt / 2

    if cmp(swap[0], swap[cbrt], arg) == .Equal { 
        generic^ = true
    }
    pivot^ = swap[cbrt]
}

trim_four_big  :: proc(data: [][^]byte, cmp: Generic_Cmp, arg:rawptr){
    branchless_swap_indecies(data,cmp,arg)
    branchless_swap_indecies(data[2:],cmp,arg)

    x := 2 * cast(uint)(cmp(data[0], data[2],arg) != .Greater)
    data[2] = data[x]

    data := data[1:]
    y := 2 * cast(uint)(cmp(data[0], data[2],arg) == .Greater)
    data[1] = data[y]
}


median_9_big  :: proc(data: [^]byte, length, width: uint, cmp: Generic_Cmp, arg:rawptr, generic: ^bool, pivot: ^[^]byte) {
    div := length / 9
    swap : [9][^]byte = ---

    for i in uint(0)..<9 {
        swap[i] = data[div * width*i:]
    }

    odd_even_sort_indecies(swap[:],9,cmp,arg)

    if cmp(swap[0], swap[4], arg) == .Equal { // this might need a lot of tuning -_-
        generic^ = true
    }
    pivot^ = swap[4]
}


block_swap_big :: proc(data: [^]byte, width: uint,left,right: [64][^]byte,num_l,num_r,num: uint){
    circle : [128][^]byte

    for i in 0..<num {
        circle[i*2] = left[num_l - i-1]
        circle[i*2+1] = right[num_r - i-1]
    }
    cycle(width, circle[:],int(num*2))
}
