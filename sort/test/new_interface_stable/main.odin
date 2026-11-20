package stable

import "core:sort"
import "base:builtin"
import "base:intrinsics"
import "core:slice"
import "core:math/rand"
import "core:time"
import "core:fmt"


main :: proc() {
	
	for i := 1; i <= 1_000_000; i *= 2 {
		sort_sizes(i, int)
	}
	for i := 10; i <= 1_000_000; i *= 2 {
		stability(i, f32)
	}
	for i := 10; i <= 1_000_000; i *= 2 {
		test_comps(i, int)
	}
	arr := make([]int, 100_000)
	for &a,j in arr {a = j}		
	it := sort.slice_interface(&arr)
	sort.stable_sort(it)
	assert(slice.is_sorted(arr))
	for &a,j in arr {a = 100_000 - j}		
	sort.stable_sort(it)
	assert(slice.is_sorted(arr))
	for &a,j in arr {a = 0}		
	sort.stable_sort(it)
	assert(slice.is_sorted(arr))
}

Data :: struct($T: typeid) {
	rand: T,
	index: int,
	junk: [1]int,
}
comps: int
sort_sizes :: proc(size: int, $T: typeid) {
	// arr := make([]Data(T), size)
	arr := make([]T, size)
	defer delete(arr)
	iter := 1_0_000 / size 
	min_time : time.Duration = time.MAX_DURATION
	min_time2 : time.Duration = time.MAX_DURATION
	min_time3 : time.Duration = time.MAX_DURATION
	smooth_cmp: int
	quick_cmp: int
	for i in 0..<clamp(iter, 1, 10_000) {
		for &a,j in arr {a = cast(int)rand.int63()}
		start := time.tick_now()

		it := sort.slice_interface(&arr)

		sort.stable_sort(it)

		dur := time.tick_since(start)
		min_time = min(min_time, dur)
		if !slice.is_sorted(arr) {
			fmt.println(typeid_of(T), size)
			panic("not sorted, merge")
		}

		for &a,j in arr { a = cast(int)rand.int63() }
		start2 := time.tick_now()

		sort.sort(it)

		dur2 := time.tick_since(start2)
		min_time2 = min(min_time2, dur2)
		if !slice.is_sorted(arr) {
			fmt.println(typeid_of(T), size)
			panic("not sorted, quick")
		}

		for &a,j in arr { a = cast(int)rand.int63() }
		start3 := time.tick_now()

		slice.sort(arr)

		dur3 := time.tick_since(start3)
		min_time3 = min(min_time3, dur3)
		if !slice.is_sorted(arr) {
			fmt.println(typeid_of(T), size)
			panic("not sorted, quick")
		}
	}
	fmt.printfln( "input length: %v, new stable interface: %v, unstable interface %v, slice.sort: %v", size, min_time, min_time2, min_time3)
}

stability :: proc(size: int, $T: typeid) {
	arr := make([]Data(T), size)
	defer delete(arr)
	iter := 1__000 / size 
	min_time : time.Duration = time.MAX_DURATION
	min_time2 : time.Duration = time.MAX_DURATION
	smooth_cmp: int
	quick_cmp: int
	for i in 0..<clamp(iter, 1, 10_000) {
		// ran(arr)
		modu(arr)
		start := time.tick_now()
		comps = 0
		it := sort.Interface {
			collection = rawptr(&arr),
			len = proc(it: sort.Interface) -> int {
				s := (^[]Data(T))(it.collection)
				return len(s^)
			},
			less = proc(it: sort.Interface, i, j: int) -> bool {
				s := (^[]Data(T))(it.collection)
				return s[i].rand < s[j].rand
			},
			swap = proc(it: sort.Interface, i, j: int) {
				s := (^[]Data(T))(it.collection)
				s[i], s[j] = s[j], s[i]
			},
		}
		sort.stable_sort(it)


		dur := time.tick_since(start)
		min_time = min(min_time, dur)
		sorted, stabel := is_sorted_stable_data(arr)
		if !sorted {
			fmt.println(typeid_of(T), size)
			panic("not sorted")
		}		
		if !stabel {
			for a in arr {
				fmt.println(a.rand, a.index)
			}
			fmt.println(size)
			panic("not stable")
		}


	}
	fmt.println("time:",min_time, " stable")
}


test_comps :: proc(size: int, $T: typeid) {
	arr := make([]Data(T), size)
	defer delete(arr)
	iter := 1__000 / size 
	min_time : time.Duration = time.MAX_DURATION
	min_time2 : time.Duration = time.MAX_DURATION
	smooth_cmp: int
	quick_cmp: int
	for i in 0..<clamp(iter, 1, 10_000) {
		// ran(arr)
		ran(arr)
		start := time.tick_now()
		comps = 0
		it := sort.Interface {
			collection = rawptr(&arr),
			len = proc(it: sort.Interface) -> int {
				s := (^[]Data(T))(it.collection)
				return len(s^)
			},
			less = proc(it: sort.Interface, i, j: int) -> bool {
				s := (^[]Data(T))(it.collection)
				comps += 1
				return s[i].rand < s[j].rand
			},
			swap = proc(it: sort.Interface, i, j: int) {
				s := (^[]Data(T))(it.collection)
				s[i], s[j] = s[j], s[i]
			},
		}
		sort.stable_sort(it)


		dur := time.tick_since(start)
		min_time = min(min_time, dur)
		sorted, stabel := is_sorted_stable_data(arr)
		if !sorted {
			fmt.println(typeid_of(T), size)
			panic("not sorted")
		}		
		if !stabel {
			for a in arr {
				fmt.println(a.rand, a.index)
			}
			fmt.println(size)
			panic("not stable")
		}
		fmt.print("size: ", size,"")
		fmt.print("stable interface comps:", comps,"")
		c1 := comps

		comps = 0
		ran(arr)

		slice.sort_by(arr, proc(l,r:Data(int)) -> bool {comps += 1;return l.rand < r.rand})


		fmt.print("slice.sort comps:", comps,"",f64(comps) / f64(c1))
		fmt.println()
		break

	}
}

is_sorted_stable_data :: proc(arr: []Data($T)) -> (sorted: bool = true, stable: bool = true) {
	for i in 1..<len(arr) {
		if arr[i - 1].rand < arr[i].rand { continue }
		if arr[i - 1].rand > arr[i].rand { sorted = false; break }
		if arr[i - 1].index > arr[i].index { stable = false }
	}
	return 
}

// slice_interface :: proc(s: ^$T/[]$E) -> Interface where ORD(E) {
// 	return Interface{
// 		collection = rawptr(s),
// 		len = proc(it: Interface) -> int {
// 			s := (^T)(it.collection)
// 			return len(s^)
// 		},
// 		less = proc(it: Interface, i, j: int) -> bool {
// 			s := (^T)(it.collection)
// 			return s[i] < s[j]
// 		},
// 		swap = proc(it: Interface, i, j: int) {
// 			s := (^T)(it.collection)
// 			s[i], s[j] = s[j], s[i]
// 		},
// 	}
// }

ran :: proc(arr: []Data($T)) {
	for &a,i in arr {
		a.rand = cast(T)(len(arr) / 2 - rand.int_max(len(arr)))
		a.junk[0] = i
		a.index = i
	}
}


modu :: proc(arr: []Data($T)) {
	for &a,i in arr {
		a.rand = cast(T)(rand.int_max(len(arr)) % 10)
		a.junk[0] = i
		a.index = i
	}
}

