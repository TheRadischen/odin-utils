package prod

import "core:slice"
import "core:fmt"



blocksize :: 128
insertion_tresh :: 32


blockqsort :: proc(arr: $A/[]$T, cmp: proc(T,T)->bool) {

    if len(arr) < insertion_tresh {
        insertion_sort_cmp(arr,cmp)
        return
    }
    median3(arr,cmp)

    cut := partition_right(arr,cmp)

    blockqsort(arr[:cut], cmp)
    blockqsort(arr[cut+1:], cmp)
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

partition_right :: proc(arr: $A/[]$T, cmp: proc(T,T)->bool) -> int {
    offset_l : [blocksize]int
    offset_r : [blocksize]int

    pivot := arr[1]
    right := len(arr) - 1
    left := 1
    num_l, num_r : int

    
    for right - left - 1 >  blocksize {
        if num_l == 0 {

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

        } else {

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

        }
        num := min(num_l,num_r)

        if num > 0 do swap_block(arr, offset_l, offset_r, num_l, num_r)

        num_l -= num
        num_r -= num

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

    num := min(num_l,num_r)

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



swap_block :: proc(arr: $A/[]$T,left,right:[blocksize]int,num_l,num_r:int){
    num := min(num_l,num_r)

    temp :=arr[left[num_l - 1]]

    for j in 1..<num {
        arr[left[num_l - j]] = arr[right[num_r - j]]
        arr[right[num_r - j]] = arr[left[num_l - (j + 1)]] 
    }
    arr[left[num_l - num]] = arr[right[num_r - num]]
    arr[right[num_r - num]] = temp
}
