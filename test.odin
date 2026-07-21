package basic

import "core:fmt"
import "core:slice"
import "core:time"


main :: proc(){
    fmt.println("average")
    for i :f64= 10; i < 10_000_000; i *= 10 {
        test_speed_average_int(int(i))
    }
    fmt.println("worse case")
    for i :f64= 10; i < 10_000_000; i *= 10 {
        test_speed_worse_case(int(i))
    }
    fmt.println("worste case")
    for i :f64= 10; i < 10_000_000; i *= 10 {
        test_speed_worste_case(int(i))
    }

    for i :f64= 0; i < 2000; i = i + 1 {
        test_correctness_2000(int(i))
    }
    fmt.println()
    fmt.println("LGTM")
}


test_correctness_2000 :: proc(size : int){
    min_slice_rotate := time.MAX_DURATION
    min_updated_rotate := time.MAX_DURATION

    iterations := max(5, 1_000 / max(1,size))
    iterations = 1

    for _ in 0..<iterations    {
        typ :: u8
        arr := make([]typ,size) 
        defer delete(arr)

        for j in 0..<len(arr) {
            arr[j] = cast(typ)j
        }

        arr2 := slice.clone(arr)
        defer delete(arr2)

        s : time.Tick
        r : int

        s = time.tick_now()
        for i in -len(arr)..<len(arr) {
            slice.rotate_left(arr2,i)
            slice.rotate_right(arr2,i+5)
        }
        d := time.tick_since(s)


        s = time.tick_now()
        for i in -len(arr)..<len(arr) {
            rotate_left(arr,i)
            rotate_right(arr,i+5)
        }
        d2 := time.tick_since(s)

        min_slice_rotate = min(min_slice_rotate, d)
        min_updated_rotate = min(min_updated_rotate, d2)    
        
        // check sameness
        for i in 0..<len(arr) {
            if arr[i] != arr2[i] {
                fmt.println("error: arr")
                fmt.println(arr)
                fmt.println("arr2")
                fmt.println(arr2)
                panic("not same rotation")
            }
        }
    }

    // fmt.println("size:",size,"iter:",iterations, "slice.rotate: ",min_slice_rotate, "small_rotate: ", min_updated_rotate, "diff: ", f64(min_slice_rotate) / f64(min_updated_rotate))
}

test_speed_average_int :: proc(size : int){
    min_slice_rotate := time.MAX_DURATION
    min_updated_rotate := time.MAX_DURATION

    iterations := max(5, 100_000 / max(1,size))
    // iterations = 1

    for _ in 0..<iterations    {
        typ :: int
        arr := make([]typ,size) 
        defer delete(arr)

        for j in 0..<len(arr) {
            arr[j] = cast(typ)j
        }

        arr2 := slice.clone(arr)
        defer delete(arr2)

        s : time.Tick
        r : int

        s = time.tick_now()
        for i in 0..<100 {
            j := i * size / 100
            slice.rotate_left(arr2,j)
        }
        d := time.tick_since(s)


        s = time.tick_now()
        for i in 0..<100 {
            j := i * size / 100
            rotate_left(arr,j)
        }
        d2 := time.tick_since(s)

        min_slice_rotate = min(min_slice_rotate, d)
        min_updated_rotate = min(min_updated_rotate, d2)    
        
        // check sameness
        for i in 0..<len(arr) {
            if arr[i] != arr2[i] {
                fmt.println("error: arr")
                fmt.println(arr)
                fmt.println("arr2")
                fmt.println(arr2)
                panic("not same rotation")
            }
        }
    }

    fmt.println("size:",size,"iter:",iterations, "slice.rotate: ",min_slice_rotate, "small_rotate: ", min_updated_rotate, "diff: ", f64(min_slice_rotate) / f64(min_updated_rotate))
}
test_speed_worse_case :: proc(size : int){
    min_slice_rotate := time.MAX_DURATION
    min_updated_rotate := time.MAX_DURATION

    iterations := max(5, 100_000 / max(1,size))
    // iterations = 1

    for _ in 0..<iterations    {
        typ :: int
        arr := make([]typ,size) 
        defer delete(arr)

        for j in 0..<len(arr) {
            arr[j] = cast(typ)j
        }

        arr2 := slice.clone(arr)
        defer delete(arr2)

        s : time.Tick
        r : int

        s = time.tick_now()
        for i in 0..<255 {
            j := i
            slice.rotate_left(arr2,j)
        }
        d := time.tick_since(s)


        s = time.tick_now()
        for i in 0..<255 {
            j := i
            rotate_left(arr,j)
        }
        d2 := time.tick_since(s)

        min_slice_rotate = min(min_slice_rotate, d)
        min_updated_rotate = min(min_updated_rotate, d2)    
        
        // check sameness
        for i in 0..<len(arr) {
            if arr[i] != arr2[i] {
                fmt.println("error: arr")
                fmt.println(arr)
                fmt.println("arr2")
                fmt.println(arr2)
                panic("not same rotation")
            }
        }
    }

    fmt.println("size:",size,"iter:",iterations, "slice.rotate: ",min_slice_rotate, "small_rotate: ", min_updated_rotate, "diff: ", f64(min_slice_rotate) / f64(min_updated_rotate))
}
test_speed_worste_case :: proc(size : int){
    min_slice_rotate := time.MAX_DURATION
    min_updated_rotate := time.MAX_DURATION

    iterations := max(5, 100_000 / max(1,size))
    // iterations = 1

    for _ in 0..<iterations    {
        typ :: u8
        arr := make([]typ,size) 
        defer delete(arr)

        for j in 0..<len(arr) {
            arr[j] = cast(typ)j
        }

        arr2 := slice.clone(arr)
        defer delete(arr2)

        s : time.Tick
        r : int

        s = time.tick_now()
        for i in 0..<100 {
            j := i
            slice.rotate_left(arr2,j)
        }
        d := time.tick_since(s)


        s = time.tick_now()
        for i in 0..<100 {
            j := i
            rotate_left(arr,j)
        }
        d2 := time.tick_since(s)

        min_slice_rotate = min(min_slice_rotate, d)
        min_updated_rotate = min(min_updated_rotate, d2)    
        
        // check sameness
        for i in 0..<len(arr) {
            if arr[i] != arr2[i] {
                fmt.println("error: arr")
                fmt.println(arr)
                fmt.println("arr2")
                fmt.println(arr2)
                panic("not same rotation")
            }
        }
    }

    fmt.println("size:",size,"iter:",iterations, "slice.rotate: ",min_slice_rotate, "small_rotate: ", min_updated_rotate, "diff: ", f64(min_slice_rotate) / f64(min_updated_rotate))
}