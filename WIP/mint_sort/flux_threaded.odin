package ermsort

import "core:slice"
import "core:log"
import "base:runtime"
import "core:thread"
import "core:container/queue"
import "core:fmt"
import "base:intrinsics"

/*
	thanks to scandum for flux partitioning
	https://github.com/scandum
*/

// uncomment if used independently

// ORD :: intrinsics.type_is_ordered
// Ordering :: enum {
// 	Less = -1,
// 	Equal = 0,
// 	Greater = 1,
// }

/*
WARNING: each call generates a new quicksort, only use in performance critical path

This sort is stable

	example :: proc() {
		arr := []int{3,2,1}
		sort.sort_stable(arr)
	}
*/
sort_stable_threaded :: proc(arr: $T/[]$E, pool: ^thread.Pool, allocator := context.allocator) where ORD(E) {
	when size_of(E) != 0 {
		if len(arr) > 1 {
			base_type :: intrinsics.type_core_type(E)
			mini_flux_threaded(transmute([]base_type)arr, rawptr(nil), 
			proc(l, r: base_type, data: rawptr) -> bool { return l < r }, 
			// proc(a, b: int, data: rawptr) -> bool {
			// 	x := a
			// 	for i in 0..<100 {
			// 		x = x * 16645 + 10139042
			// 		x = x %% 101
			// 	}

			// 	return x %% 100_0 < b %% 100_0
			// },
			pool, allocator)
		}
	}
}


