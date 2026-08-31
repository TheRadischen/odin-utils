package msort

import "core:sort"
import "core:time"
import "core:math/rand"
import "core:slice"
import "base:intrinsics"
import "core:fmt"



// main :: proc() {

// 	arr := []int{0,1,6,5,7,4,2,3}
// 	arr2 := []int{0,1,6,5,7,4,2,3}
	
// 	// ind := slice.sort_with_indices(arr)
// 	ind := sort.sort_inlined_with_indices(arr)
// 	sort.sort_from_permutation_indices2(arr2, ind)

// 	fmt.println(ind)
// 	fmt.println(arr)
// 	fmt.println(arr2)

// }

test_indices2 :: proc(size: i64) {
	arr_size :: 1
	t_type :: i32
	Test :: [arr_size]t_type
	// min1 := time.MAX_DURATION
	// min2 := time.MAX_DURATION
	// iter := 2
	iter := clamp(1_000_000 / size, 4, 10_000)
	// iter = 10

	times1 := make([]time.Duration, iter)
	times2 := make([]time.Duration, iter)

	arr1 := make([]Test,size)
	arr2 := make([]Test,size)

	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<iter {
		for i in 0..<len(arr1) {
			for a in 0..<arr_size {
				arr1[i][a] = cast(t_type) rand.int_max(int(size))
				arr2[i][a] = cast(t_type) rand.int_max(int(size))

			}
		}

		sort.sort_inlined_by(arr1, proc(l, r: Test)->bool{return l[0] < r[0]} )

		// ind2, end2 := sort.sort_inlined_by_with_indices2(arr1, proc(l, r: Test)->bool{return l[0] < r[0]})
		ind := sort.sort_inlined_by_with_indices(arr2, proc(l, r: Test)->bool{return l[0] < r[0]})
		// ind := slice.sort_by_with_indices(arr2, proc(l, r: Test)->bool{return l[0] < r[0]})
		defer delete(ind)


		// min1 = min(min1, end1)
		// // min2 = min(min2, end2)
		// times1[j] = end1
		// times2[j] = end2

		// if !slice.is_sorted(arr1) {
		// 	panic("not sorted1")
		// }
	}

 

	fmt.println("size",size," ","old: ",times1[iter / 3] ,"new: ",times2[iter / 3] ,"    diff:   ", f64(times1[iter / 3]) / f64(times2[iter / 3]))
}




// main :: proc() {
// 	for i :i64= 100; i <= 1_0_000; i += 10 {
// 		test_indices2(i)
// 	}
// }

main :: proc() {
	for i :i64= 10; i <= 1_0_000; i *= 10 {
		test_indices2(i)
	}
	// {return}


	arr := make([]f32, 100)

	sort.sort_inlined(arr)

	slice.sort(arr)
	fmt.println(arr[:1])

	all_equal := make([]int, 10000)
	defer delete(all_equal)
	for &a in all_equal {
		a = 10
	}
	sort.sort_inlined(all_equal)
	if !slice.is_sorted(all_equal) {
		panic("all equal failed")
	}



	fmt.println()
	fmt.println("test_highly_ordered(100_000 int)")
	test_highly_ordered()


	fmt.println()
	fmt.println("test_ordered(100_000 int)")
	test_ordered()

	fmt.println()
	fmt.println("test_many_similar(100_000 int)")
	test_many_similar()


	fmt.println()
	fmt.println("test_random(100_000 int)")
	test_random_100_000()

	fmt.println()
	fmt.println("test_slice_with_data_indecies_100_000")
	test_slice_with_data_indecies_100_000()

	fmt.println()
	fmt.println("slice.big(100_00 1600 byte )")
	test_slice_big_100_00()

	fmt.println()
	fmt.println("sort_with_indecies(int)")
	for i :i64= 10; i <= 1_000_000; i *= 10 {
		test_indices(i)
	}
	fmt.println()
	fmt.println("sort_by_with_indecies([100]int)")
	for i :i64= 10; i <= 1_00_000; i *= 10 {
		test_indices_by(i)
	}
	fmt.println()
	fmt.println("test_random(int)")
	for i :i64= 10; i <= 1_000_000; i *= 10 {
		test_random(i)
	}


}


