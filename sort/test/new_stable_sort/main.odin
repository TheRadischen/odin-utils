package unstable

import "base:builtin"
import "base:intrinsics"
import "core:slice"
import "core:math/rand"
import "core:time"
import "core:fmt"

ORD :: intrinsics.type_is_ordered
Ordering :: enum {
	Less    = -1,
	Equal   =  0,
	Greater = +1,
}

Generic_Cmp :: #type proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering

N :: #config(N, 1)
MOD :: #config(MOD, 1000000)
base : []int
main :: proc() {
	fmt.println("testing with data size:", size_of(Data(int)),", modulus:",MOD)
	
	for i := 10; i <= 1_000_000; i *= 10 {
		sort_sizes(i, int)
		// sort_sizes(i, i32)
		// sort_sizes(i, f64)
		sort_sizes(i, f32)
	}
}

Data :: struct($T: typeid) {
	rand: T,
	junk: [N]int,
}
comps: int
sort_sizes :: proc(size: int, $T: typeid) {
	arr := make([]Data(T), size)
	defer delete(arr)
	iter := 1_00_000 / size 
	min_time : time.Duration = time.MAX_DURATION
	min_time2 : time.Duration = time.MAX_DURATION
	smooth_cmp: int
	quick_cmp: int
	for i in 0..<clamp(iter, 1, 10_000) {
		ran(arr)
		start := time.tick_now()
		comps = 0
		slice.stable_sort_by(arr, proc(l,r: Data(T))->bool{
			comps += 1
			return l.rand < r.rand
		})
		quick_cmp = comps
		dur := time.tick_since(start)
		min_time = min(min_time, dur)
		if !slice.is_sorted_by(arr, proc(l,r: Data(T))->bool{
			return l.rand < r.rand
		}) {
			fmt.println(typeid_of(T), size)
			for a in arr {
				fmt.print(a.rand,",",sep="")
			}
			fmt.println()
			panic("not sorted, quick")
		}



		ran(arr)
		start = time.tick_now()
		comps = 0
		stable_sort_by(arr, proc(l,r: Data(T))->bool{
			comps += 1
			return l.rand < r.rand
		})
		dur = time.tick_since(start)
		min_time2 = min(min_time2, dur)
		if !slice.is_sorted_by(arr, proc(l,r: Data(T))->bool{
			return l.rand < r.rand
		}) {
			fmt.println(arr)
			panic("not sorted")
		}
		smooth_cmp = comps
	}
	fmt.println("type:", typeid_of(T), "size: ",size,"quick: time:", min_time,"comps:", quick_cmp, "  ||  smooth: time", min_time2,"comps:", smooth_cmp)
}
ran :: proc(arr: []Data($T)) {
	for &a,i in arr {
		a.rand = cast(T)(len(arr) / 2 - rand.int_max(len(arr)))
		a.junk[0] = i
	}
}


modu :: proc(arr: []Data($T)) {
	for &a,i in arr {
		a.rand = cast(T)(rand.int_max(len(arr)) % MOD)
		a.junk[0] = i
	}
}
Sort_Kind :: enum {
	Ordered,
	Less,
	Cmp,
}

stable_sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_stable_sort_general(data, less, .Less)
		}
	}
}


_stable_sort_general :: proc(data: $T/[]$E, call: $P, $KIND: Sort_Kind) where (ORD(E) && KIND == .Ordered) || (KIND != .Ordered) #no_bounds_check {
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

	merge_rotate(data, call)

	insertion_sort :: proc(data: T, call: P) {
		for i in 1..<len(data) {
			j := i
			temp := data[j]
			for ; j > 0 && less(temp, data[j - 1], call); j -= 1 {
				data[j] = data[j - 1]
			}
			data[j] = temp
		}
	}

	merge_rotate :: proc(data: T, call: P) {
		if len(data) <= 200 {
			insertion_sort(data, call)
			return
		}

		mid := len(data) / 2
		merge_rotate(data[:mid], call)
		merge_rotate(data[mid:], call)

		merge(data, mid, len(data) - mid, call)
	}

	bin_search_left :: proc(data: T, value: E, call: P) -> (from: int) {
		n := len(data)

		for n > 0 {
			half := n / 2
			mid := from + half

			if less(data[mid], value, call) {
				from = mid + 1
				n -= half + 1
			} else {
				n = half
			}
		}

		return from
	}

	bin_search_right :: proc(data: T, value: E, call: P) -> (from: int) {
		n := len(data)

		for n > 0 {
			half := n / 2
			mid := from + half

			if less(value, data[mid], call) {
				n = half
			} else {
				from = mid + 1
				n -= half + 1
			}
		}

		return from
	}

	merge :: proc(data: T, left, right: int, call: P) {
		if left == 0 || right == 0 {
			return
		}

		if left + right == 2 {
			if less(data[1], data[0], call) {
				data[1], data[0] = data[0], data[1]
			}
			return
		} 

		first_cut, second_cut: int
		left2, right2: int

		if left > right {
			left2 = left / 2
			first_cut = left2

			second_cut = left + bin_search_left(data[left:], data[first_cut], call)
			right2 = second_cut - left
		} else {
			right2 = right / 2
			second_cut = left + right2

			first_cut = bin_search_right(data[:left], data[second_cut], call)
			left2 = first_cut
		}

		slice.rotate_left(data[first_cut:second_cut], left - first_cut)
		new_mid := first_cut + right2

		merge(data[:new_mid], left2       , right2        , call)
		merge(data[new_mid:], left - left2, right - right2, call)
	}
}