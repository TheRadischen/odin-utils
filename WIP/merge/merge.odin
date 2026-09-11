package merge

import "base:intrinsics"
import "core:fmt"



merge_parity :: proc(to, from: []int, left, right: int) {
	left_low := 0
	left_high := left - 1
	right_low := left
	right_high := left + right - 1
	write_low := 0
	write_high := right_high

	// youd test this at caller site
	if from[left_high] <= from[right_low] {
		copy(to, from)
		return
	}
	if from[left_low] > from[right_high] {
		copy(to, from[left:])
		copy(to[left:], from)
	}

	for _ in 0..<(left + right) / 2 {
		to[inc(&write_low)] = from[inc(&left_low)] if from[left_low] <= from[right_low] else from[inc(&right_low)]
		to[dec(&write_high)] = from[dec(&left_high)] if from[left_high] > from[right_high] else from[dec(&right_high)]
	}
	if (left + right) %% 2 == 1 {
		to[write_low] = from[left_low] if from[left_low] <= from[right_low] else from[right_low]
	}

}

merge_cross_loop4 :: proc(to, from: []int, left, right: int) {
	l := 0
	r := left
	i := 0

	if l + 3 < left && r + 3 < left + right {
	left_hand := true
	outer: for {
		if left_hand {
			for from[l + 3] <= from[r] {
				copy(to[i:], from[l:][:4])
				i += 4; l += 4
				if l + 3 >= left {break outer}
			}
			if from[l + 1] <= from[r] {
				copy(to[i:], from[l:][:2])
				i += 2; l += 2
				// if l + 3 >= left {break outer}
			}
			if from[l] > from[r + 1] {
				copy(to[i:], from[r:][:2])
				i += 2; r += 2 
				if r + 3 >= left + right {break outer}
				left_hand = false
				continue outer
			}
		} else {
			for from[l] > from[r + 3] {
				copy(to[i:], from[r:][:4])
				i += 4; r += 4 
				if r + 3 >= left + right {break outer}
			}
			if from[l] > from[r + 1] {
				copy(to[i:], from[r:][:2])
				i += 2; r += 2 
				// if r + 3 >= left + right {break outer}
			}
			if from[l + 1] <= from[r] {
				copy(to[i:], from[l:][:2])
				i += 2; l += 2
				if l + 3 >= left {break outer}
				left_hand = true
				continue outer
			}
		}


		x := cast(int)(from[l] <= from[r])
		to[i + 1 - x] = from[l]
		to[i + x] = from[r]
		i += 2
		l += 1
		r += 1

		// TODO:test_speed
		// to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]

		if !(l + 3 < left && r + 3 < left + right) {
			break
		}
	}}

	for l < left && r < left + right {
		to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]
	}


	if l < left {
		copy(to[i:], from[l:left])
	} else if r < left + right {
		copy(to[i:], from[r:])
	}
}


merge_cross_loop2 :: proc(to, from: []int, left, right: int) {
	l := 0
	r := left
	i := 0

	if l + 1 < left && r + 1 < left + right {
	left_hand := true
	outer: for {
		if left_hand {
			for from[l + 1] <= from[r] {
				copy(to[i:], from[l:][:2])
				i += 2; l += 2
				if l + 1 >= left {break outer}
			}
			if from[l] > from[r + 1] {
				copy(to[i:], from[r:][:2])
				i += 2; r += 2 
				if r + 1 >= left + right {break outer}
				left_hand = false
				continue outer
			}
		} else {
			for from[l] > from[r + 1] {
				copy(to[i:], from[r:][:2])
				i += 2; r += 2 
				if r + 1 >= left + right {break outer}
			}
			if from[l + 1] <= from[r] {
				copy(to[i:], from[l:][:2])
				i += 2; l += 2
				if l + 1 >= left {break outer}
				left_hand = true
				continue outer
			}
		}


		x := cast(int)(from[l] <= from[r])
		to[i + 1 - x] = from[l]
		to[i + x] = from[r]
		i += 2
		l += 1
		r += 1

		// TODO:test_speed
		// to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]

		if !(l + 1 < left && r + 1 < left + right) {
			break
		}
	}}

	for l < left && r < left + right {
		to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]
	}


	if l < left {
		copy(to[i:], from[l:left])
	} else if r < left + right {
		copy(to[i:], from[r:])
	}
}


merge_cross4 :: proc(to, from: []int, left, right: int) {
	l := 0
	r := left
	i := 0

	for l + 3 < left && r + 3 < left + right {
		if from[l + 3] <= from[r] {
			copy(to[i:], from[l:][:4])
			i += 4; l += 4
		} else if from[l + 1] <= from[r] {
			copy(to[i:], from[l:][:2])
			i += 2; l += 2
		} else if from[l] > from[r + 3] {
			copy(to[i:], from[r:][:4])
			i += 4; r += 4 
		} else if from[l] > from[r + 1] {
			copy(to[i:], from[r:][:2])
			i += 2; r += 2 
		} else {
			x := cast(int)(from[l] <= from[r])
			to[i + 1 - x] = from[l]
			to[i + x] = from[r]
			i += 2
			l += 1
			r += 1
			// i dont know about this, its not neccessary, TODO:test_speed
			// to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]
		}
	}
	for l < left && r < left + right {
		to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]
	}


	if l < left {
		copy(to[i:], from[l:left])
	} else if r < left + right {
		copy(to[i:], from[r:])
	}
}


