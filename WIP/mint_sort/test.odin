package ermsort

import "shared:min_sort"
// import "shared:min_sort"
import "core:mem"
import "core:thread"
import "core:time"
import "core:slice"
import "core:math/rand"
import "core:fmt"


main :: proc(){
		// test_thread(200)
	for i := 10_001; i <= 900_000_000; i *= 10 {
		test_thread(i)
	}
	
	// test(100_000)

	// for _ in 0..<1000 {
	// 	// test_rev()
	// }
	// fmt.println("exit")
	
}
copy_duration :i64=0
copy_duration1 :i64=0
copy_duration2 :i64=0
copy_duration3 :i64=0
copy_duration11 :i64=0
copy_duration22 :i64=0
copy_duration33 :i64=0
comps := 0
test :: proc(size: int) {
	iter := 100
	times := make([]time.Duration, iter)
	for i in 0..<iter {
		arr := make([]int,size, context.temp_allocator)
		for &a in arr { a = rand.int_max(size) }
		// for &a,i in arr { a = size - i }
		

		start := time.tick_now()
		// sort_stable_by(arr, proc(l,r:int) -> bool {comps += 1; return l < r}, context.temp_allocator)
		// sort_stable_reverse(arr, context.temp_allocator)
		sort_stable(arr, context.temp_allocator)
		// sort_inlined(arr)
		dur := time.tick_since(start)

		if !slice.is_sorted(arr) {
			fmt.println("not sorted lmao")
			fmt.println(arr)
		}
		times[i] = dur
		free_all(context.temp_allocator)
	}
	slice.sort(times)

	fmt.println(times[0], times[iter / 2])
	// fmt.println("comps: ",comps)
	// fmt.println("copy0: ", copy_duration)
	// fmt.println("copy1: ", copy_duration1)
	// fmt.println("copy2: ", copy_duration2)
	// fmt.println("copy3: ", copy_duration3)
	// fmt.println("copy11: ", copy_duration11)
	// fmt.println("copy22: ", copy_duration22)
	// fmt.println("copy33: ", copy_duration33)

}

length : int
test_rev :: proc() {
	size := 100_000
	arr := make([]int,size, context.temp_allocator)
	for &a in arr { a = rand.int_max(size) }
		// fmt.println(arr)
		length = 0
	sort_stable_reverse(arr)

	if !slice.is_sorted(arr) {
		fmt.println(arr, length)
		panic("not sorted")

	}

}


test_thread :: proc(size: int){
	// size := 1_00_000_000
	// size := 2_000_000
	arr := make([]int,size, context.allocator)
	defer delete(arr)


	iter :: 20
	times1 : [iter]time.Duration
	times2 : [iter]time.Duration
	mint1 := time.MAX_DURATION
	mint2 := time.MAX_DURATION

// for &a in arr { a = rand.int_max(size * 1) }


	for i in 0..<iter {
		for &a in arr { a = rand.int_max(size * 10) }
		start := time.tick_now()
		sort_inlined_threaded(arr)
		times1[i] = time.tick_since(start)

		if !slice.is_sorted(arr) {
			fmt.println(arr[:], length)
			panic("not sorted")
		}
		for &a in arr { a = rand.int_max(size * 10) }

		start = time.tick_now()
		sort_parallel(arr, 8, context.allocator)
		// sort_inlined_threaded(arr)
		// min_sort.sort(arr)

		times2[i] = time.tick_since(start)
		
	}
	slice.sort(times1[:])
	slice.sort(times2[:])
	fmt.println("testing: ", size)
	fmt.println("stable threaded: ", times2[0], times2[iter / 4], times2[iter / 2])
	fmt.println("unstable threaded: ", times1[0], times1[iter / 4], times1[iter / 2])


}