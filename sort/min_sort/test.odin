package msort

import "core:time"
import "core:math/rand"
import "core:slice"
import "base:runtime"
import "base:intrinsics"
import "core:fmt"
import "shared:scandum"

CMP :: #type proc(int,int) -> bool
less ::  proc(l,r:int)->bool{return l < r}
less10 ::  proc(l,r:[10]int)->bool{return l[0] < r[0]}
less_soa :: proc(l,r:[4]int)->bool{return l.x < r.x}
greater ::  proc(l,r:int)->bool{return l > r}



main :: proc() {


    fmt.println("BIG")
    test_inplace_big(100)
    test_inplace_big(20)
    test_inplace_big(10)

    // {return}
    fmt.println()
    fmt.println("inplace(100_000 int)")
    test_sort_inplace_100_000()
    // {return}
    
    fmt.println()
    fmt.println("inplace(int)")
    for i :i64= 10; i <= 1_000_000; i *= 10 {
        test_sort_inplace(i)
    }
    // {return}
    fmt.println()
    fmt.println("sort(int)")
    for i :i64= 10; i <= 1_000_000; i *= 10 {
        test_sort(i)
    }
    fmt.println()
    fmt.println("sort_with_indecies(int)")
    for i :i64= 10; i <= 1_00_000; i *= 10 {
        test_indices(i)
    }
    fmt.println()
    fmt.println("sort_by_with_indecies([10]int)")
    for i :i64= 10; i <= 1_00_000; i *= 10 {
        test_indices_by(i)
    }
    fmt.println()
    fmt.println("soa_sort_by([4]int)")
    for i :i64= 10; i <= 1_00_000; i *= 10 {
        test_soa(i)
    }
    fmt.println()
    fmt.println("soa_stable_sort_by([4]int)")
    for i :i64= 10; i <= 1_00_000; i *= 10 {
        test_stablity(i)
    }

}


test_inplace_big:: proc($size: int) {
    Big :: struct {
        data: [size]int,
        ind: int,
    }
    fmt.println(size_of(Big))
    SIZE :: 100_00

    min1 := time.MAX_DURATION
    for i in 0..<100 {
        arr1 := make([]Big,SIZE)

        for i in 0..<len(arr1) {
            // arr1[i] = i
            arr1[i].ind = rand.int_max(SIZE)
        }

        // temp := slice.clone(arr1)

        defer {
            delete(arr1)
            // delete(temp)
        }

        sum  := 0
        for a in arr1 {
            sum += a.ind
        }

        
        start := time.tick_now()
        sort_by_inplace(arr1, proc(l,r: Big) -> bool{return l.ind < r.ind})
        // slice.sort(arr1)
        end1 := time.tick_since(start)


        min1 = min(min1, end1)

        

        for a in arr1 {
            sum -= a.ind
        }

        if sum != 0 {
            panic("sum not right")
        }

        // for i in 1..<len(arr1) {
        //     if arr1[i - 1] > arr1[i] {
        //         fmt.println(arr1[i - 1], arr1[i], i)
        //     }
        // }
        if !slice.is_sorted_by(arr1, proc(l,r: Big) -> bool{return l.ind < r.ind}) {
            fmt.println(arr1)
            fmt.println(len(arr1))
            fmt.println(i)
            
            panic("not sorted1")
        }
        
    }
    fmt.println("size",size," ","lumoto: ",min1)


}


test_sort_inplace_100_000 :: proc() {
    // iter := 2

    SIZE :: 100_000

    min1 := time.MAX_DURATION
    for i in 0..<100 {
        arr1 := make([]int,SIZE)

        for i in 0..<len(arr1) {
            arr1[i] = rand.int_max(SIZE)
        }

        defer {
            delete(arr1)
        }

        sum  := 0
        for a in arr1 {
            sum += a
        }

        
        start := time.tick_now()
        sort_inplace(arr1)
        // slice.sort(arr1)
        end1 := time.tick_since(start)


        min1 = min(min1, end1)

        

        for a in arr1 {
            sum -= a
        }

        if sum != 0 {
            panic("sum not right")
        }

        // for i in 1..<len(arr1) {
        //     if arr1[i - 1] > arr1[i] {
        //         fmt.println(arr1[i - 1], arr1[i], i)
        //     }
        // }
        if !slice.is_sorted(arr1) {
            fmt.println(arr1)
            fmt.println(len(arr1))
            fmt.println(i)
            
            panic("not sorted1")
        }
        
    }
    fmt.println("size",100_000,"  ","lumoto: ",min1)


}