test_random_100_000 :: proc() {
	// iter := 2

	SIZE :: 1_00_000

	min1 := time.MAX_DURATION
	min2 := time.MAX_DURATION
	arr1 := make([]int,SIZE)
	arr2 := make([]int,SIZE)
	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<100 {

		for i in 0..<len(arr1) {
			arr1[i] = int(rand.int_max(SIZE))
		}
		copy(arr2, arr1)



		sum  :int= 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()
		sort.sort_inlined(arr1)
		end1 := time.tick_since(start)
		
		start2 := time.tick_now()
		slice.sort(arr2)
		end2 := time.tick_since(start2)

		min1 = min(min1, end1)
		min2 = min(min2, end2)
		

		for a in arr1 {
			sum -= a
		}

		if sum != 0 {
			fmt.println(arr1)
			panic("sum not right")
		}

		// if !slice.is_sorted(arr1) {
		// 	fmt.println(arr1)
		// 	fmt.println(len(arr1))
			
		// 	panic("not sorted1")
		// }
		
	}
	fmt.println("size",SIZE," ","inline_sort: ",min1,"_smoothsort: ",min2, f64(min2) / f64(min1))


}



test_inplace_big:: proc($size: int) {
	Big :: struct {
		data: [size]int,
		ind: int,
	}
	SIZE :: 100_00

	min1 := time.MAX_DURATION
	min2 := time.MAX_DURATION
	arr1 := make([]Big,SIZE)
	arr2 := make([]Big,SIZE)
	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<100 {

		for i in 0..<len(arr1) {
			arr1[i].ind = rand.int_max(SIZE)
		}
		copy(arr2, arr1)



		sum  := 0
		for a in arr1 {
			sum += a.ind
		}

		
		start := time.tick_now()
		sort.sort_inlined_by(arr1, proc(l,r: Big) -> bool{return l.ind < r.ind})
		end1 := time.tick_since(start)
		
		start2 := time.tick_now()
		slice.sort_by(arr2, proc(l,r: Big) -> bool{return l.ind < r.ind})
		end2 := time.tick_since(start2)


		min1 = min(min1, end1)
		min2 = min(min2, end2)

		

		for a in arr1 {
			sum -= a.ind
		}

		if sum != 0 {
			panic("sum not right")
		}


		if !slice.is_sorted_by(arr1, proc(l,r: Big) -> bool{return l.ind < r.ind}) {
			fmt.println(arr1)
			fmt.println(len(arr1))
			fmt.println(i)
			
			panic("not sorted1")
		}
		
	}
	fmt.println("size",size," ","inline_sort: ",min1,"_smoothsort: ",min2, f64(min2) / f64(min1))


}

test_highly_ordered :: proc() {
	// iter := 2

	SIZE :: 100_000

	min1 := time.MAX_DURATION
	min2 := time.MAX_DURATION
	arr1 := make([]int,SIZE)
	arr2 := make([]int,SIZE)
	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<100 {

		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(SIZE) %% 10 + i
		}
		copy(arr2, arr1)



		sum  := 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()
		sort.sort_inlined(arr1)
		end1 := time.tick_since(start)
		
		start2 := time.tick_now()
		slice.sort(arr2)
		end2 := time.tick_since(start2)

		min1 = min(min1, end1)
		min2 = min(min2, end2)
		

		for a in arr1 {
			sum -= a
		}

		if sum != 0 {
			fmt.println(arr1)
			panic("sum not right")
		}

		if !slice.is_sorted(arr1) {
			fmt.println(arr1)
			fmt.println(len(arr1))
			
			panic("not sorted1")
		}
		
	}
	fmt.println("size",SIZE," ","inline_sort: ",min1,"_smoothsort: ",min2, f64(min2) / f64(min1))


}


