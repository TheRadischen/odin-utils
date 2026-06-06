package test

import "core:fmt"
import "core:math/rand"
import "core:math"
import "core:time"

import "core:slice"
// to test stability
Data :: struct {
    rand: int,
    index: int,
}

main :: proc(){
    // test_stability()
    test_speed()
}
Sort_Kind :: enum {
	Ordered,
	Less,
	Cmp,
}
test_speed :: proc(){
    size :: 1_000_0
    shuffeled :f32= 2
    loops := 10
    arr := ascending_int(size)
for {
        min_insert := time.MAX_DURATION
        min_merge := time.MAX_DURATION
        min_quick := time.MAX_DURATION
        min_blockq := time.MAX_DURATION
        min_sort := time.MAX_DURATION
        sum_insert : time.Duration
        sum_merge : time.Duration
        sum_quick : time.Duration
        sum_blockq : time.Duration
        sum_sort : time.Duration
        for i in 0..<loops {

            start : time.Tick
            dur : time.Duration

            shuffle_percent(arr,shuffeled)
            start = time.tick_now()
            stable_sort_old(arr,struct{}{},.Ordered)
            dur = time.tick_since(start)
            if dur < min_insert do min_insert = dur
            sum_insert += dur
            if !is_sorted(arr) {
                fmt.println("not sorted",shuffeled)
                break
            }

            shuffle_percent(arr,shuffeled)
            start = time.tick_now()
            slice.stable_sort(arr)
            dur = time.tick_since(start)
            if dur < min_merge do min_merge = dur
            sum_merge += dur
            if !is_sorted(arr) {
                fmt.println("not sorted",shuffeled)
                break
            } 

            // shuffle_percent(arr,shuffeled)
            // start = time.tick_now()
            // prod.pipo_sort(arr,c2)
            // // prod.pipo_sort2(arr,buf,c2)
            // dur = time.tick_since(start)
            // if dur < min_quick do min_quick = dur
            // sum_quick += dur
            // if !is_sorted(arr) {
            //     fmt.println("not sorted",shuffeled)
            //     break
            // } 

            // shuffle_percent(arr,shuffeled)
            // start = time.tick_now()
            // prod.blockqsort(arr,c2)
            // dur = time.tick_since(start)
            // sum_blockq += dur
            // if dur < min_blockq do min_blockq = dur
            // if !is_sorted(arr) {
            //     fmt.println("not sorted",shuffeled)
            //     break
            // } 

            shuffle_percent(arr,shuffeled)
            start = time.tick_now()
            slice.sort(arr)
            dur = time.tick_since(start)
            sum_sort += dur
            if dur < min_sort do min_sort = dur
            if !is_sorted(arr) {
                fmt.println("not sorted",shuffeled)
                break
            } 
        }
            // fmt.print("insert: ",avg(sum_insert,loops),min_insert, nlogn(min_insert,size))
            // fmt.print("stable: ",avg(sum_merge,loops),min_merge, nlogn(min_merge,size))
            // fmt.print(" pipo: ",avg(sum_quick,loops),min_quick, nlogn(min_quick,size))
            // fmt.print(" quick: ",avg(sum_blockq,loops),min_blockq, nlogn(min_blockq,size))
            // fmt.println(" std sort: ",avg(sum_sort,loops),min_sort, nlogn(min_sort,size))

            fmt.print(" insert: ",avg(sum_insert,loops))
            fmt.print(" stable: ",avg(sum_merge,loops))
            // fmt.print(" pipo: ",avg(sum_quick,loops))
            // fmt.print(" quick: ",avg(sum_blockq,loops))
            // fmt.print(" std sort: ",avg(sum_sort,loops))
            fmt.println()

    }


}
avg :: proc(tim: time.Duration, size: int) -> time.Duration {
    temp := cast(int)tim / size
    return cast(time.Duration)temp
}

nlogn :: proc(time: time.Duration, size: int) -> f64 {
    return cast(f64)time / (cast(f64)size*math.log10(f64(size)))
}

test_stability :: proc(){
    d := proc(l,r: Data)->bool{return l.rand < r.rand}
    arrd := rand_Data(100_000)
    arrd2 := slice.clone(arrd)

    slice.stable_sort_by(arrd,d)
    stable_sort_old(arrd2,d,.Less)

    is_sorted_data(arrd)
    is_sorted_data(arrd2)

    if !slice.equal(arrd,arrd2) do fmt.println("meh")
}


stable_sort_old :: proc(data: $T/[]$E, call: $P, $KIND: Sort_Kind) #no_bounds_check {
	less :: #force_inline proc(a, b: E, call: P) -> bool {
		when KIND == .Ordered {
			return a < b
		} else when KIND == .Less {
			return call(a, b)
		} else when KIND == .Cmp {
			return call(a, b) == .Less
		} else {
			#panic("unhandled Sort_Kind")
		}
	}
	
	// insertion sort
	// TODO(bill): use a different algorithm as insertion sort is O(n^2)
	n := len(data)
	for i in 1..<n {
		for j := i; j > 0 && less(data[j], data[j-1], call); j -= 1 {
			slice.swap(data, j, j-1)
		}
	}
}

rand_int :: proc(size: int) -> []int {
    arr := make([]int, size)
    for i in 0..<len(arr) do arr[i] = rand.int_max(size)
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
rand_int_many_similar :: proc(size: int) -> []int {
    similarity := log2(size)
    arr := make([]int, size)
    for i in 0..<len(arr) do arr[i] = rand.int_max(size / similarity)
    return arr
}
rand_Data :: proc(size: int) -> []Data {
    similarity := log2(size)
    arr := make([]Data, size)
    for i in 0..<len(arr) {
        arr[i].rand = rand.int_max(size / similarity)
        arr[i].index = i
    } 
    return arr
}

is_sorted :: proc{is_sorted_data, is_sorted_value}

is_sorted_data :: proc(arr: []Data) -> bool {
    sorted := true
    for i in 1..<len(arr) {
        if arr[i - 1].rand < arr[i].rand do continue
        if arr[i - 1].rand > arr[i].rand do return false
        if arr[i - 1].index > arr[i].index {
            fmt.println(arr[i-1],arr[i])
            sorted := false
        } 
    }
    if !sorted do fmt.println("not sorted, smh")
    return sorted
}
is_sorted_value :: proc(arr: []$T) -> bool {
    for i in 1..<len(arr) {
        if arr[i - 1] > arr[i] do return false
    }
    return true
}

rand_f32 :: proc(size: int) -> (arr: []f32) {
    arr = make([]f32, size)
    size := f32(size)
    for i in 0..<len(arr) do arr[i] = rand.float32() * size
    return
}


shuffle :: proc(arr: []$T) {
    for i in 0..<len(arr) {
        basic.swap(arr, i, rand.int_max(len(arr)))
    }
}

shuffle_percent :: proc(arr: []$T, percent: f32) {
    size := f32(len(arr))
    inverse := 2 / percent
    for i := inverse; int(i) < len(arr) ; i += inverse {
        slice.swap(arr, int(i), rand.int_max(len(arr)))
    }
}
log2 :: proc(n: int) -> int {
    log := 0
    n := n
    for ; n > 0 ;n >>= 1 {log += 1}
    return log
}
