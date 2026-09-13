#+ignore
package msort

import "core:container/queue"
import "core:sync"
import "core:mem"
import "core:thread"
import "core:fmt"
import "base:intrinsics"


sort :: proc(arr: []int, pool: ^thread.Pool) {
	swap := make([]int, len(arr))
	defer delete(swap)
	threading(arr, swap, arr, pool, 16)
	Task_Data :: struct {
		arr: []int,
		swap: []int,
		cur: []int,
		pivot: int,
		less: int, // out
	}
	MAX_PARALLELL :: 16

	threading :: proc(arr, swap, cur: []int, pool: ^thread.Pool, num_threads: int) {
		tasks : [MAX_PARALLELL]Task_Data = ---
		pivot := cur[len(cur) / 2]
		block_size := len(arr) / num_threads
		for i in 0..<num_threads - 1 {
			a := arr[i * block_size:][:block_size]
			s := swap[i * block_size:][:block_size]
			c := cur[i * block_size:][:block_size]
			tasks[i] = Task_Data{a, s, c, pivot, 0}
			task_data := &tasks[i]
			thread.pool_add_task(pool, context.allocator, thread_proc, task_data, i)
		}

		less_last := partition(
			arr[num_threads * block_size:],
			swap[num_threads * block_size:],
			cur[num_threads * block_size:],
			pivot
		) 
		thread.pool_join(pool)

		less := 0
		for i in 0..<num_threads - 1 {
			less += tasks[i].less
			copy(arr[less:], arr[block_size:][:tasks[i + 1].less])
		}
		less += less_last

		greater := 0
		end := swap[len(swap):]
		g := block_size - tasks[num_threads].less
		for i := num_threads - 1; i >= 0; i -= 1 {
			greater += g
			g = block_size - tasks[i].less
			copy(end[-greater:], tasks[i].swap[:g])
		}
	}

	thread_proc :: proc(task: thread.Task) {
		data := (^Task_Data)(task.data)
		arr := data.arr
		swap := data.swap
		cur := data.cur
		piv := data.pivot
		data.less = partition(arr, swap, cur, piv)
	}

	partition :: proc(arr, swap, cur: []int, pivot: int) -> (less: int) {
		swap := swap[len(arr) - 1:]

		#unroll(8) for a in cur {
			x := cast(int)(pivot)
			arr[less] = a
			swap[less] = a
			#no_bounds_check swap = swap[-1:]
			less += x
		}
		
		return less
	}

}






mini_thread :: proc(arr: []int) {

	swap := make([]int, len(arr))
	defer delete(swap)
	THREAD_COUNT :: 16
	Task_Data :: struct {
		arr: []int,
		swap: []int,
		cur: []int,
		pivot: int,
		less: int, // out
	}
	
	pool: thread.Pool
	pool_allocator: mem.Allocator
	pool_allocator = context.allocator
	thread.pool_init(&pool, pool_allocator, THREAD_COUNT)
	thread.pool_start(&pool)
	defer thread.pool_destroy(&pool)
	

	thred(arr, swap, arr, nil, true, &pool)

	thred :: proc(arr, swap, cur: []int, last_piv: Maybe(int), leftmost: bool, pool: ^thread.Pool) #no_bounds_check {
		for {
			if len(cur) <= 10_000 {
				task_data := Task_Data{arr, swap, cur}
				thread.pool_add_task(pool, context.temp_allocator, thread_loop, &task_data)
			}
		}
	}


	thread_loop :: proc(task: thread.Task) {
		// The data is passed as a `rawptr`,
		// so we cast it to the type expected by the task.
		data := cast(^Task_Data)task.data

		// Compute and store the sum.
		loop(data.arr, data.swap, data.cur, nil, false)
	}

	loop :: proc(arr, swap, cur: []int, last_piv: Maybe(int), leftmost: bool) #no_bounds_check {
		arr := arr; cur := cur; last_piv := last_piv; leftmost := leftmost
		for {
			if len(arr) <= 48 {
				if leftmost {
					insertion_sort(arr)
				} else {
					insertion_sort_unguarded(arr)
				}
				return
			}

			depth := log2(len(arr)) / 5 
			pivot := med3(cur, depth)

			if pivot == last_piv {
				left := partition_reverse(arr, swap, cur, pivot)
				right := len(arr) - left
				arr = arr[left:]
				cur = swap[:right]
				last_piv = nil
				leftmost = false
				continue
			}

			left := partition(arr, swap, cur, pivot)
			right := len(arr) - left

			loop(arr[left:], swap, swap[:right], pivot, false)
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

	med3 :: proc(arr: []int, depth: int) -> int #no_bounds_check {
		if depth == 0 {
			return arr[0]
		}

		div := len(arr) / 3

		swap := [3]int{
			med3(arr[:div], depth - 1), 
			med3(arr[div:][:div], depth - 1), 
			med3(arr[div * 2:], depth - 1)
		}
		
		x := cast(int)(swap[0] < swap[1])
		y := cast(int)(swap[0] < swap[2])
		z := cast(int)(swap[1] < swap[2])

		return swap[(int)(x == y) + (int)(y ~ z)]
	}

	insertion_sort :: proc(arr: []int) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && current < arr[j - 1]; j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	insertion_sort_unguarded :: proc(arr: []int) #no_bounds_check {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; current < arr[j - 1]; j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
	}

	partition :: proc(arr, swap, cur: []int, piv: int) -> int #no_bounds_check {
		less := 0

		#unroll(8) for a,i in cur {
			x := cast(int)(a < piv)
			arr[less] = a
			swap[i - less] = a
			less += x
		}
		
		return less
	}

	partition_parity :: proc(arr, swap, cur: []int, piv: int) -> int #no_bounds_check {
		n := len(cur)
		half := n / 2
		half2 := n - half

		less1 := 0; less2 := 0
		a1 := arr[:half]; a2 := arr[half:][:half2]
		s1 := swap[:half]; s2 := swap[half:][:half2]
		c1 := cur[:half]; c2 := cur[half:][:half2]

		#unroll(8) for a,i in a1 {
			x := cast(int)(a < piv)
			a1[less1] = c1[i]
			s1[i - less1] = c1[i]
			less1 += x

			y := cast(int)(a < piv)
			a2[less2] = c2[i]
			s2[i - less2] = c2[i]
			less2 += y
		}

		if half != half2 {
			y := cast(int)(c2[half] < piv)

			a2[less2] = c2[half]
			s2[half - less2] = c2[half]
			less2 += y
		}

		intrinsics.mem_copy_non_overlapping(&arr[less1], &a2[0], less2 * size_of(int))
		intrinsics.mem_copy_non_overlapping(&swap[half - less1], &s2[0], ((n-half) - less2) * size_of(int))

		return less1 + less2
	}



	partition_reverse :: proc(arr, swap, cur: []int, piv: int) -> int #no_bounds_check {
		less_equal := 0

		#unroll(8) for a,i in cur {
			x := cast(int)(piv >= a)
			arr[less_equal] = a
			swap[i - less_equal] = a
			less_equal += x
		}
		
		return less_equal
	}
}