test_ordered :: proc() {
	// iter := 2

	SIZE :: 100_000

	min1 := time.MAX_DURATION
	min2 := time.MAX_DURATION
	arr1 := make([]int,SIZE)
	arr2 := make([]int,SIZE)
	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<100 {

		for i in 0..<len(arr1) {
			arr1[i] = i
		}
		copy(arr2, arr1)



		sum  := 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()
		sort.sort_inlined(arr1)
		end1 := time.tick_since(start)
		
		start2 := time.tick_now()
		slice.sort(arr2)
		end2 := time.tick_since(start2)

		min1 = min(min1, end1)
		min2 = min(min2, end2)
		

		for a in arr1 {
			sum -= a
		}

		if sum != 0 {
			fmt.println(arr1)
			panic("sum not right")
		}

		if !slice.is_sorted(arr1) {
			fmt.println(arr1)
			fmt.println(len(arr1))
			
			panic("not sorted1")
		}
		
	}
	fmt.println("size",SIZE," ","inline_sort: ",min1,"_smoothsort: ",min2, f64(min2) / f64(min1))


}


test_many_similar :: proc() {
	// iter := 2

	SIZE :: 100_000

	min1 := time.MAX_DURATION
	min2 := time.MAX_DURATION
	arr1 := make([]int,SIZE)
	arr2 := make([]int,SIZE)
	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<100 {

		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(SIZE) %% 10
		}
		copy(arr2, arr1)



		sum  := 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()
		sort.sort_inlined(arr1)
		end1 := time.tick_since(start)
		
		start2 := time.tick_now()
		slice.sort(arr2)
		end2 := time.tick_since(start2)

		min1 = min(min1, end1)
		min2 = min(min2, end2)
		

		for a in arr1 {
			sum -= a
		}

		if sum != 0 {
			fmt.println(arr1)
			panic("sum not right")
		}

		if !slice.is_sorted(arr1) {
			fmt.println(arr1)
			fmt.println(len(arr1))
			
			panic("not sorted1")
		}
		
	}
	fmt.println("size",SIZE," ","inline_sort: ",min1,"_smoothsort: ",min2, f64(min2) / f64(min1))


}


test_slice_with_data_indecies_100_000 :: proc() {

	data := []int{6,0,4,2,8,9,7,1,3,5}

	SIZE :: 100_000

	min1 := time.MAX_DURATION
	min2 := time.MAX_DURATION
	arr1 := make([]int,SIZE)
	arr2 := make([]int,SIZE)
	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<10 {

		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(SIZE)
		}
		copy(arr2, arr1)


		sum  := 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()
		sort.sort_inlined_by_with_indices_with_data(arr1, proc(l, r: int, data: ^[]int)->bool{
			return data[l %% 10] < data[r %% 10]
		}, &data)
		end1 := time.tick_since(start)


		start2 := time.tick_now()
		slice.sort_by_with_indices_with_data(arr2, proc(l, r: int, user_data: rawptr)->bool{
			data := (^[]int)(user_data)
			return data[l %% 10] < data[r %% 10]
		}, &data)
		end2 := time.tick_since(start2)


		min1 = min(min1, end1)
		min2 = min(min2, end2)

		

		for a in arr1 {
			sum -= a
		}

		if sum != 0 {
			fmt.println(arr1)
			panic("sum not right")
		}

		
	}
	fmt.println("size",SIZE," ","inline_sort: ",min1,"_smoothsort: ",min2, f64(min2) / f64(min1))



}

test_slice_big_100_00 :: proc() {
	// iter := 2

	SIZE :: 100_00

	Data :: struct {
		rand: int,
		weight: [100]int,
	}
	data_less :: proc(l, r: Data)->bool{return l.rand < r.rand}

	min1 := time.MAX_DURATION
	min2 := time.MAX_DURATION
	arr1 := make([]Data,SIZE)
	arr2 := make([]Data,SIZE)
	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<100 {

		for i in 0..<len(arr1) {
			arr1[i].rand = rand.int_max(SIZE)
		}
		copy(arr2, arr1)


		sum  := 0
		for a in arr1 {
			sum += a.rand
		}

		
		start := time.tick_now()
		sort.sort_inlined_by(arr1, data_less)
		end1 := time.tick_since(start)
		
		start2 := time.tick_now()
		slice.sort_by(arr2, data_less)
		end2 := time.tick_since(start2)


		min1 = min(min1, end1)
		min2 = min(min2, end2)

		

		for a in arr1 {
			sum -= a.rand
		}

		if sum != 0 {
			fmt.println(arr1)
			panic("sum not right")
		}


		if !slice.is_sorted_by(arr1, data_less) {
			fmt.println(arr1)
			fmt.println(len(arr1))
			
			panic("not sorted1")
		}
		
	}
	fmt.println("size",SIZE," ","inline_sort: ",min1,"_smoothsort: ",min2, f64(min2) / f64(min1))



}


