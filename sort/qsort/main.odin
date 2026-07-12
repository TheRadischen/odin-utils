package ref

import "core:time"
import "core:slice"
import "core:math/rand"
import "base:intrinsics"
import "core:fmt"


COMMON_SIZE :: 100_000

main :: proc(){
   
    // test_multi_instance()

    // for size := 10; size <= 10_000_000; size *= 10 {
    //     test_difference_rand(size)
    // }

    for size := 10; size <= 10_000_000; size *= 10 {
        test_difference_asc(size)
    }

}

test_multi_instance :: proc(){
    
    min_t1 := time.MAX_DURATION
    min_t2 := time.MAX_DURATION
    min_t3 := time.MAX_DURATION

    for i in 0..<1_00 {
        arr := make([]int,COMMON_SIZE)
        for i in 0..<len(arr) {
            arr[i] = rand.int_max(COMMON_SIZE)
        }
        arr3:= make([]f32,COMMON_SIZE)
        for i in 0..<len(arr) {
            arr3[i] = rand.float32()
        }

        arr2 := slice.clone(arr)

        defer delete(arr)
        defer delete(arr2)
        defer delete(arr3)


        start := time.tick_now()
        slice.sort(arr)
        min_t1 = min(time.tick_since(start), min_t1)

        start = time.tick_now()
        slice.sort(arr3)
        min_t2 = min(time.tick_since(start), min_t2)

        start = time.tick_now()
        // sort(arr2)
        min_t3 = min(time.tick_since(start), min_t3)




        // if !slice.is_sorted(arr2) {
        //     // fmt.println("not sorted2")
        //     // fmt.println(arr2)
        //     return
        // } 

    }
    fmt.println("sorting with []int and []f32 array slows down runtime, since the comparison funtion is a function pointer")
    fmt.println("size: ",COMMON_SIZE,"slice.sort int: ",min_t1, "slice.sort f32: ",min_t2,"qsort int : ",min_t3, "diff: ", f64(min_t1) / f64(min_t3))

}

test_difference_rand :: proc(size: int){
    
    min_t1 := time.MAX_DURATION
    min_t2 := time.MAX_DURATION

    iter := clamp(size / 1_000_000,2,100_00)

    for i in 0..<iter {
        arr := make([]int,size)
        for i in 0..<len(arr) {
            arr[i] = rand.int_max(size)
        }

        arr2 := slice.clone(arr)

        defer delete(arr)
        defer delete(arr2)



        start := time.tick_now()
        slice.sort(arr)
        min_t1 = min(time.tick_since(start), min_t1)

        start = time.tick_now()
        sort(arr2)
        min_t2 = min(time.tick_since(start), min_t2)



        if !slice.is_sorted(arr2) {
            panic("not sorted")
        } 

    }

    fmt.println("size: ",size,"slice.sort int: ",min_t1, "qsort int: ",min_t2, "diff: ", f64(min_t1) / f64(min_t2))

}


test_difference_asc :: proc(size: int){
    
    min_t1 := time.MAX_DURATION
    min_t2 := time.MAX_DURATION

    iter := clamp(size / 1_000_000,2,100_00)

    for i in 0..<iter {
        arr := make([]int,size)
        for i in 0..<len(arr) {
            arr[i] = i
        }

        arr2 := slice.clone(arr)

        defer delete(arr)
        defer delete(arr2)



        start := time.tick_now()
        slice.sort(arr)
        min_t1 = min(time.tick_since(start), min_t1)

        start = time.tick_now()
        sort(arr2)
        min_t2 = min(time.tick_since(start), min_t2)



        if !slice.is_sorted(arr2) {
            panic("not sorted")
        } 

    }

    fmt.println("size: ",size,"slice.sort int: ",min_t1, "qsort int: ",min_t2, "diff: ", f64(min_t1) / f64(min_t2))

}

// test :: proc(size: int){

//     min_t1 := time.MAX_DURATION
//     min_t2 := time.MAX_DURATION
//     min_t3 := time.MAX_DURATION
//     min_t4 := time.MAX_DURATION
//     for i in 0..<1_00 {
//         arr := make([]f32,size)
//         for i in 0..<len(arr) {
//             // arr[i] = f64(i)
//             arr[i] = rand.float32()
//         }
//         arr3:= make([]f32,size)
//         for i in 0..<len(arr) {
//             arr3[i] = rand.float32()
//             // arr3[i] = f32(i)
//         }
        
//         arr2 := slice.clone(arr)
//         arr4 := slice.clone(arr3)
//         defer delete(arr)
//         defer delete(arr2)
//         defer delete(arr3)
//         defer delete(arr4)

//         c:= proc(l,r: [SIZE]f32) -> bool {return l[0] < r[0]}

//         start := time.tick_now()
//         ind := slice.sort_with_indices2(arr)
//         min_t1 = min(time.tick_since(start), min_t1)

//         start = time.tick_now()
//         ind2 := slice.sort_with_indices(arr2)
//         min_t2 = min(time.tick_since(start), min_t2)

//         fmt.println(ind[:10])
//         fmt.println(ind2[:10])

//         start = time.tick_now()
//         // slice.sort_by2(arr3, c)
//         min_t3 = min(time.tick_since(start), min_t3)

//         start = time.tick_now()
//         // slice.sort(arr4)
//         min_t4 = min(time.tick_since(start), min_t4)

//         // sum := slice.reduce(arr,0,proc(acc,erm: int)->int{return acc + erm})
//         // sum2 := slice.reduce(arr2,0,proc(acc,erm: int)->int{return acc + erm})
//         // if sum != sum2 do fmt.println("not same sum ,erm")
//         // if !slice.is_sorted(arr) do fmt.println("not sorted")
//         if !slice.is_sorted(arr2) {
//             fmt.println("not sorted2")
//             // fmt.println(arr2)
//             return
//         } 
//         // if !slice.is_sorted(arr3) do fmt.println("not sorted3")
//         // if !slice.is_sorted(arr4) do fmt.println("not sorted4")
//     }

//     fmt.println("size: ",size,"qsort: ",min_t1, "slice.sort: ",min_t2,"pipo f64 : ",min_t3,"slice.sort f64: ",min_t4, "diff: ", f64(min_t2) / f64(min_t1), f64(min_t4) / f64(min_t3))

// }


sort :: proc(data: $T/[]$E) where intrinsics.type_is_ordered(E) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			raw := ([^]byte)(raw_data(data))
			qsort(raw, uint(len(data)), size_of(E), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				x, y := (^E)(lhs)^, (^E)(rhs)^
				if x < y {
					return .Less
				} else if x > y {
					return .Greater
				}
				return .Equal
			}, nil)
		}
	}
}