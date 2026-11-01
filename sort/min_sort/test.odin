// #+ignore
package msort

import "core:time"
import "core:math/rand"
import "core:slice"
import "base:runtime"
import "base:intrinsics"
import "core:fmt"

import "core:sort"



SIZE :: 10_000_000
ITER :: 2

main :: proc(){

	arr := make([]int, SIZE)
	arr32 := make([]i32, SIZE)
	data := make([]Data, SIZE)
	data_soa := make(#soa[]Data, SIZE)
	times : [ITER]time.Duration
	
	
	// for i in 0..<ITER {
	// 	ran(arr)
	// 	start := time.tick_now()
	// 	sort_stable_stack(arr)
	// 	times[i] = time.tick_since(start)
	// 	if !is_sorted(arr) {fmt.println(arr);panic("did not sort")}
	// }
	// slice.sort(times[:])
	// fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack", times[0], times[ITER / 4], times[ITER / 2])

	// {return}

	for i := 10; i <= 1_000_000; i *= 10 {
		sort_sizes(i)
	}
	sort_sizes :: proc(size: int) {
		arr := make([]int, size)
		defer delete(arr)
		iter := 1_000_000 / size 
		min_time : time.Duration = time.MAX_DURATION
		for i in 0..<clamp(iter, 1, 10_000) {
			ran(arr)
			start := time.tick_now()
			sort_inlined(arr)
			dur := time.tick_since(start)
			min_time = min(min_time, dur)
		}
		// fmt.println("size:",size,"time:",min_time)
		min_time2 : time.Duration = time.MAX_DURATION
		for i in 0..<clamp(iter / 10, 1, 10_000) {
			ran(arr)
			start := time.tick_now()
			slice.sort(arr)
			dur := time.tick_since(start)
			min_time2 = min(min_time2, dur)
		}
		// fmt.println("size:",size,"time:",min_time2)
		fmt.println("size: ",size," slice.sort / sort_inlined: ", f64(min_time2) / f64(min_time))
	}

	fmt.println("sorting 100_000 elements; Iterations", ITER)
	fmt.println("fastest time | 25% time | 50% time | function name")

	fmt.println()
	fmt.println("random []i32")

	for i in 0..<ITER {
		ran(arr32)
		start := time.tick_now()
		sort_inlined(arr32)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {fmt.println(arr[:min(28,SIZE)]);panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined", times[0], times[ITER / 4], times[ITER / 2])

	fmt.println()
	fmt.println("random []int")

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		sort_inlined(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {fmt.println(arr[:min(28,SIZE)]);panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		sort_stable(arr, context.temp_allocator)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {fmt.println(arr[len(arr)-100:]);panic("did not sort")}
		free_all(context.temp_allocator)
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		piposort(arr, less_int, context.temp_allocator)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {fmt.println(arr[len(arr)-100:]);panic("did not sort")}
		free_all(context.temp_allocator)
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  piposort", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		sort_stable_stack(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		slice.sort(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		radix(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  radix", times[0], times[ITER / 4], times[ITER / 2])

	fmt.println()
	fmt.println("ascending []int")

	for i in 0..<ITER {
		start := time.tick_now()
		sort_inlined_by(arr, less_int)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {fmt.println(arr[:min(28,SIZE)]);panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		start := time.tick_now()
		sort_stable(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		start := time.tick_now()
		piposort(arr, less_int, context.temp_allocator)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  piposort", times[0], times[ITER / 4], times[ITER / 2])
		free_all(context.temp_allocator)
	
	for i in 0..<ITER {
		start := time.tick_now()
		sort_stable_stack_by(arr, less_int)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		start := time.tick_now()
		slice.sort_by(arr, less_int)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		start := time.tick_now()
		radix(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  radix", times[0], times[ITER / 4], times[ITER / 2])

	fmt.println()
	fmt.println("i % 100 []int")

	for i in 0..<ITER {
		for &a, i in arr { a = i % 100 }
		start := time.tick_now()
		sort_inlined_by(arr, less_int)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {fmt.println(arr[:min(28,SIZE)]);panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		for &a, i in arr { a = i % 100 }
		start := time.tick_now()
		sort_stable(arr)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		for &a, i in arr { a = i % 100 }
		start := time.tick_now()
		piposort(arr, less_int, context.temp_allocator)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  piposort", times[0], times[ITER / 4], times[ITER / 2])
		free_all(context.temp_allocator)
	
	for i in 0..<ITER {
		for &a, i in arr { a = i % 100 }
		start := time.tick_now()
		sort_stable_stack_by(arr, less_int)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		for &a, i in arr { a = i % 100 }
		start := time.tick_now()
		slice.sort_by(arr, less_int)
		times[i] = time.tick_since(start)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort", times[0], times[ITER / 4], times[ITER / 2])
	

	fmt.printfln("")
	fmt.println("random []Data by less | size of Data: ", size_of(Data))
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_inlined_by(data, less_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_by", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_by(data, less_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_by", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_stack_by(data, less_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		slice.sort_by(data, less_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort_by", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		radix(data, proc(d: Data) -> int {return d.rand})
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
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
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		ind := sort_stable_with_indices(arr)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		ind := sort_stable_stack_with_indices(arr)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(arr)
		start := time.tick_now()
		ind := slice.sort_with_indices(arr)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(arr) {panic("did not sort")}
	}
	slice.sort(times[:])
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
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_by_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_stable_by_with_indices(data, less_data)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_by_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_stable_stack_by_with_indices(data, less_data)
		times[i] = time.tick_since(start)
		delete(ind)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by_with_indices", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		slice.sort_by_with_indices(data, less_data, context.temp_allocator)
		times[i] = time.tick_since(start)
		free_all(context.temp_allocator)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
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
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_by_with_data(data, less_data_modulus, &modulus)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_stack_by_with_data(data, less_data_modulus, &modulus)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		slice.sort_by_with_data(data, less_data_modulus_raw, &modulus)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	slice.sort(times[:])
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
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_inlined_by_with_indices_with_data", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_stable_by_with_indices_with_data(data, less_data_modulus, &modulus)
		delete(ind)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_by_with_indices_with_data", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := sort_stable_stack_by_with_indices_with_data(data, less_data_modulus, &modulus)
		delete(ind)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by_with_indices_with_data", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		ind := slice.sort_by_with_indices_with_data(data, less_data_modulus_raw, &modulus)
		delete(ind)
		times[i] = time.tick_since(start)
		if !is_sorted_mod(data) {panic("did not sort")}
		
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  slice.sort_by_with_indices_with_data", times[0], times[ITER / 4], times[ITER / 2])
	
	for i in 0..<ITER {
		ran(data)
		start := time.tick_now()
		sort_stable_stack_by_cmp(data, cmp_data)
		times[i] = time.tick_since(start)
		if !is_sorted(data) {panic("did not sort")}
	}
	slice.sort(times[:])
	fmt.printfln("%v  |  %v  |  %v  |  sort_stable_stack_by_with_data", times[0], times[ITER / 4], times[ITER / 2])

}

Data :: struct {
	rand:int,
	index:int,
	data:[20]int,
}

comps := 0
less_int :: #force_inline  proc(l,r:int)->bool{return l < r}
less_data :: #force_inline proc(l,r:Data)->bool{return l.rand < r.rand}
cmp_data :: #force_inline  proc(l,r:Data)->Ordering{
	if l.rand < r.rand {return .Less}
	if l.rand > r.rand {return .Greater}
	return .Equal
}
less_soa :: #force_inline  proc(l, r: Data) -> bool { return l.rand < r.rand }
modulus := []int{5,4,6,7,3,2,1,8,9,0}
less_data_modulus :: proc(l,r:Data, mod: ^[]int)->bool{
	left := l.rand %% 100
	right := r.rand %% 100
	return mod[left] < mod[right]
}
less_data_modulus_raw :: proc(l,r:Data, user_data: rawptr)->bool{
	mod := (^[]int)(user_data)
	left := l.rand %% 100
	right := r.rand %% 100
	return mod[left] < mod[right]
}

ran :: proc{rand_arr, rand_data, rand_soa,rand_data_soa,rand_arr32}
rand_arr :: proc(arr: []int) {
	for &a in arr {
		a = len(arr) / 2 - rand.int_max(len(arr))
		// a = next_rng(&seed)
	}
}
seed := 1000
next_rng :: proc(seed: ^int) -> int {
	seed^ ~= seed^ << 13
	seed^ ~= seed^ >> 7
	seed^ ~= seed^ << 17
	return seed^ %% SIZE
}
/*
impl SimpleRng {
    fn new(seed: u64) -> Self {
        Self { state: seed }
    }

    fn next_u64(&mut self) -> u64 {
        self.state ^= self.state << 13;
        self.state ^= self.state >> 7;
        self.state ^= self.state << 17;
        self.state
    }

    fn next_usize(&mut self, max: usize) -> usize {
        (self.next_u64() as usize) % max
    }
}
*/
rand_arr32 :: proc(arr: []i32) {
	for &a in arr {
		a = i32(len(arr) / 2 - rand.int_max(len(arr)))
	}
}
rand_soa :: proc(arr: #soa[][$N]int) {
	for &a in arr {
		a.x = len(arr) / 2 - rand.int_max(len(arr))
	}
}
rand_data :: proc(arr: []Data) {
	for &a,i in arr {
		a.rand = len(arr) / 2 - rand.int_max(len(arr))
		a.index = i
	}
}
rand_data_soa :: proc(arr: #soa[]Data) {
	for &a,i in arr {
		a.rand = len(arr) / 2 - rand.int_max(len(arr))
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
