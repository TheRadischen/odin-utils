package msort

import "core:fmt"
import "core:slice"
import "base:intrinsics"

USIN :: intrinsics.type_is_integer
SIN :: intrinsics.type_is_unsigned
FLOAT :: intrinsics.type_is_float
/*
radix sorter, can sort any numeric, icluding unsigned, singed and floats

to sort a Struct provide a key proc like so:

Data :: struct {data: [4]int, key: f64}

radix(arr, proc(s: Data) -> f64{return s.key})
*/
radix_generic :: proc(arr: []$T) where USIN(T) || SIN(T) || FLOAT(T) {
	// you can delete the insertion sort if you know you never have arrays that smol
	if len(arr) <= 64 {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && arr[j - 1] > current; j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
		return
	}

	raw := ([^]byte)(raw_data(arr))
	SIZE :: size_of(T)

	when USIN(T) {
		// radix_generic_unsigned(raw, len(arr), SIZE, 0)
	} else when SIN(T) {
		
	} else {

	}
}
radix_generic_by :: proc(arr: []$T, key: proc(t: ^T) -> ^$K, allocator := context.allocator) where USIN(K) || SIN(K) || FLOAT(K) {
	if len(arr) <= 8 {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && key(&arr[j - 1])^ > key(&current)^; j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
		return
	}
	raw := ([^]byte)(raw_data(arr))
	K_SIZE :: size_of(K)
	base := uintptr(&arr[0])
	key_pos := uintptr(key(&arr[0]))
	offset := int(key_pos - base)
	type_size := size_of(T)
	when USIN(K) {
		radix_u_by(raw, len(arr), offset, type_size, K_SIZE)
	} else when SIN(K) {
		
	} else {

	}
}

radix_u_by :: #force_no_inline proc(arr: [^]byte, length, offset, type_size: int, $KEY_SIZE: int) {
	BASE :: 256

	// fmt.println("erm")
	
	counts : [KEY_SIZE][BASE]u32
	swap := make([]byte, length * type_size)
	defer delete(swap)

	read := arr[offset:]
	for i in 0..<length {
		#unroll for c in 0..<KEY_SIZE {
			ind := read[c]
			counts[c][ind] += 1
		}
		read = read[type_size:]
	}
	// fmt.println(counts)

	skip : [KEY_SIZE]bool = false		
	for c in 0..<KEY_SIZE {
		if counts[c][0] == u32(length) {
			skip[c] = true
		}
	}
	for i in 1..<BASE {
		#unroll for c in 0..<KEY_SIZE {
			if counts[c][i] == u32(length) {
				skip[c] = true
			}
			counts[c][i] += counts[c][i - 1]
		}
	}
	// fmt.println(counts)
	// fmt.println(skip)

	swap_ptr := raw_data(swap)
	read_base := arr
	write_base := swap_ptr
	// read_base := arr[(length - 1) * type_size:]
	// write_base := swap_ptr[(length - 1) * type_size:]

	for &count, i in counts {
		if skip[i] {
			continue
		}
		read := read_base[(length - 1) * type_size:]
		write := write_base

		for _ in 0..<length {
			ind := read[offset + i]
			// fmt.println("ind",ind)
			// fmt.println(count[ind])
			count[ind] -= 1
			// fmt.println("b4",write[0], read[0])
			intrinsics.mem_copy_non_overlapping(write[count[ind] * u32(type_size):], read, type_size)
			// fmt.println(write[0], read[0])
			read = read[-type_size:]
		}
		write_base, read_base = read_base, write_base
	}

	if write_base == arr {
		// fmt.println("swapping")
		intrinsics.mem_copy_non_overlapping(arr, swap_ptr, type_size * length)
	}
	// fmt.println(offset, length, type_size)
}

radix_u_by2 :: proc(arr: [^]byte, length, offset, type_size: int, $K_SIZE: int) {
	when K_SIZE == 1 {
		BASE :: 256
		BASE_SIZE :: K_SIZE
		SHIFT :: 8
	} else {
		BASE_SIZE :: K_SIZE / 2
		BASE :: 256 * 256
		SHIFT :: 16
	}
	
	counts : [BASE_SIZE][BASE]u32
	swap := make([]byte, length * type_size)
	defer delete(swap)

	read := arr[offset:]
	for i in 0..<length {
		#unroll for c in uint(0)..<BASE_SIZE {
			ind := read[:2]
			counts[c][ind] += 1
		}
		read = read[type_size:]
	}

	for i in 1..<BASE {
		#unroll for c in 0..<BASE_SIZE {
			counts[c][i] += counts[c][i - 1]
		}
	}

	for &count, i in counts {
		// if count[0] == i32(len(arr)) {
		// 	continue
		// }

		#reverse for a in arr {
			ind := BASE & (key(a) >> (uint(i) * 8))
			count[ind] -= 1
			swap[count[ind]] = a
		}
		swap, arr = arr, swap
	}
}