test_sort :: proc(size: i64) {
    min1 := max(i64)
    min2 := max(i64)
    // iter := 2
    iter := clamp(1_000_000 / size, 4, 10_000)

    for i in 0..<iter {
        arr1 := make([]int,size)
        for i in 0..<len(arr1) {
            arr1[i] = rand.int_max(int(size))
        }
        arr2 := slice.clone(arr1)

        defer {
            delete(arr1)
            delete(arr2)
        }

        start := intrinsics.read_cycle_counter()
        sort(arr1)
        end1 := intrinsics.read_cycle_counter() - start

        start2 := intrinsics.read_cycle_counter()
        slice.sort(arr2)
        end2 := intrinsics.read_cycle_counter() - start2

        min1 = min(min1, end1)
        min2 = min(min2, end2)

        if !slice.is_sorted(arr1) {
            panic("not sorted1")
        }
        if !slice.is_sorted(arr2) {
            panic("not sorted2")
        }
    }

    sizelg := size

    fmt.println("iter",iter,"size",size," in cycles / item ","mini_flux: ",min1 / sizelg,"slice.sort: ",min2 / sizelg, "diff: ", (f64)(min2) / (f64)(min1))
}

test_sort_inplace :: proc(size: i64) {
    min1 := max(i64)
    min2 := max(i64)
    // iter := 2
    iter := clamp(1_000_000 / size, 4, 10_000)

    for i in 0..<iter {
        arr1 := make([]int,size)
        for i in 0..<len(arr1) {
            arr1[i] = rand.int_max(int(size))
        }
        arr2 := slice.clone(arr1)

        defer {
            delete(arr1)
            delete(arr2)
        }

        start := intrinsics.read_cycle_counter()
        sort_inplace(arr1)
        end1 := intrinsics.read_cycle_counter() - start

        start2 := intrinsics.read_cycle_counter()
        sort(arr2)
        end2 := intrinsics.read_cycle_counter() - start2

        min1 = min(min1, end1)
        min2 = min(min2, end2)

        if !slice.is_sorted(arr1) {
            fmt.println(arr1)
            panic("not sorted1")
        }
        if !slice.is_sorted(arr2) {
            panic("not sorted2")
        }
    }

    sizelg := size

    fmt.println("iter",iter,"size",size," in cycles / item ","lumoto: ",min1 / sizelg,"flux: ",min2 / sizelg, "diff: ", (f64)(min2) / (f64)(min1))
}

test_indices :: proc(size: i64) {
    Test :: int
    min1 := max(i64)
    min2 := max(i64)
    // iter := 2
    iter := clamp(1_000_000 / size, 4, 10_000)

    for i in 0..<iter {
        arr1 := make([]Test,size)
        for i in 0..<len(arr1) {
            arr1[i] = rand.int_max(int(size))
        }
        arr2 := slice.clone(arr1)

        defer {
            delete(arr1)
            delete(arr2)
        }

        start := intrinsics.read_cycle_counter()
        sort_with_indices(arr1)
        end1 := intrinsics.read_cycle_counter() - start

        start2 := intrinsics.read_cycle_counter()
        slice.sort_with_indices(arr2)
        end2 := intrinsics.read_cycle_counter() - start2

        min1 = min(min1, end1)
        min2 = min(min2, end2)

        if !slice.is_sorted(arr1) {
            panic("not sorted1")
        }
        if !slice.is_sorted(arr2) {
            panic("not sorted2")
        }
    }

    sizelg := size

    fmt.println("iter",iter,"size",size," in cycles / item ","mini_flux: ",min1 / sizelg,"slice.sort: ",min2 / sizelg, "diff: ", (f64)(min2) / (f64)(min1))
}

