package msort

import "core:time"
import "core:math/rand"
import "core:slice"
import "base:intrinsics"
import "core:fmt"


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

		slice.sort_by(arr1, proc(l, r: Test)->bool{return l[0] < r[0]} )

		// ind2, end2 := sort.sort_inlined_by_with_indices2(arr1, proc(l, r: Test)->bool{return l[0] < r[0]})
		ind := slice.sort_by_with_indices(arr2, proc(l, r: Test)->bool{return l[0] < r[0]})
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




main :: proc() {
	for i :i64= 100; i <= 1_0_000; i += 10 {
		test_indices2(i)
	}
}

// main :: proc() {


// 	arr := make([]f32, 100)

// 	slice.sort(arr)
// 	fmt.println(arr[:1])



// 	fmt.println()
// 	fmt.println("test_highly_ordered(100_000 int)")
// 	test_highly_ordered()

// 	fmt.println()
// 	fmt.println("test_many_similar(100_000 int)")
// 	test_many_similar()


// 	fmt.println()
// 	fmt.println("test_random(100_000 int)")
// 	test_random_100_000()

// 	fmt.println()
// 	fmt.println("test_slice_with_data_indecies_100_000")
// 	test_slice_with_data_indecies_100_000()

// 	fmt.println()
// 	fmt.println("slice.big(100_00 1600 byte )")
// 	test_slice_big_100_00()

// 	fmt.println()
// 	fmt.println("sort_with_indecies(int)")
// 	for i :i64= 10; i <= 1_00_000; i *= 10 {
// 		test_indices(i)
// 	}
// 	fmt.println()
// 	fmt.println("sort_by_with_indecies([10]int)")
// 	for i :i64= 10; i <= 1_00_000; i *= 10 {
// 		test_indices_by(i)
// 	}


// }



test_inplace_big:: proc($size: int) {
	Big :: struct {
		data: [size]int,
		ind: int,
	}
	SIZE :: 100_00

	min1 := time.MAX_DURATION
	for _ in 0..<100 {
		arr1 := make([]Big,SIZE)

		for i in 0..<len(arr1) {
			// arr1[i] = i
			arr1[i].ind = rand.int_max(SIZE)
		}


		defer {
			delete(arr1)
		}

		sum  := 0
		for a in arr1 {
			sum += a.ind
		}

		
		start := time.tick_now()

		slice.sort(arr1)
		end1 := time.tick_since(start)


		min1 = min(min1, end1)

		

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
	fmt.println("size",size," ","_smoothsort: ",min1)


}

test_highly_ordered :: proc() {
	// iter := 2

	SIZE :: 100_000

	min1 := time.MAX_DURATION
	for _ in 0..<100 {
		arr1 := make([]int,SIZE)

		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(SIZE) %% 10 + i

		}

		defer {
			delete(arr1)
		}

		sum  := 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()

		slice.sort(arr1)
		end1 := time.tick_since(start)


		min1 = min(min1, end1)

		

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
	fmt.println("size",100_000,"  ","_smoothsort: ",min1)


}


test_many_similar :: proc() {
	// iter := 2

	SIZE :: 100_000

	min1 := time.MAX_DURATION
	for _ in 0..<100 {
		arr1 := make([]int,SIZE)

		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(SIZE) %% 10

		}

		defer {
			delete(arr1)
		}

		sum  := 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()

		slice.sort(arr1)
		end1 := time.tick_since(start)


		min1 = min(min1, end1)

		

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
	fmt.println("size",100_000,"  ","_smoothsort: ",min1)


}


test_random_100_000 :: proc() {
	// iter := 2

	SIZE :: 100_000

	min1 := time.MAX_DURATION
	for _ in 0..<100 {
		arr1 := make([]int,SIZE)

		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(SIZE)
		}

		defer {
			delete(arr1)
		}

		sum  := 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()

		slice.sort(arr1)
		end1 := time.tick_since(start)


		min1 = min(min1, end1)

		

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
	fmt.println("size",100_000,"  ","_smoothsort: ",min1)


}

test_slice_with_data_indecies_100_000 :: proc() {

	data := []int{6,0,4,2,8,9,7,1,3,5}

	SIZE :: 100_000

	min1 := time.MAX_DURATION
	for _ in 0..<10 {
		arr1 := make([]int,SIZE)

		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(SIZE)
		}

		defer {
			delete(arr1)
		}

		sum  := 0
		for a in arr1 {
			sum += a
		}

		
		start := time.tick_now()

		slice.sort_by_with_indices_with_data(arr1, proc(l, r: int, user_data: rawptr)->bool{
			data := cast(^[]int)(user_data)
			return data[l %% 10] < data[r %% 10]
		}, &data)
		end1 := time.tick_since(start)


		min1 = min(min1, end1)

		

		for a in arr1 {
			sum -= a
		}

		if sum != 0 {
			fmt.println(arr1)
			panic("sum not right")
		}

		
	}
	fmt.println("size",100_000,"  ","_smoothsort: ",min1)


}

