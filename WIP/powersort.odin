package powersort

import "base:intrinsics"

// implementation of Nearly-Optimal Mergesorts
// by J. Ian Munro and Sebastian Wild
// https://arxiv.org/pdf/1805.04154
// possible optimizations in pythons implementation, mainly galloping
// https://github.com/python/cpython/blob/main/Objects/listobject.c#L2945


MIN_RUN_LEN :: 32

// stable sort, O(n/2) memory
powersort :: proc(arr: $A/[]$T) {
    n := len(arr)
    n2 := n << 1
    right := n - 1
    lgn_plus2 := size_of(int) * 8 - intrinsics.count_leading_zeros(n) - 1 + 2

    left_run_start := make([]int, lgn_plus2)
    left_run_end   := make([]int, lgn_plus2)
    defer delete(left_run_start)
    defer delete(left_run_end)

    for i in 0..<lgn_plus2 {
        left_run_start[i] = -1
    }

    top := 0
    buffer := make([]T, n >> 1)
    defer delete(buffer)

    start_a := 0
    end_a   := extend_run_right(arr, start_a, right)
    len_a   := end_a - start_a + 1
    if len_a < MIN_RUN_LEN {
        end_a = min(right, start_a + MIN_RUN_LEN - 1)
        insertion_sort(arr[start_a:end_a+1],len_a)
    }

    for end_a < right {
        start_b := end_a + 1
        end_b   := extend_run_right(arr, start_b, right)
        len_b   := end_b - start_b + 1
        if len_b < MIN_RUN_LEN {
            end_b = min(right, start_b + MIN_RUN_LEN - 1)
        insertion_sort(arr[start_b:end_b+1],len_b)
        }

        k := node_power(n2, start_a, start_b, end_b)

        for l := top; l > k; l -= 1 {
            if left_run_start[l] == -1 do continue
            merge_runs(arr, left_run_start[l], left_run_end[l], end_a, buffer)
            start_a = left_run_start[l]
            left_run_start[l] = -1
        }

        left_run_start[k] = start_a
        left_run_end[k]   = end_a
        top     = k
        start_a = start_b
        end_a   = end_b
    }

    for l := top; l > 0; l -= 1 {
        if left_run_start[l] == -1 do continue
        merge_runs(arr, left_run_start[l], left_run_end[l], right, buffer)
    }
}

extend_run_right :: proc(arr: $A/[]$T, left, right: int) -> int {
    if left == right do return left

    end := left + 1
    if arr[end] < arr[left] {
        for end < right && arr[end + 1] < arr[end] {
            end += 1
        }
        reverse(arr, left, end)
    } else {
        for end < right && arr[end + 1] >= arr[end] {
            end += 1
        }
    }
    return end
}

reverse :: proc(arr: $A/[]$T, left, right: int) {
    l, r := left, right
    for l < r {
        arr[l], arr[r] = arr[r], arr[l]
        l += 1
        r -= 1
    }
}

insertion_sort :: proc(arr: $A/[]$T, pre: int) {
    for i in pre..<len(arr) {
        x := arr[i]
        j := i
        for ; j > 0 && arr[j - 1] > x; j -= 1 {
            arr[j] = arr[j - 1]
        }
        arr[j] = x
    }
}

merge_runs :: proc(arr: $A/[]$T, l, m, r: int, aux: []T) {
    r := r
    l := l
    for arr[l] < arr[m+1] && l < m {l += 1}
    for arr[r] >= arr[m] && r > m {r -= 1}

    if m - l < r - m+1 {
        merge_low(arr,l,m,r,aux)
    } else {
        merge_high(arr,l,m,r,aux)
    }
}
merge_low :: proc(arr: $A/[]$T, l, m, r: int, aux: []T) {
    for i := 0; i <= m-l; i += 1 {
        aux[i] = arr[l+i]
    }

    s1 := 0
    s2 := m + 1
    s := l
    for s1 < m - l + 1 && s2 <= r {
        if aux[s1] < arr[s2] {
            arr[s] = aux[s1]
            s1 += 1
        } else {
            arr[s] = arr[s2]
            s2 += 1
        }
        s += 1
    }
    for s1 < m - l + 1 {
        arr[s] = aux[s1]
        s += 1
        s1 += 1
    }
}
merge_high :: proc(arr: $A/[]$T, l, m, r: int, aux: []T) {
    // slice.copy is exponentially slow on big inputs (10m+)
    for i := 0; i < r-m; i += 1 {
        aux[i] = arr[m+i+1]
    }

    s1 := m
    s2 := r-m-1
    s := r
    for s1 >= l && s2 >= 0 {
        if arr[s1] >= aux[s2] {
            arr[s] = arr[s1]
            s1 -= 1
        } else {
            arr[s] = aux[s2]
            s2 -= 1
        }
        s -= 1
    }
    for s2 >= 0 {
        arr[s] = aux[s2]
        s -= 1
        s2 -= 1
    }
}

node_power :: proc(n2, startA, startB, endB: int) -> int {
    l :int= startA + startB
    r :int= startB + endB + 1
    a :i32= cast(i32) ((l << 31) / n2)
    b :i32= cast(i32) ((r << 31) / n2)
    res := intrinsics.count_leading_zeros(a ~ b)
    return int(res)
}

