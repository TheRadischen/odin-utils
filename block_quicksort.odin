package prod

import "core:slice"
import "core:fmt"



blocksize :: 128
insertion_tresh :: 32


blockqsort :: proc(arr: $A/[]$T, cmp: proc(T,T)->bool) {
    // println(arr)
    if len(arr) < insertion_tresh {
        insertion_sort_cmp(arr,cmp)
        return
    }
    median3(arr,cmp)
    // println(arr)
    // cut := partition(arr,pivot,cmp)
    // println(arr[0])
        // println(arr[pp-1:][:3])
        // piv := arr[1]
    cut := partition_right(arr,cmp)

    // assert(arr[cut] == piv)

    // check_part(arr, cut, cmp)
    // if true do return
    blockqsort(arr[:cut], cmp)
    blockqsort(arr[cut+1:], cmp)
}

check_part :: proc(arr: $A/[]$T, pp: int,cmp: proc(T,T)->bool) -> bool{
    piv := arr[pp]
    correct := true
    for i in 0..<pp {
        if piv < arr[i] {
            correct = false
            fmt.println(i, arr[i])
        }
    }
    for i in pp + 1..<len(arr) {
        if piv > arr[i] {
            correct = false
            fmt.println(i, arr[i])
        }
    }
    if !correct {
        fmt.println("wrong: piv: pp: ",len(arr), piv, pp)
        fmt.println(arr)
    } 
    return correct
}

// puts the pivot at i 0
median3 :: proc(arr: $A/[]$T,cmp: proc(T,T)->bool) {
    r := len(arr) - 1
    m := r >> 1
    if cmp(arr[m], arr[0]) do arr[0], arr[m] = arr[m], arr[0]
    if cmp(arr[r], arr[m]) do arr[m], arr[r] = arr[r], arr[m]
    if cmp(arr[m], arr[0]) do arr[0], arr[m] = arr[m], arr[0] // reverse sort to get the piv to [0]
    arr[1],arr[m] = arr[m], arr[1]
}

partition2 :: proc(arr: $A/[]$T, cmp: proc(T,T)->bool) -> int {
    offset_l : [blocksize]int
    offset_r : [blocksize]int
    pivot := arr[1]
    right := len(arr) - 2
    left := 2
    num_l, num_r : int
    start_l, start_r : int
    
    for r - l > 2 * blocksize {
        if num_l == 0 {
            start_l := 0
            for i in 0..<blocksize {
                offset_l[num_l] = i
                // num_l += cast(int)cmp(arr[l+i], p)
                num_l += cast(int)cmp(p, arr[l+i])
            }
        }
        if num_r == 0 {
            start_r := 0
            for i in 0..<blocksize {
                offset_r[num_r] = i
                // num_r += cast(int)cmp(p, arr[r - i])
                num_r += cast(int)cmp(arr[r - i], p )

            }
        }
        num := min(num_l,num_r)
        for j in 0..<num {
            swap(arr, l+ offset_l[j], r - offset_r[j])
        }
        num_l -= num
        num_r -= num
        start_l += num
        start_r += num
        if num_l == 0 do l += blocksize
        if num_r == 0 do r -= blocksize
    }
    println(offset_l[:num_l],offset_r[:num_r], l, r)
    println(arr)
    return 0
}