mini_flux_threaded :: proc(arr: $A/[]$T, data: $D, $LESS: $P, pool: ^thread.Pool, allocator := context.allocator) {
	if len(arr) <= 64 {
		insertion_sort(arr, data)
		return
	}

	Task_Data :: struct {
		arr: []int,
		swap: []int,
		is_swap: bool,
		pivot: int,
		data: D,
		less: int, // out
	}
	Stack_data :: struct {
		arr, swap: A,
		is_swap: bool
	}
	Loop_data :: struct{
		arr, swap, cur: A,
		// is_swap: bool,
		data: D,
	}
	swap := make(A, len(arr), allocator)
	// loop(arr, swap, arr, data, nil, true)
	stacked(arr, swap, data, pool, allocator)
	delete(swap, allocator)

	MAX_THREADS :: 16

	stacked :: proc(arr, swap: A, data: D, pool: ^thread.Pool, allocator: runtime.Allocator) {

		stack : [MAX_THREADS]Stack_data
		tasks : [dynamic;MAX_THREADS]Task_Data
		loop_data : [MAX_THREADS]Loop_data
		stack[0] = {arr, swap, false}
		for parts := 1; parts <= MAX_THREADS / 2; parts *= 2 {

			task_num := 0
			splits := MAX_THREADS / parts

			for i in 0..<parts{
				if len(stack[i].arr) == 0 {continue}
				split_arr(stack[i], splits, data, &tasks)
			}

			for &t,i in tasks {
				// manual_thread(&t)
				thread.pool_add_task(pool, allocator, thread_land, &t,i)
			}
			t := 0
			for task in thread.pool_pop_waiting(pool) {
				t += 1
				thread.pool_do_work(pool, task)
			}
		
				// fmt.println("doing tasks lol", t)

			// for in_process : int = intrinsics.atomic_load(&pool.num_in_processing); in_process > 0; in_process = intrinsics.atomic_load(&pool.num_in_processing)  {
			// 	// fmt.println(in_process)
			// 	thread.yield()
			// }
			// resize(&tasks,0)
			// thread.pool_finish(pool)
			// intrinsics.atomic_store(&pool.num_done, 0)
			resize(&pool.tasks_done, 0)
			
			// thread.pool_join(pool)


			for i := parts - 1; i >= 0; i -= 1 {
				arr, swap := stack[i].arr, stack[i].swap
				cur_tasks := tasks[i * splits:][:splits]

				length := len(arr)
				block_length := length / splits

				less := cur_tasks[0].less
				greater := block_length - less


				for j in 1..<splits {
					a := cur_tasks[j].arr
					s := cur_tasks[j].swap
					less_cur := cur_tasks[j].less
					intrinsics.mem_copy_non_overlapping(&arr[less], &a[0], less_cur * size_of(T))
					less += less_cur

					greater_cur := len(s) - less_cur
					greater += greater_cur
					if greater_cur > 0 {
						intrinsics.mem_copy_non_overlapping(&swap[length - greater], &s[less_cur], greater_cur * size_of(T))
					}
					

				}


				stack[i*2+1] = {arr[less:], swap[less:], true}
				stack[i*2] = {arr[:less], swap[:less], false}

			}
			resize(&tasks,0)


		}
		
		slice.sort_by(stack[:], proc(l,r:Stack_data)->bool{return len(l.arr) > len(r.arr)})
		for &s,i in stack {

			arr, swap := s.arr, s.swap
			cur := swap if s.is_swap else arr

			loop_data[i] = Loop_data{arr, swap, cur, data}
			thread.pool_add_task(pool, allocator, loop_land, &loop_data[i],i)
		}
		thread.pool_finish(pool)
		// thread.pool_join(pool)
		// for thread.pool_num_done(pool) != MAX_THREADS {
		// 	thread.yield()
		// }
		// resize(&pool.tasks_done, 0)
	}

	split_arr :: proc(frame: Stack_data, splits: int, data: D, tasks: ^[dynamic;MAX_THREADS]Task_Data) {
		arr, swap, is_swap := frame.arr, frame.swap, frame.is_swap
		cur := swap if is_swap else arr

		length := len(arr)
		block_length := length / splits
		
		if len(cur) == 0 {
			panic("fuck this")
		}
		depth := log2(length) / 5 // + 1		
		pivot := med3(cur, data, depth)

		start_arr := 0
		start_swap := length - block_length

		for i in 0..<splits - 1 {
			append(tasks, Task_Data{
				arr[start_arr:][:block_length],
				swap[start_swap:][:block_length],
				is_swap,
				pivot,
				data,
				0,
			})

			start_arr += block_length
			start_swap -= block_length
		}
		append(tasks, Task_Data{
			arr[start_arr:],
			swap[:length - start_arr],
			is_swap,
			pivot,
			data,
			0,
		})
	}

	thread_land :: proc(task: thread.Task) {
		task_data := (^Task_Data)(task.data)
		arr, swap, data, pivot := task_data.arr, task_data.swap, task_data.data, task_data.pivot

		left : int = 0
		if !task_data.is_swap {
			left = partition(arr, swap, arr, data, pivot)
		} else {
			left = partition_rev(arr, swap, swap, data, pivot)
		}
		task_data.less = left
	}

	manual_thread :: proc(task_data: ^Task_Data) {
		arr, swap, data, pivot := task_data.arr, task_data.swap, task_data.data, task_data.pivot

		left : int = 0
		if !task_data.is_swap {
			left = partition(arr, swap, arr, data, pivot)
		} else {
			left = partition_rev(arr, swap, swap, data, pivot)
		}
		task_data.less = left
	}

	loop_land :: proc(task: thread.Task) {
		task_data := (^Loop_data)(task.data)

		loop(task_data.arr, task_data.swap, task_data.cur, task_data.data, nil, true)
	}

	loop :: proc(arr, swap, cur: A, data: D, last_piv: Maybe(T), leftmost: bool)  {
		arr := arr; swap := swap; cur := cur; last_piv := last_piv; leftmost := leftmost
		for {

			if len(cur) <= 48 {
				length += len(cur)
				if raw_data(arr) != raw_data(cur) {
					
					i := 0
					#reverse for a in cur {
						arr[i] = a
						i += 1
					}

				}

				if leftmost {
					insertion_sort(arr, data)
				} else {
					insertion_sort_unguarded(arr, data)
				}
				return
			}

			depth := log2(len(cur)) / 5 
			pivot := med3(cur, data, depth)

			if pivot == last_piv {
				left : int
				if raw_data(arr) == raw_data(cur) {
					left = partition_reverse(arr, swap, cur, data, pivot)
				} else {
					left = partition_reverse_rev(arr, swap, cur, data, pivot)
				}

				arr = arr[left:]
				cur = swap[left:]
				swap = swap[left:]
				last_piv = nil
				leftmost = false
				continue
			}

			left : int
			if raw_data(arr) == raw_data(cur) {
				left = partition(arr, swap, cur, data, pivot)
			} else {
				left = partition_rev(arr, swap, cur, data, pivot)
			}

			loop(arr[:left], swap[:left], arr[:left], data, nil, leftmost)
			
			arr = arr[left:]
			cur = swap[left:]
			swap = swap[left:]
			last_piv = pivot
			leftmost = false
		}
	}

	log2 :: proc(n: int) -> (log: int) {
		n := n
		for ; n > 0 ;n >>= 1 {
			log += 1
		}
		return log
	}

	med3 :: proc(arr: A, data: D, depth: int) -> T  {

		assert(len(arr) > 0)
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

	insertion_sort :: proc(arr: A, data: D)  {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	insertion_sort_unguarded :: proc(arr: A, data: D)  {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			#no_bounds_check for ; LESS(current, arr[j - 1], data); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	partition :: proc(arr, swap, cur: A, data: D, piv: T) -> int  {
		assert(len(arr) == len(swap) && len(swap) == len(cur))
		less := 0
		swap := swap[len(swap) - 1:]

		#unroll(8) for a,i in cur {
			x := cast(int)LESS(a, piv, data)
			arr[less] = a
			swap[less] = a
			#no_bounds_check swap = swap[-1:]
			less += x

		}
		
		return less
	}

	partition_rev :: proc(arr, swap, cur: A, data: D, piv: T) -> int  {
		assert(len(arr) == len(swap) && len(swap) == len(cur))
		less := 0
		swap := swap[len(swap) - 1:]

		#reverse for a, i in cur {
			x := cast(int)LESS(a, piv, data)
			arr[less] = a
			swap[less] = a
			#no_bounds_check swap = swap[-1:]
			less += x
		}
		
		return less
	}

	partition_reverse :: proc(arr, swap, cur: A, data: D, piv: T) -> int  {
		assert(len(arr) == len(swap) && len(swap) == len(cur))
		less_equal := 0
		swap := swap[len(swap) - 1:]

		#unroll(8) for a in cur {
			x := cast(int)!LESS(piv, a, data)
			arr[less_equal] = a
			swap[less_equal] = a
			#no_bounds_check swap = swap[-1:]
			less_equal += x
		}
		
		return less_equal
	}

	partition_reverse_rev :: proc(arr, swap, cur: A, data: D, piv: T) -> int  {
		assert(len(arr) == len(swap) && len(swap) == len(cur))
		less_equal := 0
		swap := swap[len(swap) - 1:]

		#reverse for a in cur {
			x := cast(int)!LESS(piv, a, data)
			arr[less_equal] = a
			swap[less_equal] = a
			#no_bounds_check swap = swap[-1:]
			less_equal += x
		}
		
		return less_equal
	}
}

