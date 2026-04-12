package merge_inplace

// https://arxiv.org/pdf/2509.24540
// by Christian Siebert

sort :: proc(arr: $A/[]$T, less: proc(T, T) -> bool){
    if len(arr) < 32 {
        insertion_sort_cmp(arr, less)
        return
    }
    mid := len(arr) >> 1

    sort(arr[:mid], less)
    sort(arr[mid:], less)
    
    merge_inplace(arr,len(arr)>>1,len(arr)-len(arr)>>1, less)


}

insertion_sort_cmp :: proc(arr: $A/[]$T, less: proc(T, T) -> bool) {
    for i in 1..<len(arr) {
        x := arr[i]
        j := i
        for ; j > 0 && less(x, arr[j - 1]); j -= 1 {
            arr[j] = arr[j - 1]
        }
        arr[j] = x
    }
}

merge_inplace :: proc(arr: $A/[]$T, n1, n2: int, less: proc(T, T) -> bool) {
    if n1 < 1 || n2 < 1 do return
    a := arr[:n1]
    b := arr[n1:]
    
    j, k := co_rank(n1, a, b, less)
    m := arr[j:][:(n1-j)+k]
    optimal_rotate(m, k)

    merge_inplace(a, j, n1 - j, less)
    merge_inplace(b, k, n2 - k, less)

}

optimal_rotate :: proc(a: $A/[]$T, r: int) {
    n := len(a)
    if !(n > 0 && r > 0) do return
    work := n
    for s := 0; work > 0; s += 1 {
        i := s
        first := a[s]
        for {
            next := i + r
            if next >= n {
                next -= n
            } 

            if next == s {
                a[i] = first
            } else {
                a[i] = a[next]
            }
            i = next
            work -= 1
            if i == s do break
        }
    }
}

co_rank :: proc(i: int, a,b: $A/[]$T, less: proc(T, T) -> bool) -> (int, int) {
    na := len(a)
    nb := len(b)
    j := min(i, na)
    k := i - j
    j_low := max(0, i - nb)
    k_low : int

    for { 
        if (j > 0 && k < nb) && less(b[k],a[j - 1]) {
            g := (j - j_low + 1) >> 1
            k_low = k
            j -= g
            k += g
        } else if (k > 0 && j < na) && !less(b[k - 1], a[j]) {
            g := (k - k_low + 1) >> 1
            j_low = j
            j += g
            k -= g
        } else {
            return j, k
        }
    }
    return j, k // should never reach here
}