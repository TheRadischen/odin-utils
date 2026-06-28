package blit 

import "core:fmt"

import "core:math/rand"

// to test stability
Data :: struct {
    rand: int,
    index: int,
    big_data: [50]int,
}
asc_q1 :: proc(arr: []int){
    for i in 0..<len(arr)/4 {
        arr[i] = i
    }
}
asc_q2 :: proc(arr: []int){
    for i in len(arr)/4..<len(arr)/2 {
        arr[i] = i
    }
}
asc_q3 :: proc(arr: []int){
    for i in len(arr)/4*2..<len(arr)/4*3 {
        arr[i] = i
    }
}
asc_q4 :: proc(arr: []int){
    for i in len(arr)/4*3..<len(arr) {
        arr[i] = i
    }
}
// rand_ordered :: proc(arr: []Data) {
//     segments := len(arr) / 100
//     len_seg := 100

//     for i in 0..<segments {
//         start := rand.int_max(len(arr) - 100)
//         for i in start..<start+len_seg {
//             arr[i] = Data{len(arr)-i,i,{5,4,3,2,1},{5,4,3,8,1}}
//         }
//     }
    
// }
random_tail_25 :: proc(size:int)->[]Data{return random_tail(size,25)}
random_tail :: proc(size, tail: int) -> []Data{
    arr := make([]Data, size)
    p := f64(tail) / 100
    for i in 0..<len(arr) {
        arr[i].rand = i
        arr[i].index = i
    }
    n := f64(len(arr)) - 1
    for i := n; i > n * p; i -= 1 {
        arr[int(i)].rand = rand.int_max(size)
    }
    return arr
}
random_tail_int :: proc(size: int) -> []int{
    arr := make([]int, size)
    p :f64= 25 / 100
    for i in 0..<len(arr) {
        arr[i] = i
    }
    n := f64(len(arr)) - 1
    for i := n; i > n * p; i -= 1 {
        arr[int(i)] = rand.int_max(size)
    }
    return arr
}
random_head_int :: proc(size: int) -> []int{
    arr := make([]int, size)
    p := f64(25) / 100
    for i in 0..<len(arr) {
        arr[i]= i
    }
    n := f64(len(arr)) - 1
    for i :f64= 0; i < n * p; i += 1 {
        arr[int(i)] = rand.int_max(size)
    }
    return arr
}
random_head_25 :: proc(size:int)->[]Data{return random_head(size,25)}
random_head :: proc(size, head: int) -> []Data{
    arr := make([]Data, size)
    p := f64(head) / 100
    for i in 0..<len(arr) {
        arr[i].rand = i
        arr[i].index = i
    }
    n := f64(len(arr)) - 1
    for i :f64= 0; i < n * p; i += 1 {
        arr[int(i)].rand = rand.int_max(size)
    }
    return arr
}

rand_int :: proc(size: int) -> []int {
    arr := make([]int, size)
    for i in 0..<len(arr) do arr[i] = rand.int_max(size)
    return arr
}

ascending_saw :: proc(size: int) -> []Data {
    blades := 7 
    arr := make([]Data, size)
    for i in 0..<len(arr) {
        arr[i].rand = i % (size / blades+1)
        arr[i].index = i
    }
    return arr
}
ascending_saw_int :: proc(size: int) -> []int {
    blades := 7 
    arr := make([]int, size)
    for i in 0..<len(arr) {
        arr[i]= i % (size / blades+1)

    }
    return arr
}
desendin_saw_int :: proc(size: int) -> []int {
    blades := 7 
    arr := make([]int, size)
    for i in 0..<len(arr) {
        arr[i]= (size - i) % (size / blades+1)

    }
    return arr
}
desendin_saw :: proc(size: int) -> []Data {
    blades := 7 
    arr := make([]Data, size)
    for i in 0..<len(arr) {
        arr[i].rand = (size - i) % (size / blades+1)
        arr[i].index = i
    }
    return arr
}

