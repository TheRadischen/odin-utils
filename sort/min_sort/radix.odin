package msort

import "base:intrinsics"

/*
radix sorter, can sort any numeric type exept i8

to sort a Struct provide a key proc like so:

Data :: struct {data: [4]int, key: f64}

radix(arr, proc(s: Data) -> f64{return s.key})
*/
radix :: proc{radix_simple, radix_unsigned, radix_integer, radix_float}

radix_group :: proc{radix_unsigned, radix_integer, radix_float}

radix_simple :: proc(data: []$T, allocator := context.allocator) 
    where   intrinsics.type_is_unsigned(T) ||
            intrinsics.type_is_integer(T) ||
            intrinsics.type_is_float(T), T != i8 {
    radix_group(data, proc(t: T) -> T {return t}, allocator)
}

radix_unsigned :: proc(data: []$T, $key: proc(T)->$K, allocator := context.allocator)
    where intrinsics.type_is_unsigned(K) #no_bounds_check { // dont bother with u128
    if len(data) <= 64 {
        for i in 1..<len(data) {
            current := data[i]
            j := i
            for ; j > 0 && key(data[j - 1]) > key(current); j -= 1 {
                data[j] = data[j - 1]
            }
            data[j] = current
        }
        return
    }
    BASE :: 256
    SIZE :: size_of(K)
    arr := data
    counts : [SIZE][BASE]i32
    swap := make([]T, len(arr), allocator)
    defer delete(swap, allocator)

    // count 
    for a in arr {
        #unroll for c in uint(0)..<SIZE {
            ind := 0xff & (key(a) >> (c * 8))
            counts[c][ind] += 1
        }
    }

    // calc offset
    for i in 1..<BASE {
        #unroll for c in 0..<SIZE {
            counts[c][i] += counts[c][i - 1]
        }
    }

    // swap
    for &count, i in counts {
        if count[0] == i32(len(arr)) {
            continue
        }

        #reverse for a in arr {
            ind := 0xff & (key(a) >> (uint(i) * 8))
            count[ind] -= 1
            swap[count[ind]] = a
        }
        swap, arr = arr, swap
    }

    // swap if we skipped odd amounts
    if raw_data(arr) != raw_data(data) {
        copy(swap, arr)
        swap, arr = arr, swap
    }
}

radix_integer :: proc(data: []$T, $key: proc(T)->$K, allocator := context.allocator)
    where intrinsics.type_is_integer(K), K != i8 #no_bounds_check { // dont bother with i128
    if len(data) <= 64 {
        for i in 1..<len(data) {
            current := data[i]
            j := i
            for ; j > 0 && key(data[j - 1]) > key(current); j -= 1 {
                data[j] = data[j - 1]
            }
            data[j] = current
        }
        return
    }
    BASE :: 256
    SIZE :: size_of(K) - 1
    arr := data
    counts : [SIZE + 1][BASE]i32
    swap := make([]T, len(arr), allocator)
    defer delete(swap, allocator)

    // count 
    for a in arr {
        #unroll for c in uint(0)..<SIZE {
            ind := 0xff & (key(a) >> (c * 8))
            counts[c][ind] += 1
        }
        ind := (0xff & (key(a) >> (SIZE * 8))) ~ 128
        counts[SIZE][ind] += 1
    }

    // calc offset
    for i in 1..<BASE {
        #unroll for c in 0..<SIZE + 1 {
            counts[c][i] += counts[c][i - 1]
        }
    }

    // swap
    for c in 0..<SIZE {
        count := counts[c]
        if count[0] == i32(len(arr)) || count[BASE - 2] == 0 {
            continue
        }

        #reverse for a in arr {
            ind := 0xff & (key(a) >> (uint(c) * 8))
            count[ind] -= 1
            swap[count[ind]] = a
        }
        swap, arr = arr, swap
    }
    // rest
    if counts[SIZE][0] != i32(len(arr)) && counts[SIZE][BASE - 2] != 0 {
        #reverse for a in arr {
            ind := (0xff & (key(a) >> (SIZE * 8))) ~ 128
            counts[SIZE][ind] -= 1
            swap[counts[SIZE][ind]] = a
        }
        swap, arr = arr, swap
    }

    // swap if we skipped odd amounts
    if raw_data(arr) != raw_data(data) {
        copy(swap, arr)
        swap, arr = arr, swap
    }
}

radix_float :: proc(data: []$T, $key: proc(T)->$K, allocator := context.allocator)
    where intrinsics.type_is_float(K) #no_bounds_check {
    if len(data) <= 64 {
        for i in 1..<len(data) {
            current := data[i]
            j := i
            for ; j > 0 && key(data[j - 1]) > key(current); j -= 1 {
                data[j] = data[j - 1]
            }
            data[j] = current
        }
        return
    }
    BASE :: 256
    SIZE :: size_of(K)
    SIZE_LAST :: size_of(K) - 1
    when K == f16 {
        TYPE :: u16
    } else when K == f32 {
        TYPE :: u32
    } else {
        TYPE :: u64
    }
    arr := data
    ke :: proc(k: T) -> TYPE {return transmute(TYPE)key(k)}
    
    counts : [SIZE][BASE]i32
    last : [BASE]i32
    swap := make([]T, len(arr), allocator)
    defer delete(swap, allocator)

    // count 
    for a in arr {
        #unroll for c in uint(0)..<SIZE {
            ind := 0xff & (ke(a) >> (c * 8))
            counts[c][ind] += 1
        }
    }

    negativ_nums :i32= 0
    for i in BASE / 2..<BASE {
        negativ_nums += counts[SIZE_LAST][i]
    }

    // calc offset
    last[BASE - 1] = 0
    last[0] = negativ_nums + counts[SIZE_LAST][0] - 1
    for i in 1..<BASE / 2 {
        #unroll for c in 0..<SIZE_LAST {
            counts[c][i] += counts[c][i - 1]
        }

        last[i] = counts[SIZE_LAST][i] + last[i - 1]
        last[BASE - 1 - i] = counts[SIZE_LAST][BASE - i] + last[BASE - i]
    }
    for i in BASE / 2..<BASE {
        #unroll for c in 0..<SIZE_LAST {
            counts[c][i] += counts[c][i - 1]
        }
    }

    // swap
    for c in 0..<SIZE_LAST {
        count := counts[c]
        if count[0] == i32(len(arr)) || count[BASE - 2] == 0 {
            continue
        }

        #reverse for a in arr {
            ind := 0xff & (ke(a) >> (uint(c) * 8))
            count[ind] -= 1
            swap[count[ind]] = a
        }
        swap, arr = arr, swap
    }

    // rest
    #reverse for a in arr {
        ind := (0xff & (ke(a) >> (SIZE_LAST * 8)))
        swap[last[ind]] = a
        last[ind] += 1 if ind >= 128 else -1
    }
    swap, arr = arr, swap

    // swap if we skipped odd amounts
    if raw_data(arr) != raw_data(data) {
        copy(swap, arr)
        swap, arr = arr, swap
    }
}
