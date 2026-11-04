package sorting

import "core:fmt"
import "core:testing"


@test
test_sort :: proc(t: ^testing.T){
	{
		arr = random_int(10_000)
		defer delete(arr)

		quick_sort_ll(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "quicksort ll sort not sorted")
	}
	{
		arr = random_int(10_000)
		defer delete(arr)

		quick_sort_lr(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "quicksort lr sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		insertion_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "insertion sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		selection_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "selection_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		selection_double(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "selection_double not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		selection_optimized_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "selection_optimized_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		heap_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "heap_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		bubble_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "bubble_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		odd_even(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "odd_even not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		shell_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "shell_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		comb_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "comb_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		circle_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "circle_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)
		aux = make([]int, 1_000)
		defer delete(aux)

		pipo_sort(arr, aux)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "pipo_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		cycle_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "cycle_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		merge_rotate(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "merge_rotate not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		insertion_sort_binary(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "insertion_sort_binary not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		sort_inlined(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "sort_inlined not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		poplar_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "poplar_sort not sorted")
	}
	{
		arr = random_int(1_000)
		defer delete(arr)

		smooth_sort(arr)
		
		sorted := is_sorted_int(arr)
		testing.expect(t, sorted, "smooth_sort not sorted")
	}
	{
		swap := make([]int, 20)
		arr = make([]int, 20)
		for &a,i in arr {
			a = i % 10 + i
		}
		defer delete(arr)
		defer delete(swap)

		merge_cross(swap, arr, 10, 10)
		
		sorted := is_sorted_int(swap)
		testing.expect(t, sorted, "merge_cross not sorted")
	}
}