test_slice_big_100_00 :: proc() {
	// iter := 2

	SIZE :: 100_00

	Data :: struct {
		rand: int,
		weight: [100]int,
	}
	data10_less :: proc(l, r: Data)->bool{return l.rand < r.rand}

	min1 := time.MAX_DURATION
	for _ in 0..<100 {
		arr1 := make([]Data,SIZE)

		for i in 0..<len(arr1) {
			arr1[i].rand = rand.int_max(SIZE)
		}

		defer {
			delete(arr1)
		}

		sum  := 0
		for a in arr1 {
			sum += a.rand
		}

		
		start := time.tick_now()

		slice.sort_by(arr1, data10_less)
		end1 := time.tick_since(start)


		min1 = min(min1, end1)

		

		for a in arr1 {
			sum -= a.rand
		}

		if sum != 0 {
			fmt.println(arr1)
			panic("sum not right")
		}


		if !slice.is_sorted_by(arr1, data10_less) {
			fmt.println(arr1)
			fmt.println(len(arr1))
			
			panic("not sorted1")
		}
		
	}
	fmt.println("size",100_000,"  ","_smoothsort: ",min1)


}



test_sort_qsort :: proc(size: i64) {
	min1 := max(i64)
	// iter := 2
	iter := clamp(1_000_000 / size, 4, 10_000)

	for _ in 0..<iter {
		arr1 := make([]int,size)
		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(int(size))
		}

		defer {
			delete(arr1)
		}

		start := intrinsics.read_cycle_counter()
		slice.sort(arr1)
		end1 := intrinsics.read_cycle_counter() - start



		min1 = min(min1, end1)

		if !slice.is_sorted(arr1) {
			fmt.println(arr1)
			panic("not sorted1")
		}
	}

	sizelg := size

	fmt.println("iter",iter,"size",size," in cycles / item ","sort: ",min1 / sizelg, )
}

test_indices :: proc(size: i64) {
	Test :: int
	min2 := max(i64)
	// iter := 2
	iter := clamp(1_000_000 / size, 4, 10_000)

	for _ in 0..<iter {
		arr1 := make([]Test,size)
		for i in 0..<len(arr1) {
			arr1[i] = rand.int_max(int(size))
		}

		defer {
			delete(arr1)
		}


		start2 := intrinsics.read_cycle_counter()
		slice.sort_with_indices(arr1)
		end2 := intrinsics.read_cycle_counter() - start2

		min2 = min(min2, end2)

		if !slice.is_sorted(arr1) {
			panic("not sorted1")
		}
	}

	sizelg := size

	fmt.println("iter",iter,"size",size," in cycles / item ","slice.sort: ",min2 / sizelg)
}

less10 ::  proc(l,r:[10]int)->bool{return l[0] < r[0]}
test_indices_by :: proc(size: i64) {
	Test :: [10]int
	min2 := max(i64)
	// iter := 2
	iter := clamp(1_000_000 / size, 4, 10_000)

	for _ in 0..<iter {
		arr1 := make([]Test,size)
		for i in 0..<len(arr1) {
			arr1[i][0] = rand.int_max(int(size))
		}

		defer {
			delete(arr1)
		}


		start2 := intrinsics.read_cycle_counter()
		slice.sort_by_with_indices(arr1, less10)
		end2 := intrinsics.read_cycle_counter() - start2

		min2 = min(min2, end2)

		if !slice.is_sorted_by(arr1,less10) {
			panic("not sorted1")
		}
	}

	sizelg := size

	fmt.println("iter",iter,"size",size," in cycles / item ","slice.sort: ",min2 / sizelg)
}