test_indices_by :: proc(size: i64) {
    Test :: [10]int
    min1 := max(i64)
    min2 := max(i64)
    // iter := 2
    iter := clamp(1_000_000 / size, 4, 10_000)

    for i in 0..<iter {
        arr1 := make([]Test,size)
        for i in 0..<len(arr1) {
            arr1[i][0] = rand.int_max(int(size))
        }
        arr2 := slice.clone(arr1)

        defer {
            delete(arr1)
            delete(arr2)
        }

        start := intrinsics.read_cycle_counter()
        sort_by_with_indices(arr1, less10)
        end1 := intrinsics.read_cycle_counter() - start

        start2 := intrinsics.read_cycle_counter()
        slice.sort_by_with_indices(arr2, less10)
        end2 := intrinsics.read_cycle_counter() - start2

        min1 = min(min1, end1)
        min2 = min(min2, end2)

        if !slice.is_sorted_by(arr1,less10) {
            panic("not sorted1")
        }
        if !slice.is_sorted_by(arr2,less10) {
            panic("not sorted2")
        }
    }

    sizelg := size

    fmt.println("iter",iter,"size",size," in cycles / item ","mini_flux: ",min1 / sizelg,"slice.sort: ",min2 / sizelg, "diff: ", (f64)(min2) / (f64)(min1))
}

test_soa :: proc(size: i64) {
    Test :: [4]int
    min1 := max(i64)
    min2 := max(i64)
    // iter := 2
    iter := clamp(1_000_000 / size, 4, 10_000)

    for i in 0..<iter {
        arr1 := make(#soa[]Test,size)
        for i in 0..<len(arr1) {
            arr1[i].x = rand.int_max(int(size))
        }

        defer {
            delete(arr1)
        }

        start := intrinsics.read_cycle_counter()
        soa_sort_by(arr1, less_soa)
        // scandum.blitsort(arr1,proc(l,r:[4]int)->bool{return l.x > r.x})
        end1 := intrinsics.read_cycle_counter() - start


        min1 = min(min1, end1)

        for i in 1..<len(arr1) {
            if arr1[i-1].x > arr1[i].x {
                s1,s2,s3,s4 := soa_unzip(arr1)
                fmt.println(s1)
                panic("not sorted soa")
            }
        }

    }

    sizelg := size

    fmt.println("iter",iter,"size",size," in cycles / item ","mini_flux: ",min1 / sizelg)
}


test_stablity :: proc(size: i64) {
    Test :: [4]int
    min1 := max(i64)
    min2 := max(i64)
    // iter := 2
    iter := clamp(1_000_000 / size, 4, 10_000)

    for i in 0..<iter {
        arr1 := make(#soa[]Test,size)
        for i in 0..<len(arr1) {
            arr1[i].x = rand.int_max(int(size % 10 + 1))
            arr1[i].y = i
        }

        defer {
            delete(arr1)
        }

        start := intrinsics.read_cycle_counter()
        soa_sort_by(arr1, less_soa)
        // scandum.blitsort(arr1,proc(l,r:[4]int)->bool{return l.x > r.x})
        end1 := intrinsics.read_cycle_counter() - start


        min1 = min(min1, end1)

        sum := arr1[0].y
        for i in 1..<len(arr1) {
            sum += arr1[i].y
            if arr1[i-1].x > arr1[i].x {

                s1,s2,s3,s4 := soa_unzip(arr1)
                fmt.println(s1)
                panic("not sorted soa")
            }
            if arr1[i-1].x < arr1[i].x {continue}
            if arr1[i-1].y > arr1[i].y {
                
                s1,s2,s3,s4 := soa_unzip(arr1)
                fmt.println(s1)
                panic("not sorted stable soa")
            }
        }
        assert(sum == int(size * (size - 1) / 2), "not stable")

    }

    sizelg := size

    fmt.println("iter",iter,"size",size," in cycles / item ","mini_flux: ",min1 / sizelg)
}
