package min

radix_i32 :: proc(arr: []i32)  {
    arr := arr
    swap := make([]i32,len(arr))
    count0 : [256]i32
    count1 : [256]i32
    count2 : [256]i32
    count3 : [256]i32

    for i in 0..<len(arr) {
        ind0 := 0xff & arr[i]
        ind1 := 0xff & (arr[i] >> 8)
        ind2 := 0xff & (arr[i] >> 16)
        ind3 := 0xff & (arr[i] >> 24)
        count0[ind0] += 1
        count1[ind1] += 1
        count2[ind2] += 1
        count3[ind3] += 1
    }

    for i in 1..<256 {
        count0[i] += count0[i-1]
        count1[i] += count1[i-1]
        count2[i] += count2[i-1]
        count3[i] += count3[i-1]
    }
    skips := 0
    if count0[0] == i32(len(arr)) {
        swap,arr = arr, swap
        skips+=1
    } else {
    for i := len(arr) - 1; i >= 0; i -= 1 {
        key := 0xff & arr[i]
        count0[key] -= 1
        swap[count0[key]] = arr[i]
    }}

    if count1[0] == i32(len(arr)) {
        swap,arr = arr, swap
        skips+=1
    } else {
    for i := len(arr) - 1; i >= 0; i -= 1 {
        key := 0xff & (swap[i] >> 8)
        count1[key] -= 1
        arr[count1[key]] = swap[i]
    }}

    if count2[0] == i32(len(arr)) {
        swap,arr = arr, swap
        skips+=1
    } else {
    for i := len(arr) - 1; i >= 0; i -= 1 {
        key := 0xff & (arr[i] >> 16)
        count2[key] -= 1
        swap[count2[key]] = arr[i]
    }}

    if count3[0] == i32(len(arr)) {
        swap,arr = arr, swap
        skips+=1
    } else {
    for i := len(arr) - 1; i >= 0; i -= 1 {
        key := 0xff & (swap[i] >> 24)
        count3[key] -= 1
        arr[count3[key]] = swap[i]
    }}

    if skips % 2 == 1 {
        swap,arr = arr, swap
        copy(arr,swap)
    }

    delete(swap)
}