partition_right :: proc(arr: $A/[]$T, cmp: proc(T,T)->bool) -> int {
    offset_l : [blocksize]int
    offset_r : [blocksize]int
    // defer delete(offset_l)
    // defer delete(offset_r)
    pivot := arr[1]
    right := len(arr) - 1
    left := 1
    num_l, num_r : int
    // start_l, start_r : int
    // println(pivot)
    
    for right - left - 1 >  blocksize {
        if num_l == 0 {
            // start_l := 0
            for i := 0; i < blocksize; i+=8 {
                left += 1; offset_l[num_l] = left; num_l += cast(int) !cmp(arr[left], pivot)
                left += 1; offset_l[num_l] = left; num_l += cast(int) !cmp(arr[left], pivot)
                left += 1; offset_l[num_l] = left; num_l += cast(int) !cmp(arr[left], pivot)
                left += 1; offset_l[num_l] = left; num_l += cast(int) !cmp(arr[left], pivot)
                left += 1; offset_l[num_l] = left; num_l += cast(int) !cmp(arr[left], pivot)
                left += 1; offset_l[num_l] = left; num_l += cast(int) !cmp(arr[left], pivot)
                left += 1; offset_l[num_l] = left; num_l += cast(int) !cmp(arr[left], pivot)
                left += 1; offset_l[num_l] = left; num_l += cast(int) !cmp(arr[left], pivot)
            }
            // for i in 0..<blocksize {
            //     left += 1
            //     offset_l[num_l] = left
            //     num_l += cast(int)cmp(pivot, arr[left])
            // }
        } else {
        // if num_r == 0 {
            // start_r := 0
            for i := 0; i < blocksize; i+=8 {
                right -= 1; offset_r[num_r] = right; num_r += cast(int)cmp(arr[right], pivot)
                right -= 1; offset_r[num_r] = right; num_r += cast(int)cmp(arr[right], pivot)
                right -= 1; offset_r[num_r] = right; num_r += cast(int)cmp(arr[right], pivot)
                right -= 1; offset_r[num_r] = right; num_r += cast(int)cmp(arr[right], pivot)
                right -= 1; offset_r[num_r] = right; num_r += cast(int)cmp(arr[right], pivot)
                right -= 1; offset_r[num_r] = right; num_r += cast(int)cmp(arr[right], pivot)
                right -= 1; offset_r[num_r] = right; num_r += cast(int)cmp(arr[right], pivot)
                right -= 1; offset_r[num_r] = right; num_r += cast(int)cmp(arr[right], pivot)
            }
            // for i in 0..<blocksize {
            //     right -= 1
            //     offset_r[num_r] = right
            //     num_r += cast(int)cmp(arr[right], pivot)
            // }
        }
        num := min(num_l,num_r)
        // for j in 1..=num {
        //     swap(arr, offset_l[num_l - j], offset_r[num_r - j])
        // }
        if num > 0 do swap_block(arr, offset_l, offset_r, num_l, num_r)

        num_l -= num
        num_r -= num
        // start_l += num
        // start_r += num
        // if num_l == 0 do l += blocksize
        // if num_r == 0 do r -= blocksize
    }
    unknown := right - left - 1
    if num_l == 0 {
        for i in 0..<unknown {
            left += 1
            offset_l[num_l] = left
            num_l += cast(int)cmp(pivot, arr[left])
        }
    } else {
        for i in 0..<unknown {
            right -= 1
            offset_r[num_r] = right
            num_r += cast(int)cmp(arr[right], pivot)
        }
    }
    // println(offset_l[:num_l],offset_r[:num_r], left, right)
    // println(arr)
    // if true do return 1
    num := min(num_l,num_r)
    // println(offset_l[:num_l],offset_r[:num_r], left, right)
    // println(arr)
    // for j in 1..=num {
    //     swap(arr, offset_l[num_l - j], offset_r[num_r - j])
    // }
    if num > 0 do swap_block(arr,offset_l,offset_r,num_l,num_r)
    num_l -= num
    num_r -= num


    if num_l > 0 {
        for num_l > 0 {
            num_l -= 1
            swap(arr, left, offset_l[num_l])
            left -= 1
        }
        swap(arr, 1, left + 0)
        return left - 0
    }
    if num_r > 0 {
        for num_r > 0 {
            num_r -= 1
            swap(arr, right, offset_r[num_r])
            right += 1
        }

        swap(arr, 1, right - 1)

        return right - 1
    }
    swap(arr, 1, left + 0)
    return left + 0
}

// println :: proc(args: ..any) {
//     if true do return
//     fmt.println(args)
// }

swap_block :: proc(arr: $A/[]$T,left,right:[blocksize]int,num_l,num_r:int){
    num := min(num_l,num_r)
    // fmt.println(num)
    temp :=arr[left[num_l - 1]]

    for j in 1..<num {
        arr[left[num_l - j]] = arr[right[num_r - j]]
        arr[right[num_r - j]] = arr[left[num_l - (j + 1)]] 
    }
    arr[left[num_l - num]] = arr[right[num_r - num]]
    arr[right[num_r - num]] = temp
}