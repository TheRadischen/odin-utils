package power_sort

import "core:fmt"
import "core:math"
import "core:slice"
import "base:intrinsics"

T :: int
minRunLen := 2
powersort :: proc(arr: ^[]T, left, right:int){
    fmt.println(arr)
    n:= right - left + 1
    lg_plus2 := int(math.log10_f32(f32(n)) + 2)
    left_run_start :[]int= make([]int,lg_plus2)
    left_run_end :[]int= make([]int,lg_plus2)
    slice.fill(left_run_end, -1)
    top := 0
    buffer :[]T = make_slice([]T,n >> 1)

    startA := left
    endA := extendRunRight(arr^, startA, right)
    lenA := endA - startA + 1
    if lenA < minRunLen {
        endA = min(right, startA + minRunLen - 1)
        insertion_sort(arr[startA:endA])
    }
    fallback := 0
    for endA < right && fallback < 10 {
        fallback += 1
        fmt.println(arr, left_run_start, left_run_end)
        startB := endA + 1
        endB := extendRunRight(arr^, startB, right)
        lenB := endB - startB + 1
        if lenB < minRunLen {
            endB = min(right, startB + minRunLen - 1)
            insertion_sort(arr[startB:endB])  
        }
        k := cast(int)nodePower(left, right, startA, startB, endB)
        assert(k != top)
        for l := top; l > k; l -= 1 {
            if left_run_start[l] == - 1 do continue
            mergeRuns(arr, left_run_start[l],left_run_end[l] + 1, endA, &buffer)
            startA = left_run_start[l]
            left_run_start[l] = -1
        }
        left_run_start[k] = startA
        left_run_end[k] = endA
        top = k
        startA = startB
        endA = endB
    }
    assert(endA == right)
    for l := top; l > 0; l -= 1 {
        if left_run_start[l] == -1 do continue
        mergeRuns(arr, left_run_start[l], left_run_end[l] + 1, right, &buffer)
    }

}

extendRunRight :: proc(arr: []T,left,right: int) -> int{
    left := left
    for arr[left] < arr[right] {
        left += 1
    }
    return left
}

nodePower :: proc(left, right, startA, startB, endB: int) -> i32 {
    twoN :int= (right - left + 1) << 1; // 2*n
    l :int= startA + startB - (left << 1)
    r :int= startB + endB + 1 - (left << 1)
    a :i32= cast(i32) ((l << 31) / twoN)
    b :i32= cast(i32) ((r << 31) / twoN)
    res := intrinsics.count_leading_zeros(a ~ b)
    fmt.println(res)
    return res
}

mergeRuns :: proc(arr: ^[]int, l, m, r: int, aux: ^[]int) {
    m := m - 1
    i, j: int
    for i = m+1; i > l; i -= 1 {
        aux[i-1] = arr[i-1]
    }
    for j = m; j < r; j += 1 {
        aux[r+m-j] = arr[j+1]
    }
    for k := l; k <= r; k += 1 {
        if aux[j] < aux[i] {
            arr[k] = aux[j]
            j -= 1
        } else {
            arr[k] = aux[i]
            i += 1
        }
    }
}


gallop_right :: proc(){}
gallop_left :: proc(){}
merge_high :: proc(){}
merge_low :: proc(){}

insertion_sort :: proc(arr: $A/[]$T) {
    for i in 1..<len(arr) {
        x := arr[i]
        j := i
        for ; j > 0 && arr[j - 1] > x; j -= 1 {
            arr[j] = arr[j - 1]
        }
        arr[j] = x
    }
}