rand_half :: proc(size: int) -> []Data {
    arr := make([]Data, size)
    for i in 0..<len(arr) {
        arr[i].rand = (i % 2) == 0 ? i : rand.int_max(size)
        arr[i].index = i
    }
    return arr
}


rand_half_int :: proc(size: int) -> []int {
    arr := make([]int, size)
    for i in 0..<len(arr) {
        arr[i] = (i % 2) == 0 ? i : rand.int_max(size)
    }
    return arr
}

ascending_int :: proc(size: int) -> []int {
    arr := make([]int,size)
    for i in 0..<len(arr) do arr[i] = i
    return arr
}

descending_int :: proc(size: int) -> []int {
    arr := make([]int,size)
    for i in 0..<len(arr) do arr[i] = size - i
    return arr
}
rand_int_mod10 :: proc(size: int) -> []int {
    arr := make([]int, size)
    for i in 0..<len(arr) do arr[i] = rand.int_max(10)
    return arr
}
rand_Data_10 :: proc(size: int) -> []Data {
    arr := make([]Data, size)
    for i in 0..<len(arr) {
        arr[i].rand = rand.int_max(10)
        arr[i].index = i
    } 
    return arr
}
rand_Data :: proc(size: int) -> []Data {
    arr := make([]Data, size)
    for i in 0..<len(arr) {
        arr[i].rand = rand.int_max(size)
        arr[i].index = i
    } 
    return arr
}
rand_Data_soa :: proc(size: int) -> #soa[]Data {
    arr := make(#soa[]Data, size)
    for i in 0..<len(arr) {
        arr[i].rand = rand.int_max(size)
        arr[i].index = i
    } 
    return arr
}

data_to_int :: proc(data: []Data) -> []int {
    arr := make([]int, len(data))
    for i in 0..<len(arr) {arr[i] = data[i].rand}
    return arr
}

sum_data :: proc(arr: []Data) -> (sum: int) {
    for i in 0..<len(arr) {
        sum += arr[i].rand
    }
    return
}
sum_int :: proc(arr: []int) -> (sum: int) {
    for i in 0..<len(arr) {
        sum += arr[i]
    }
    return
}

is_sorted_data :: proc(arr: []Data) -> bool {
    sorted := true
    for i in 1..<len(arr) {
        if arr[i - 1].rand < arr[i].rand do continue
        if arr[i - 1].rand > arr[i].rand do return false
        if arr[i - 1].index > arr[i].index {
            fmt.println(arr[i-1],arr[i])
            sorted = false
        } 
    }
    return sorted
}

is_sorted_value :: proc(arr: []$T) -> bool {
    for i in 1..<len(arr) {
        if arr[i - 1] > arr[i] {
            fmt.println(i,arr[i])
            return false
        } 
    }
    return true
}


rand_f32 :: proc(size: int) -> (arr: []f32) {
    arr = make([]f32, size)
    size := f32(size)
    for i in 0..<len(arr) do arr[i] = rand.float32() * size
    return
}

shell_last_gap :: proc(size: int) -> []int {
    arr := rand_int( size)

    shell_sort(arr)
    
    return arr
}
shell_sort :: proc(arr: $A/[]$T) {
    gaps := []int{9775485,  5934785,  1645254,  692843,  324011,  149728,  69487,  31970,  14842,  6847,  3227,  1408,  644,  301,  132,  57,  23,  10,  4}
    // gaps := []int{301, 132, 57, 23, 10, 4,1};

    k := 0
    for gaps[k] > len(arr) do k += 1
    for ; k < len(gaps); k += 1 {
        
        gap := gaps[k]
        for i := gap ; i < len(arr); i += 1 {
            cur := arr[i]
            j := i
            for j >= gap && arr[j - gap] >= cur {
                arr[j] = arr[j - gap]
                j -= gap
            }
            arr[j] = cur
        }
    }
}