package merge

import "core:slice"
import "core:log"
import "core:fmt"
import "core:testing"


main :: proc(){
	test_simple()
}

// test_simple :: proc(t: ^testing.T) {
test_simple :: proc() {
	size :: 10
	arr := make_runs(size, 0.5)
	swap := make([]int, size)
	merge_cross4(swap, arr, 5, 5)
	if !slice.is_sorted(arr) {
		fmt.println(swap)
	}
	// testing.expect(t, slice.is_sorted(arr), "expected merging to sort")
}

// -------- test things ----------
size :: 10_000
ratio :: 0.6
// -------- test things ----------

@test
test_dumb :: proc(t: ^testing.T) {
	arr := make_runs(size, ratio)
	swap := make([]int, size)
	merge_dumb(swap, arr, size * ratio, size * (1-ratio))
	testing.expect(t, slice.is_sorted(swap), "expected merging to sort")
}
@test
test_parity :: proc(t: ^testing.T) {
	arr := make_runs(size, ratio)
	swap := make([]int, size)
	merge_parity(swap, arr, size * ratio, size * (1-ratio))
	testing.expect(t, slice.is_sorted(swap), "expected merging to sort")
}
@test
test_ternary :: proc(t: ^testing.T) {
	arr := make_runs(size, ratio)
	swap := make([]int, size)
	merge_branchless(swap, arr, size * ratio, size * (1-ratio))
	testing.expect(t, slice.is_sorted(swap), "expected merging to sort")
}
@test
test_cross :: proc(t: ^testing.T) {
	arr := make_runs(size, ratio)
	swap := make([]int, size)
	merge_cross(swap, arr, size * ratio, size * (1-ratio))
	testing.expect(t, slice.is_sorted(swap), "expected merging to sort")
}
@test
test_cross4 :: proc(t: ^testing.T) {
	arr := make_runs(size, ratio)
	swap := make([]int, size)
	merge_cross4(swap, arr, size * ratio, size * (1-ratio))
	testing.expect(t, slice.is_sorted(swap), "expected merging to sort")
}
@test
test_cross_loop2 :: proc(t: ^testing.T) {
	arr := make_runs(size, ratio)
	swap := make([]int, size)
	merge_cross_loop2(swap, arr, size * ratio, size * (1-ratio))
	testing.expect(t, slice.is_sorted(swap), "expected merging to sort")
}

@test
test_cross_loop4 :: proc(t: ^testing.T) {
	arr := make_runs(size, ratio)
	swap := make([]int, size)
	merge_cross_loop4(swap, arr, size * ratio, size * (1-ratio))
	testing.expect(t, slice.is_sorted(swap), "expected merging to sort")
}


make_runs :: proc(size: int, ratio: f32) -> (res: []int) {
	res = make([]int, size)
	part1 := int(f32(size) * ratio)
	for i in 0..<part1 {
		res[i] = i
	}
	for i, index in part1..<size {
		res[i] = index
	}
	return res
}