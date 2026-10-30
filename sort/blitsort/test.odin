// #+ignore
package blit

import "core:time"
import "core:math/rand"
import "core:slice"
import "base:runtime"
import "base:intrinsics"
import "core:fmt"

import "core:sort"



SIZE :: 1000_000
ITER :: 100

main :: proc(){

	arr := make([]int, SIZE)
	times : [ITER]time.Duration


	fmt.println("sorting 100_000 elements; Iterations", ITER)
	fmt.println("fastest time | 25% time | 50% time | function name")

	fmt.println()
	fmt.println("random []int")

	for i in 0..<ITER {
		rand_arr(arr)
		start := time.tick_now()
		blitsort(arr, greater_int)
		times[i] = time.tick_since(start)
		if !slice.is_sorted(arr) {fmt.println(arr[:min(28,SIZE)]);panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  blitsort", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		rand_arr(arr)
		start := time.tick_now()
		quadsort(arr, greater_int, context.temp_allocator)
		times[i] = time.tick_since(start)
		if !slice.is_sorted(arr) {fmt.println(arr[len(arr)-100:]);panic("did not sort")}
		free_all(context.temp_allocator)
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  quadsort", times[0], times[ITER / 4], times[ITER / 2])
	

}

less_int :: #force_inline  proc(l,r:int)->bool{return l < r}
greater_int :: #force_inline  proc(l,r:int)->bool{return l > r}

rand_arr :: proc(arr: []int) {
	for &a in arr {
		a = len(arr) / 2 - rand.int_max(len(arr))
	}
}