merge_cross :: proc(to, from: []int, left, right: int) {
	l := 0
	r := left
	i := 0

	for l + 1 < left && r + 1 < left + right {
		if from[l + 1] <= from[r] {
			copy(to[i:], from[l:][:2])
			i += 2; l += 2
		} else 	if from[l] > from[r + 1] {
			copy(to[i:], from[r:][:2])
			i += 2; r += 2 
		} else {
			x := cast(int)(from[l] <= from[r])
			to[i + 1 - x] = from[l]
			to[i + x] = from[r]
			i += 2
			l += 1
			r += 1
			// i dont know about this, its not neccessary, TODO:test_speed
			to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]
		}
	}
	for l < left && r < left + right {
		to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]
	}


	if l < left {
		copy(to[i:], from[l:left])
	} else if r < left + right {
		copy(to[i:], from[r:])
	}
}

merge_cross_parity :: proc(to, from: []int, left, right: int) {
	left_low := 0
	left_high := left - 1
	right_low := left
	right_high := left + right - 1
	write_low := 0
	write_high := right_high

	// youd test this at caller site
	if from[left_high] <= from[right_low] {
		copy(to, from)
		return
	}
	if from[left_low] > from[right_high] {
		copy(to, from[left:])
		copy(to[left:], from)
	}

	if left_high - left_low > 1 && right_high - right_low > 1 {
	low_left_hand := true
	high_left_hand := true
	outer: for {
		if low_left_hand {
			for from[left_low + 1] <= from[right_low] {
				copy(to[write_low:], from[left_low:][:2])
				write_low += 2; left_low += 2
				if left_low + 1 >= left_high {break outer}
			}
			if from[left_low] > from[right_low + 1] {
				copy(to[write_low:], from[right_low:][:2])
				write_low += 2; right_low += 2
				if right_low + 1 >= right_high {break outer}
			}
		} else {
			for from[left_low] > from[right_low + 1] {
				copy(to[write_low:], from[right_low:][:2])
				write_low += 2; right_low += 2
				if right_low + 1 >= right_high {break outer}
			}
			if from[left_low + 1] <= from[right_low] {
				copy(to[write_low:], from[left_low:][:2])
				write_low += 2; left_low += 2
				if left_low + 1 >= left_high {break outer}
			}
		}
		x := cast(int)(from[left_low] <= from[right_low])
		to[write_low + 1 - x] = from[left_low]
		to[write_low + x] = from[right_low]
		write_low += 2
		left_low += 1
		right_low += 1

		if !(left_high - left_low > 1 && right_high - right_low > 1) {
			break
		}

		if high_left_hand {
			for from[left_high + 1] <= from[right_high] {
				copy(to[write_high:], from[left_high:][:2])
				write_high += 2; left_high += 2
				if left_high + 1 >= left_high {break outer}
			}
			if from[left_high] > from[right_high + 1] {
				copy(to[write_high:], from[right_high:][:2])
				write_high += 2; right_high += 2
				if right_high + 1 >= right_high {break outer}
			}
		} else {
			for from[left_high] > from[right_high + 1] {
				copy(to[write_high:], from[right_high:][:2])
				write_high += 2; right_high += 2
				if right_high + 1 >= right_high {break outer}
			}
			if from[left_high + 1] <= from[right_high] {
				copy(to[write_high:], from[left_high:][:2])
				write_high += 2; left_high += 2
				if left_high + 1 >= left_high {break outer}
			}
		}
		y := cast(int)(from[left_high] <= from[right_high])
		to[write_high + 1 - y] = from[left_high]
		to[write_high + y] = from[right_high]
		write_high += 2
		left_high += 1
		right_high += 1

		if !(left_high - left_high > 1 && right_high - right_high > 1) {
			break
		}
	}} 



	for _ in 0..<(left + right) / 2 {
		to[inc(&write_low)] = from[inc(&left_low)] if from[left_low] <= from[right_low] else from[inc(&right_low)]
		to[dec(&write_high)] = from[dec(&left_high)] if from[left_high] > from[right_high] else from[dec(&right_high)]
	}
	if (left + right) %% 2 == 1 {
		to[write_low] = from[left_low] if from[left_low] <= from[right_low] else from[right_low]
	}
}

merge_branchless :: proc(to, from: []int, left, right: int) {
	l := 0
	r := left
	i := 0
	for l < left && r < left + right {
		to[inc(&i)] = from[inc(&l)] if from[l] <= from[r] else from[inc(&r)]
	}
	if l < left {
		copy(to[i:], from[l:left])
	} else if r < left + right {
		copy(to[i:], from[r:])
	}
}

inc :: proc(p: ^int) -> int {
	defer p^ += 1
	return p^
}
dec :: proc(p: ^int) -> int {
	defer p^ -= 1
	return p^
}

merge_dumb :: proc(to, from: []int, left, right: int) {
	l := 0
	r := left
	i := 0
	for l < left && r < left + right {
		if from[l] > from[r] {
			to[i] = from[r]
			r += 1
		} else {
			to[i] = from[l]
			l += 1
		}
		i += 1
	}
	for l < left {
		to[i] = from[l]
		l += 1
		i += 1
	}
	for r < left + right {
		to[i] = from[r]
		r += 1
		i += 1
	}
}