test_indices :: proc(size: i64) {
	Test :: int
	min1 := max(i64)
	min2 := max(i64)
	// iter := 2
	iter := clamp(1_000_000 / size, 4, 10_000)

	arr1 := make([]Test,size)
	arr2 := make([]Test,size)

	defer {
		delete(arr1)
		delete(arr2)
	}
	for _ in 0..<iter {
		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(int(size))
		}
		copy(arr2, arr1)


		start1 := intrinsics.read_cycle_counter()
		sort.sort_inlined_with_indices(arr1)
		end1 := intrinsics.read_cycle_counter() - start1

		start2 := intrinsics.read_cycle_counter()
		slice.sort_with_indices(arr2)
		end2 := intrinsics.read_cycle_counter() - start2

		min1 = min(min1, end1)
		min2 = min(min2, end2)

		if !slice.is_sorted(arr1) {
			panic("not sorted1")
		}
	}

 

	fmt.println("size",size," ","inline_sort: ",min1 / size,"_smoothsort: ",min2 / size,"    diff:   ", f64(min2) / f64(min1))
}

less10 ::  proc(l,r:[100]int)->bool{return l[0] < r[0]}
test_indices_by :: proc(size: i64) {
	Test :: [100]int
	min1 := max(i64)
	min2 := max(i64)
	// iter := 2
	iter := clamp(1_000_000 / size, 4, 10_000)
	arr1 := make([]Test,size)
	arr2 := make([]Test,size)
	defer {
		delete(arr1)
		delete(arr2)
	}

	for _ in 0..<iter {
		for i in 0..<len(arr1) {
			arr1[i][0] = rand.int_max(int(size))
		}
		copy(arr2, arr1)



		start1 := intrinsics.read_cycle_counter()
		sort.sort_inlined_by_with_indices(arr1, less10)
		end1 := intrinsics.read_cycle_counter() - start1

		start2 := intrinsics.read_cycle_counter()
		slice.sort_by_with_indices(arr2, less10)
		end2 := intrinsics.read_cycle_counter() - start2

		min1 = min(min1, end1)
		min2 = min(min2, end2)

		if !slice.is_sorted_by(arr1,less10) {
			panic("not sorted1")
		}
	}

 

		fmt.println("size",size," ","inline_sort: ",min1 / size,"_smoothsort: ",min2 / size,"    diff:   ", f64(min2) / f64(min1))

}


test_random :: proc(size: i64) {
	// iter := 2
	iter := clamp(1_000_000 / size, 2, 10_000)
	min1 := make([]i64, iter)
	min2 := make([]i64, iter)
	arr1 := make([]int,size)
	arr2 := make([]int,size)
	defer {
		delete(arr1)
		delete(arr2)
	}

	for j in 0..<iter {
		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(int(size))
		}
		copy(arr2, arr1)



		start1 := intrinsics.read_cycle_counter()
		sort.sort_inlined(arr1)
		end1 := intrinsics.read_cycle_counter() - start1

		start2 := intrinsics.read_cycle_counter()
		slice.sort(arr2)
		end2 := intrinsics.read_cycle_counter() - start2

		min1[j] = end1
		min2[j] = end2

		if !slice.is_sorted(arr1) {
			panic("not sorted1")
		}
	}

 

	median1 := min1[iter / 2]
	median2 := min2[iter / 2]

	fmt.println("size",size," ","inline_sort: ",median1 / size,"_smoothsort: ",median2 / size,"    diff:   ", f64(median2) / f64(median1))

}