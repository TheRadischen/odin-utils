package msort

import "core:fmt"
import "base:intrinsics"


sort_thread :: proc(arr: $T/[]$E, allocator := context.allocator) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			base_type :: intrinsics.type_core_type(E)
			mini_thread(transmute([]base_type)arr, rawptr(nil), proc(l, r: base_type, data: rawptr) -> bool { return l < r }, allocator)
		}
	}
}



mini_thread :: proc(arr: $A/[]$T, data: $D, $LESS: $P, allocator := context.allocator) {
	if len(arr) <= 64 {
		insertion_sort(arr, data)
		return
	}
	// Task_Data :: struct {
	// 	arr: []int,
	// 	swap: []int,
	// 	cur: []int,
	// 	pivot: int,
	// 	less: int, // out
	// }
	swap := make(A, len(arr), allocator)
	// loop(arr, swap, arr, data, nil, true)
	stacked(arr, swap, arr, data)
	delete(swap, allocator)

	MAX_THREADS :: 8

	stacked :: proc(arr, swap, cur: A, data: D) {
		parts := 1
		stack : [MAX_THREADS][3]A
		stack[0] = {arr, swap, cur}
		for parts <= MAX_THREADS / 2 {

			// splits := 16 / parts

			for i := parts - 1; i >= 0; i -= 1 {

				arr, swap, cur := stack[i][0], stack[i][1], stack[i][2]

				fmt.println(parts,i,len(cur))
				
				depth := log2(len(cur)) / 5 
				pivot := med3(cur, data, depth)

				left := partition(arr, swap, cur, data, pivot)
				right := len(cur) - left

				stack[i*2+1] = {arr[left:], swap, swap[:right]}
				stack[i*2] = {arr[:left], swap, arr[:left]}

			}

			parts *= 2
		}
		sum := 0
		for s,i in stack {
			l := len(s[0])
			fmt.println(l)
			sum += l
		}
		fmt.println(sum)
		
		for i := parts - 1; i >= 0; i -= 1 {

			arr, swap, cur := stack[i][0], stack[i][1], stack[i][2]
			loop(arr, swap, cur, data, nil, true)

		}
	}


	loop :: proc(arr, swap, cur: A, data: D, last_piv: Maybe(T), leftmost: bool) #no_bounds_check {
		arr := arr; cur := cur; last_piv := last_piv; leftmost := leftmost
		for {
			if len(arr) <= 48 {
				if raw_data(arr) != raw_data(cur) {
					intrinsics.mem_copy_non_overlapping(raw_data(arr), raw_data(cur), len(cur) * size_of(T))
				}

				if leftmost {
					insertion_sort(arr, data)
				} else {
					insertion_sort_unguarded(arr, data)
				}
				return
			}

			depth := log2(len(arr)) / 5 
			pivot := med3(cur, data, depth)

			if pivot == last_piv {
				left := partition_reverse(arr, swap, cur, data, pivot)
				right := len(arr) - left
				arr = arr[left:]
				cur = swap[:right]
				last_piv = nil
				leftmost = false
				continue
			}

			left := partition(arr, swap, cur, data, pivot)
			// left := partition_parity(arr, swap, cur, data, pivot)
			// left := partition_parity4(arr, swap, cur, data, pivot)
			// left := partition_parity4_timing(arr, swap, cur, data, pivot)
			// left := partition_parity4_copy(arr, swap, cur, data, pivot)
			right := len(arr) - left

			loop(arr[left:], swap, swap[:right], data, pivot, false)
			arr = arr[:left]
			cur = arr[:left]
			last_piv = nil
			leftmost = leftmost
		}
	}

	log2 :: proc(n: int) -> (log: int) {
		n := n
		for ; n > 0 ;n >>= 1 {
			log += 1
		}
		return log
	}

	med3 :: proc(arr: A, data: D, depth: int) -> T #no_bounds_check {
		if depth == 0 {
			return arr[0]
		}

		div := len(arr) / 3

		swap := [3]T{
			med3(arr[:div], data, depth - 1), 
			med3(arr[div:][:div], data, depth - 1), 
			med3(arr[div * 2:], data, depth - 1)
		}
		
		x := LESS(swap[0], swap[1], data)
		y := LESS(swap[0], swap[2], data)
		z := LESS(swap[1], swap[2], data)

		return swap[(int)(x == y) + (int)(y ~ z)]
	}

	insertion_sort :: proc(arr: A, data: D) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	insertion_sort_unguarded :: proc(arr: A, data: D) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	partition :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
		less := 0

		#unroll(8) for a,i in cur {
			x := cast(int)LESS(a, piv, data)
			arr[less] = a
			swap[i - less] = a
			less += x
		}
		
		return less
	}

	partition_reverse :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
		less_equal := 0

		#unroll(8) for a,i in cur {
			x := cast(int)!LESS(piv, a, data)
			arr[less_equal] = a
			swap[i - less_equal] = a
			less_equal += x
		}
		
		return less_equal
	}

	partition_parity :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
		n := len(cur)
		half := n / 2
		half2 := n - half

		less1 := 0; less2 := 0
		a1 := arr[:half]; a2 := arr[half:][:half2]
		s1 := swap[:half]; s2 := swap[half:][:half2]
		c1 := cur[:half]; c2 := cur[half:][:half2]

		#unroll(8) for a,i in a1 {
			x := cast(int)LESS(c1[i], piv, data)
			a1[less1] = c1[i]
			s1[i - less1] = c1[i]
			less1 += x

			y := cast(int)LESS(c2[i], piv, data)
			a2[less2] = c2[i]
			s2[i - less2] = c2[i]
			less2 += y
		}

		if half != half2 {
			y := cast(int)LESS(c2[half], piv, data)
			a2[less2] = c2[half]
			s2[half - less2] = c2[half]
			less2 += y
		}

		intrinsics.mem_copy_non_overlapping(&arr[less1], &a2[0], less2 * size_of(T))
		intrinsics.mem_copy_non_overlapping(&swap[half - less1], &s2[0], ((n-half) - less2) * size_of(T))

		return less1 + less2
	}


	partition_parity4 :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
		n := len(cur)
		quart := n / 4

		less1 := 0; less2 := 0; less3 := 0; less4 := 0; 

		a1 := arr;  a2 := arr[quart:];  a3 := arr[quart * 2:];  a4 := arr[quart * 3:]
		s1 := swap; s2 := swap[quart:]; s3 := swap[quart * 2:]; s4 := swap[quart * 3:]
		c1 := cur;  c2 := cur[quart:];  c3 := cur[quart * 2:];  c4 := cur[quart * 3:]


		for i in 0..<quart {
			x := cast(int)LESS(c1[i], piv, data)
			a1[less1] = c1[i]
			s1[i - less1] = c1[i]
			less1 += x

			y := cast(int)LESS(c2[i], piv, data)
			a2[less2] = c2[i]
			s2[i - less2] = c2[i]
			less2 += y

			z := cast(int)LESS(c3[i], piv, data)
			a3[less3] = c3[i]
			s3[i - less3] = c3[i]
			less3 += z

			w := cast(int)LESS(c4[i], piv, data)
			a4[less4] = c4[i]
			s4[i - less4] = c4[i]
			less4 += w
		}

		c4 = c4[quart:]
		for i in 0..<(n %% 4) {
			w := cast(int)LESS(c4[i], piv, data)
			a4[less4] = c4[i]
			s4[quart + i - less4] = c4[i]
			less4 += w
		}



		less := less1
		copy(arr[less:], a2[:less2])
		less += less2
		copy(arr[less:], a3[:less3])
		less += less3
		copy(arr[less:], a4[:less4])
		less += less4

		greater := quart - less1
		copy(swap[greater:], s2[:quart - less2])
		greater += quart - less2
		copy(swap[greater:], s3[:quart - less3])
		greater += quart - less3
		copy(swap[greater:], s4[:quart + n %% 4 - less4])

		return less
	}


	partition_parity4_timing :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
		n := len(cur)
		quart := n / 4

		less1 := 0; less2 := 0; less3 := 0; less4 := 0; 
		// i1 := 0; i2 := half

		a1 := arr[:quart];  a2 := arr[quart:];  a3 := arr[quart * 2:];  a4 := arr[quart * 3:]
		s1 := swap; s2 := swap[quart:]; s3 := swap[quart * 2:]; s4 := swap[quart * 3:]
		c1 := cur;  c2 := cur[quart:];  c3 := cur[quart * 2:];  c4 := cur[quart * 3:]

		// fmt.println("cur")
		// fmt.println(cur)
		for i in 0..<quart {
			x := cast(int)LESS(c1[i], piv, data)
			a1[less1] = c1[i]
			s1[i - less1] = c1[i]
			less1 += x

			y := cast(int)LESS(c2[i], piv, data)
			a2[less2] = c2[i]
			s2[i - less2] = c2[i]
			less2 += y

			z := cast(int)LESS(c3[i], piv, data)
			a3[less3] = c3[i]
			s3[i - less3] = c3[i]
			less3 += z

			w := cast(int)LESS(c4[i], piv, data)
			a4[less4] = c4[i]
			s4[i - less4] = c4[i]
			less4 += w
		}

		// fmt.println("arrr, swap")
		// fmt.println(arr)
		// fmt.println(swap)
		c4 = c4[quart:]
		for i in 0..<(n %% 4) {
			w := cast(int)LESS(c4[i], piv, data)
			a4[less4] = c4[i]
			s4[quart + i - less4] = c4[i]
			less4 += w
		}

		start0 := intrinsics.read_cycle_counter()
		start := intrinsics.read_cycle_counter()

		less := less1
		copy(arr[less:], a2[:less2])
		copy_duration1 += intrinsics.read_cycle_counter() - start
		start = intrinsics.read_cycle_counter()
		less += less2
		copy(arr[less:], a3[:less3])
		copy_duration2 += intrinsics.read_cycle_counter() - start
		start = intrinsics.read_cycle_counter()
		less += less3
		copy(arr[less:], a4[:less4])
		copy_duration3 += intrinsics.read_cycle_counter() - start
		start = intrinsics.read_cycle_counter()
		less += less4

		greater := quart - less1
		copy(swap[greater:], s2[:quart - less2])
		copy_duration11 += intrinsics.read_cycle_counter() - start
		start = intrinsics.read_cycle_counter()
		greater += quart - less2
		copy(swap[greater:], s3[:quart - less3])
		copy_duration22 += intrinsics.read_cycle_counter() - start
		start = intrinsics.read_cycle_counter()
		greater += quart - less3
		// len4 := quart + n %% 4
		len4 := len(s4)
		fmt.println(len4, quart + n %% 4)
		// copy(swap[greater:], s4[:quart + n %% 4 - less4])
		// copy(swap[greater:], s4[:len(s4) - less4])
		copy(swap[greater:], s4[:len4])
		copy_duration33 += intrinsics.read_cycle_counter() - start
		start = intrinsics.read_cycle_counter()

		
		copy_duration += intrinsics.read_cycle_counter() - start0
		// fmt.println("arrr, swap, after copy")
		// fmt.println(arr)
		// fmt.println(swap)
		return less
	}

	partition_parity4_copy :: proc(arr, swap, cur: A, data: D, piv: T) -> int #no_bounds_check {
		n := len(cur)
		quart := n / 4

		less1 := 0; less2 := 0; less3 := 0; less4 := 0; 
		// i1 := 0; i2 := half

		a1 := arr;  a2 := arr[quart:];  a3 := arr[quart * 2:];  a4 := arr[quart * 3:]
		s1 := swap; s2 := swap[quart:]; s3 := swap[quart * 2:]; s4 := swap[quart * 3:]
		c1 := cur;  c2 := cur[quart:];  c3 := cur[quart * 2:];  c4 := cur[quart * 3:]

		// fmt.println("cur")
		// fmt.println(cur)
		for i in 0..<quart {
			x := cast(int)LESS(c1[i], piv, data)
			a1[less1] = c1[i]
			s1[i - less1] = c1[i]
			less1 += x

			y := cast(int)LESS(c2[i], piv, data)
			a2[less2] = c2[i]
			s2[i - less2] = c2[i]
			less2 += y

			z := cast(int)LESS(c3[i], piv, data)
			a3[less3] = c3[i]
			s3[i - less3] = c3[i]
			less3 += z

			w := cast(int)LESS(c4[i], piv, data)
			a4[less4] = c4[i]
			s4[i - less4] = c4[i]
			less4 += w
		}

		// fmt.println("arrr, swap")
		// fmt.println(arr)
		// fmt.println(swap)
		c4 = c4[quart:]
		for i in 0..<(n %% 4) {
			w := cast(int)LESS(c4[i], piv, data)
			a4[less4] = c4[i]
			s4[quart + i - less4] = c4[i]
			less4 += w
		}

		b4_copy := intrinsics.read_cycle_counter()

		less := less1
		intrinsics.mem_copy_non_overlapping(&arr[less], &a2[0], less2 * size_of(T))
		less += less2
		intrinsics.mem_copy_non_overlapping(&arr[less], &a3[0], less3 * size_of(T))
		less += less3
		intrinsics.mem_copy_non_overlapping(&arr[less], &a4[0], less4 * size_of(T))
		less += less4

		greater := quart - less1
		intrinsics.mem_copy_non_overlapping(&swap[greater], &s2[0], (quart - less2) * size_of(T))
		greater += quart - less2
		intrinsics.mem_copy_non_overlapping(&swap[greater], &s3[0], (quart - less3) * size_of(T))
		greater += quart - less3
		intrinsics.mem_copy_non_overlapping(&swap[greater], &s4[0], (len(s4) - less4) * size_of(T))
		// greater += len(s4) - less4
		
		dur_copy := intrinsics.read_cycle_counter() - b4_copy
		copy_duration += dur_copy
		// fmt.println("arrr, swap, after copy")
		// fmt.println(arr)
		// fmt.println(swap)
		return less
	}
}

