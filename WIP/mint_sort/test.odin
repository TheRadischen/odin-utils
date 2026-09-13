package msort

import "core:time"
import "core:slice"
import "core:math/rand"
import "core:fmt"


main :: proc(){
	test_thread()
	// test(100_000)

	for _ in 0..<1000 {
		// test_rev()
	}
	
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


test_thread :: proc(){
	size := 100000
	arr := make([]int,size, context.temp_allocator)
	for &a in arr { a = rand.int_max(size) }

	sort_stable_threaded(arr)

	if !slice.is_sorted(arr) {
		fmt.println(arr, length)
		panic("not sorted")

	}
}