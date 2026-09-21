// #+ignore
package ermsort

import "core:slice"
import "core:time"
import "core:sync"
import "core:math"
import "core:thread"
import "core:fmt"
import "base:intrinsics"


sort_parallel :: proc(arr: $T/[]$E, thread_num: int, allocator := context.allocator) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			base_type :: intrinsics.type_core_type(E)
			mini_thread(transmute([]base_type)arr, rawptr(nil), proc(l, r: base_type, data: rawptr) -> bool { return l < r },
			thread_num, allocator)
		}
	}
}



	lastt : time.Tick
mini_thread :: proc(arr: $A/[]$T, data: $D, $LESS: $P, thread_num: int, allocator := context.allocator) {
	if len(arr) <= 64 {
		insertion_sort(arr, data)
		return
	} else if len(arr) <= 100_000 {
		swap := make(A, len(arr), allocator)
		loop(arr, swap, arr, data, nil, true)
		// stacked(arr, swap, data, thread_num)
		delete(swap, allocator)
		return
		// non threaded
	}

	Task_Data :: struct {
		from: [2]A,
		// from2: []int,
		to: A,
		data: D,
		less: int, // out
		pivot: T,
	}
	Job_Data :: struct {
		blocks: []Task_Data, // arr[block,block]
		job_idx: []int, // [longest, shortest]
		job_nums: int,
		remaining: int,
		mutex: sync.Mutex,
		cond: sync.Cond,
		finish_cond: sync.Cond,
		shutdown: bool,
		final: bool,
	}
	swap := make(A, len(arr), allocator)
	// loop(arr, swap, arr, data, nil, true)
	stacked(arr, swap, data, thread_num)

	// fmt.println("last",time.tick_since(lastt))
	delete(swap, allocator)

	stacked :: proc(arr, swap: A, data: D, thread_num: int) {
		from := arr
		to := swap
		block_num := math.next_power_of_two(thread_num) * 1

		blocks := make([]Task_Data, block_num * 2) // *2 for final iteration
		defer delete(blocks)

		job_num := block_num
		idx := make([]int, block_num * 2)
		defer delete(idx)
		for &j, i in idx {j = i}

		jobs : Job_Data = {
			blocks,
			idx,
			block_num,
			block_num,
			{},
			{},
			{},
			false,
			false
		}

		// what do i need to keep track of?



		dummy : A = {}
		// // // // fmt.println( "threads:",thread_num,"blocks:",block_num)
		// first pass

		t0 := time.tick_now()

		depth := log2(len(arr)) / 8
		pivot := med3(arr, data, depth)

		// // fmt.println("med0",time.tick_since(t0))

		block_size := len(arr) / block_num + 1
		start := 0
		end := block_size

		for i in 0..<block_num {
			// // // // fmt.print(start, "")
			blocks[i] = Task_Data{
				{from[start:end], dummy},
				to[start:end],
				data,
				0,
				pivot
			}
			start = end
			end = min(end + block_size, len(arr))
		}

		t1 := time.tick_now()
		threads := make([]^thread.Thread, thread_num)
		for &t, i in threads {
			t = thread.create(thread_land, .High)
			t.data = &jobs
			thread.start(t)
		}
		// // fmt.println("starting threads",time.tick_since(t1))
		t2 := time.tick_now()

		defer {
			for &t in threads {
				thread.destroy(t)
			}
			delete(threads)
		}


		
		block_length := 1
		block_num /= 2
		for block_num > 0 {
			// // // // fmt.println()
			// // // // fmt.println("processing:", block_num, block_length)

			sync.mutex_lock(&jobs.mutex)

			
			// // fmt.println("block_length",block_length,time.tick_since(t2))
			t2 = time.tick_now()

			for jobs.remaining > 0 {
				sync.cond_wait(&jobs.finish_cond, &jobs.mutex)
			}
			// sync.mutex_unlock(&jobs.mutex)
			
			from, to = to, from

			block_idx := 0
			for i in 0..<block_length {
				for lh in 0..<2 {
					start := time.tick_now()
					sample_block := blocks[i * 2 * block_num]
					sample := sample_block.to[:sample_block.less] if lh == 0 else sample_block.to[sample_block.less:]
					pivot := med3(sample, data, 3)
					start = time.tick_now()
					for j in 0..<block_num {
						f1_idx := j * 2 + i * 2 * block_num
						f2_idx := f1_idx + 1
						block1 := blocks[f1_idx]
						block2 := blocks[f2_idx]
						from1 := block1.to[:block1.less] if lh == 0 else block1.to[block1.less:]
						from2 := block2.to[:block2.less] if lh == 0 else block2.to[block2.less:]
						blocks[block_idx].from = {from1, from2}
						blocks[block_idx].pivot = pivot
						block_idx += 1
					}
				}
			}
			start := 0
			for &b in blocks {
				end := start + len(b.from[0]) + len(b.from[1])
				b.to = to[start : end]
				b.less = 0
				start = end
			}

			// slice.sort_by_with_data(idx[:len(blocks) / 2],proc(l,r:int,user_data:rawptr)->bool{
			// 	blocks := (^[]Task_Data)(user_data)
			// 	return len(blocks[l].to) < len(blocks[r].to)
			// },&blocks)

			jobs.remaining = len(blocks) / 2
			jobs.job_nums = len(blocks) / 2
			sync.mutex_unlock(&jobs.mutex)
			// send signal
			sync.cond_broadcast(&jobs.cond)
			block_length *= 2
			block_num /= 2
		}

		sync.mutex_lock(&jobs.mutex)

		for jobs.remaining > 0 {
			sync.cond_wait(&jobs.finish_cond, &jobs.mutex)
		}


		// if raw_data(blocks[0].to) == raw_data(arr) {

		// }

		for b in 0..<len(blocks) / 2 {
			block := blocks[b]
			from_low := block.to[:block.less]
			from_high := block.to[block.less:]
			// block_low := blocks[b * 2]
			// block_high := blocks[b * 2 + 1]
			blocks[b * 2].from[0] = from_low
			blocks[b * 2 + 1].from[0] = from_high


			// // // // fmt.println("block:",b,block.to, block.less, block.pivot)
		}

		start = 0

			// // // // fmt.println(arr)
			// // // // fmt.println(swap)
			// // // // fmt.println()
		for &b in blocks {
			// // // // fmt.print(len(b.from[0]), " ")
			end := start + len(b.from[0])

			b.from[1] = swap[start : end]
			b.to = arr[start : end]

			start = end
		}
			// // // // fmt.println()
			// // // // fmt.println()
		// startt := time.tick_now()
		slice.sort_by_with_data(idx,proc(l,r:int,user_data:rawptr)->bool{
			blocks := (^[]Task_Data)(user_data)
			return len(blocks[l].to) < len(blocks[r].to)
		},&blocks)

		// // // fmt.println(time.tick_since(startt))

		jobs.final = true
		jobs.remaining = len(blocks)
		jobs.job_nums = len(blocks)
		// // // // fmt.println("last dings")
		lastt = time.tick_now()
		sync.mutex_unlock(&jobs.mutex)
		// send signal
		sync.cond_broadcast(&jobs.cond)
		

		// jobs.shutdown = true
	}



	thread_land :: proc(t: ^thread.Thread) {

		job := cast(^Job_Data)t.data

		outer: for {
			sync.mutex_lock(&job.mutex)
			// // // // fmt.println("hello from thread",job.remaining, job.final)

			for job.job_nums == 0 {
				if job.final {
					sync.mutex_unlock(&job.mutex)
					break outer
				}
				sync.cond_wait(&job.cond, &job.mutex)
				// // // // fmt.println("wakey", job.job_nums)
			}

			// if job.shutdown {
			// 	sync.mutex_unlock(&job.mutex)
			// 	break
			// }

			job.job_nums -= 1
			idx := job.job_idx[job.job_nums]
			data := &job.blocks[idx]

			final := job.final

			sync.mutex_unlock(&job.mutex)

			// do job
		
			if final {
				// fmt.println("final", len(data.to))
				assert(len(data.to) == len(data.from[0]) && len(data.from[0]) == len(data.from[1]))
				loop(data.to, data.from[1], data.from[0], data.data, nil, true)
				
			} else if len(data.to) == 0 {} else {
				// // // // fmt.println("regu", )
				less := 0
				arr := data.to
				swap := data.to[len(data.to) - 1:]
				pivot := data.pivot
				d := data.data

				for from in data.from {

					#unroll(8) for a in from {
						x := cast(int)LESS(a, pivot, d)
						arr[less] = a
						swap[less] = a
						#no_bounds_check swap = swap[-1:]
						less += x
					}
				
				}
				data.less = less
			}


			
			// move into the other lock | unlock block
			sync.mutex_lock(&job.mutex)
			// // // // fmt.println(job.remaining)
			job.remaining -= 1
			if job.remaining == 0 {
				if job.final {
					sync.mutex_unlock(&job.mutex)
					break
				}
				sync.cond_signal(&job.finish_cond)
			}
			sync.mutex_unlock(&job.mutex)
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

		// // // // fmt.println("cur")
		// // // // fmt.println(cur)
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

		// // // // fmt.println("arrr, swap")
		// // // // fmt.println(arr)
		// // // // fmt.println(swap)
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
		// // // fmt.println(len4, quart + n %% 4)
		// copy(swap[greater:], s4[:quart + n %% 4 - less4])
		// copy(swap[greater:], s4[:len(s4) - less4])
		copy(swap[greater:], s4[:len4])
		copy_duration33 += intrinsics.read_cycle_counter() - start
		start = intrinsics.read_cycle_counter()

		
		copy_duration += intrinsics.read_cycle_counter() - start0
		// // // // fmt.println("arrr, swap, after copy")
		// // // // fmt.println(arr)
		// // // // fmt.println(swap)
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

		// // // // fmt.println("cur")
		// // // // fmt.println(cur)
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

		// // // // fmt.println("arrr, swap")
		// // // // fmt.println(arr)
		// // // // fmt.println(swap)
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
		// // // // fmt.println("arrr, swap, after copy")
		// // // // fmt.println(arr)
		// // // // fmt.println(swap)
		return less
	}
}

