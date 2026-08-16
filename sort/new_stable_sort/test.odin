package rotate_merge

import "core:testing"
import "core:slice"
import "core:math/rand"
import "core:fmt"
import "base:intrinsics"

main :: proc(){
    for u: uint = 10; u <= 1_00_000; u *= 10 {
        test_16_byte(u)
    }
    for u: uint = 10; u <= 1_00_000; u *= 10 {
        test_160_byte(u)
    }
    for u: uint = 10; u <= 10_000; u *= 10 {
        test_old_stable(u)
    }

}
Data :: struct{
    rand: int,
    index: int,
}
test_16_byte :: proc(size: uint) {
    iter := 1_00_000 / size
    iter = clamp(iter,2,10_000)
    mint := max(i64)
    mint2 := max(i64)
    arr := make([]Data, size)
    arr2  := make([]Data, size)
    defer delete(arr)
    defer delete(arr2)

    for i in 0..<iter {
        for &a, index in arr {
            a.rand = rand.int_max(int(size / 2))
            a.index = index
        }

        copy(arr2, arr)

        start := intrinsics.read_cycle_counter()
        slice.stable_sort_by(arr, proc(l,r:Data)->bool{return l.rand < r.rand})
        dur := intrinsics.read_cycle_counter() - start

        start2 := intrinsics.read_cycle_counter()
        slice.sort_by(arr2, proc(l,r: Data)->bool{return l.rand < r.rand})
        dur2 := intrinsics.read_cycle_counter() - start2

        mint = min(mint,dur)
        mint2 = min(mint2,dur2)

        for i in 1..<len(arr) {
            if arr[i-1].rand > arr[i].rand {
                panic("not sorted")
            }
            if arr[i-1].rand < arr[i].rand {
                continue
            }
            if arr[i-1].index > arr[i].index {
                panic("not stable")
            }
        }
    }

    fmt.println("iterations:",iter,
    "size:", size,
    "cycles / len(data)   new.stable_sort_by:",mint / i64(size),
     "slice.sort_by:",mint2 / i64(size),
      "   diff: ", mint2 / mint)
}

Data2 :: struct{
    junk: [10]int,
    rand: int,
    index: int,
}
test_160_byte :: proc(size: uint) {
    iter := 1_00_000 / size
    iter = clamp(iter,2,10_000)
    mint := max(i64)
    mint2 := max(i64)
    arr := make([]Data2, size)
    arr2  := make([]Data2, size)
    defer delete(arr)
    defer delete(arr2)

    for i in 0..<iter {
        for &a, index in arr {
            a.rand = rand.int_max(int(size / 2))
            a.index = index
        }

        copy(arr2, arr)

        start := intrinsics.read_cycle_counter()
        slice.stable_sort_by(arr, proc(l,r:Data2)->bool{return l.rand < r.rand})
        dur := intrinsics.read_cycle_counter() - start

        start2 := intrinsics.read_cycle_counter()
        slice.sort_by(arr2, proc(l,r: Data2)->bool{return l.rand < r.rand})
        dur2 := intrinsics.read_cycle_counter() - start2

        mint = min(mint,dur)
        mint2 = min(mint2,dur2)
        if !slice.is_sorted_by(arr, proc(l,r: Data2) -> bool {return l.rand < r.rand} ) {
            fmt.println(arr[:10])
            panic("not sorted")
        }
    }

    fmt.println("iterations:",iter,
    "size:", size,
    "cycles / len(data)   new.stable_sort_by:",mint / i64(size),
     "slice.sort_by:",mint2 / i64(size),
      "   diff: ", mint2 / mint)
}

test_old_stable :: proc(size: uint) {
    iter := 1_000 / size
    iter = clamp(iter,2,10_000)
    mint := max(i64)
    mint2 := max(i64)
    arr := make([]Data, size)
    arr2  := make([]Data, size)
    defer delete(arr)
    defer delete(arr2)

    for i in 0..<iter {
        for &a, index in arr {
            a.rand = rand.int_max(int(size / 2))
            a.index = index
        }

        copy(arr2, arr)

        start := intrinsics.read_cycle_counter()
        slice.stable_sort_by(arr, proc(l,r:Data)->bool{return l.rand < r.rand})
        dur := intrinsics.read_cycle_counter() - start

        start2 := intrinsics.read_cycle_counter()
        stable_sort_by(arr2, proc(l,r: Data)->bool{return l.rand < r.rand})
        dur2 := intrinsics.read_cycle_counter() - start2

        mint = min(mint,dur)
        mint2 = min(mint2,dur2)

        for i in 1..<len(arr) {
            if arr[i-1].rand > arr[i].rand {
                panic("not sorted")
            }
            if arr[i-1].rand < arr[i].rand {
                continue
            }
            if arr[i-1].index > arr[i].index {
                panic("not stable")
            }
        }
    }

    fmt.println("iterations:",iter,
    "size:", size,
    "cycles / len(data)   new.stable_sort_by:",mint / i64(size),
     "old.stable_sort_by:",mint2 / i64(size), 
     "   diff: ", mint2 / mint)
}


@test
test_sort_stability :: proc(t: ^testing.T) {
	// Test sizes are all prime.
	test_sizes :: []int{7, 13, 347, 1031, 10111, 100003}
    Data :: struct {
        rand: int,
        index: int,
    }

	for test_size in test_sizes {
		rand.reset(t.seed)

		vals  := make([]Data, test_size)
		defer {
			delete(vals)
		}

		// Set up test values
		for _, i in vals {
			vals[i].rand = rand.int_max(10)
			vals[i].index = i
		}

		// Sort
		slice.stable_sort_by(vals, proc(l, r: Data) -> bool {return l.rand < r.rand})

		// Verify sorted test values
		rand.reset(t.seed)

        sum := vals[0].index
        for i in 1..<len(vals) {
            sum += vals[i].index
            if vals[i-1].rand > vals[i].rand {
	            testing.expect(t, false, "Expected slice to be sorted")
            }
            if vals[i-1].rand < vals[i].rand {
                continue
            }
            if vals[i-1].index > vals[i].index {
	            testing.expect(t, false, "Expected slice to be stable")
            }
        }

        testing.expect(t, sum == test_size * (test_size - 1) / 2, "Expected slice to have all indecies")

	}
}
ORD :: intrinsics.type_is_ordered
Sort_Kind :: enum {
	Ordered,
	Less,
	Cmp,
}
stable_sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			old_sort_general(data, less, .Less)
		}
	}
}

old_sort_general :: proc(data: $T/[]$E, call: $P, $KIND: Sort_Kind) where (ORD(E) && KIND == .Ordered) || (KIND != .Ordered) #no_bounds_check {
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
	
	// insertion sort
	// TODO(bill): use a different algorithm as insertion sort is O(n^2)
	n := len(data)
	for i in 1..<n {
		for j := i; j > 0 && less(data[j], data[j-1], call); j -= 1 {
			slice.swap(data, j, j-1)
		}
	}
}
