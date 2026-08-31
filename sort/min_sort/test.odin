// #+ignore
package msort

import "core:time"
import "core:math/rand"
import "core:slice"
import "base:runtime"
import "base:intrinsics"
import "core:fmt"

import "core:sort"



SIZE :: 100_000
main :: proc(){
	arr := make([]int, SIZE)
	data := make([]Data, SIZE)
	ITER :: 10
	times : [ITER]time.Duration
	fmt.println("sorting 100_000 elements; Iterations", ITER)
	fmt.println("fastest time | 25% time | 50% time | function name")

	fmt.println()
	fmt.println("random []int")

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		sort_inlined(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		sort_stable(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		sort_stable_stack(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		slice.sort(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		radix(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  radix", times[0], times[ITER / 4], times[ITER / 2])

	fmt.printfln("")
	fmt.println("random []Data by less")
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_inlined_by(data, less_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_by", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_by(data, less_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_by", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_stack_by(data, less_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		slice.sort_by(data, less_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort_by", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		radix(data, proc(d: Data) -> int {return d.rand})
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  radix_by", times[0], times[ITER / 4], times[ITER / 2])

	fmt.printfln("")
	fmt.println("random []int with indecies")
	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		ind := sort_inlined_with_indices(arr)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		ind := sort_stable_with_indices(arr)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		ind := sort_stable_stack_with_indices(arr)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		ind := slice.sort_with_indices(arr)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(arr) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	fmt.printfln("")
	fmt.println("random []Data with indecies")
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_inlined_by_with_indices(data, less_data)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_by_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_stable_by_with_indices(data, less_data)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_by_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_stable_stack_by_with_indices(data, less_data)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		slice.sort_by_with_indices(data, less_data, context.temp_allocator)
		times[i] = time.tick_since(start)
		free_all(context.temp_allocator)
		if !is_sorted(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort_by_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	fmt.printfln("")
	fmt.println("random []Data with modulus data")
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_inlined_by_with_data(data, less_data_modulus, &modulus)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_by_with_data(data, less_data_modulus, &modulus)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_stack_by_with_data(data, less_data_modulus, &modulus)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		slice.sort_by_with_data(data, less_data_modulus_raw, &modulus)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

	fmt.printfln("")
	fmt.println("random []Data with modulus data with indices")
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_inlined_by_with_indices_with_data(data, less_data_modulus, &modulus)
		delete(ind)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_by_with_indices_with_data", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_stable_by_with_indices_with_data(data, less_data_modulus, &modulus)
		delete(ind)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_by_with_indices_with_data", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_stable_stack_by_with_indices_with_data(data, less_data_modulus, &modulus)
		delete(ind)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by_with_indices_with_data", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := slice.sort_by_with_indices_with_data(data, less_data_modulus_raw, &modulus)
		delete(ind)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	sort_inlined(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort_by_with_indices_with_data", times[0], times[ITER / 4], times[ITER / 2])
	
	// fmt.printfln("%v  |  %v  |  %v  |  ")
	// fmt.printfln("%v  |  %v  |  %v  |  random []Data by cmp")
	// for i in 0..<ITER {
	// 	ran(data)
	// 	start := time.tick_now()
	// 	sort_stable_stack_by_cmp(data, cmp_data)
	// 	times[i] = time.tick_since(start)
	// 	if !is_sorted(data) {panic("did not sort")}
	// }
	// sort_inlined(times[:])
	// fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

}

Data :: struct {
	rand:int,
	index:int,
	data:[20]int,
}

less_int :: proc(l,r:int)->bool{return l < r}
less_data :: proc(l,r:Data)->bool{return l.rand < r.rand}
modulus := []int{5,4,6,7,3,2,1,8,9,0}
less_data_modulus :: proc(l,r:Data, mod: ^[]int)->bool{
	left := l.rand %% 10
	right := r.rand %% 10
	return mod[left] < mod[right]
}
less_data_modulus_raw :: proc(l,r:Data, user_data: rawptr)->bool{
	mod := (^[]int)(user_data)
	left := l.rand %% 10
	right := r.rand %% 10
	return mod[left] < mod[right]
}

ran :: proc{rand_arr, rand_data}
rand_arr :: proc(arr: []int) {
	for &a in arr {
		a = rand.int_max(len(arr))
	}
}
rand_data :: proc(arr: []Data) {
	for &a,i in arr {
		a.rand = rand.int_max(len(arr))
		a.index = i
	}
}

is_sorted :: proc{slice.is_sorted, is_sorted_data}
is_sorted_data :: proc(arr: []Data) -> bool {
	for i in 1..<len(arr) {
		if arr[i - 1].rand > arr[i].rand {
			return false
		}
	}
	return true
}

is_sorted_mod :: proc(arr: []Data) -> bool {
	for i in 1..<len(arr) {
		if less_data_modulus(arr[i], arr[i - 1], &modulus) {
			return false
		}
	}
	return true
}
