package msort

import "base:runtime"
import "core:fmt"
import "base:intrinsics"




radix :: proc{radix_u8, radix_unsigned, radix_i8, radix_integer, radix_float}

radix_unsigned :: proc(data: $A, $key: proc(^$T) -> ^$U, allocator := context.allocator)
where intrinsics.type_is_unsigned(U), U != u8 {
	BASE :: 256
	SIZE :: size_of(U)
	swap := make(A, len(data), allocator)
	defer delete(swap, allocator)
	arr := data
	counts : [SIZE][BASE + 1]i32

	// count 
	for &a in arr {
		k := key(&a)^
		#unroll for c in uint(0)..<SIZE {
			ind := 0xff & (k >> (c * 8))
			counts[c][ind + 1] += 1
		}
	}

	// calc offset
	for i in 1..<BASE {
		#unroll for c in 0..<SIZE {
			counts[c][i] += counts[c][i - 1]
		}
	}

	// swap
	for &count, i in counts {
		// this could be much smarter
		if count[1] == i32(len(arr)) {
			continue
		}

		for &a in arr {
			ind := 0xff & (key(&a)^ >> (uint(i) * 8))
			swap[count[ind]] = a
			count[ind] += 1
		}
		swap, arr = arr, swap
	}

	// swap if we skipped odd amounts
	if slice_eq(arr, data) {
		copy(swap, arr)
		swap, arr = arr, swap
	}
}

radix_u8 :: proc(data: $A, $key: proc(^$T) -> ^u8, allocator := context.allocator) {
	BASE :: 256
	swap := make(A, len(data), allocator)
	defer delete(swap, allocator)
	arr := data
	counts : [BASE + 1]i32

	for &a in arr {
		ind := 0xff & key(&a)^
		counts[ind+1] += 1
	}

	for i in 1..<BASE {
		counts[i] += counts[i - 1]
	}

	for &a in arr {
		ind := 0xff & key(&a)^
		swap[counts[ind]] = a
		counts[ind] += 1
	}

	my_copy(arr, swap)
}
radix_i8 :: proc(data: $A, $key: proc(^$T) -> ^i8, allocator := context.allocator) {
	BASE :: 256
	swap := make(A, len(data), allocator)
	defer delete(swap, allocator)
	arr := data
	counts : [BASE + 1]i32

	for &a in arr {
		ind := transmute(u8)key(&a)^ ~ u8(1 << 7)
		counts[ind+1] += 1
	}

	for i in 1..<BASE {
		counts[i] += counts[i - 1]
	}

	for &a in arr {
		ind := transmute(u8)key(&a)^ ~ u8(1 << 7)
		swap[counts[ind]] = a
		counts[ind] += 1
	}

	my_copy(arr, swap)
}
radix_float :: proc(data: $A, $key: proc(^$T) -> ^$F, allocator := context.allocator) 
where intrinsics.type_is_float(F) {
	
	SIZE :: size_of(F)

	when SIZE == 2 {
		UT :: u16
		IT :: i16
	} else when SIZE == 4 {
		UT :: u32
		IT :: i32
	} else when SIZE == 8 {
		UT :: u64
		IT :: i64
	} else {
		#panic()
	}
	
	
	BASE :: 256
	swap := make(A, len(data), allocator)
	defer delete(swap, allocator)
	arr := data
	SIZEm1 :: SIZE * 8 - 1
	counts : [SIZE][BASE + 1]i32

	for &a in arr {
		k := transmute(^UT)key(&a)
		k^ ~= (transmute(UT)((-cast(IT)(k^ >> SIZEm1))) | (1 << SIZEm1))
		#unroll for c in uint(0)..<SIZE {
			ind := 0xff & (k^ >> (c * 8))
			counts[c][ind + 1] += 1
		}
	}

	for i in 1..<BASE {
		#unroll for c in 0..<SIZE {
			counts[c][i] += counts[c][i - 1]
		}
	}


	for c in 0..<SIZE - 1 {
		count := counts[c]
		if count[1] == i32(len(arr)) {
			continue
		}
		
		for &a in arr {
			k := transmute(UT)key(&a)^
			ind := 0xff & (k >> (uint(c) * 8))
			swap[count[ind]] = a
			count[ind] += 1
		}
		swap, arr = arr, swap
	}
	


	for &a in arr {
		k := key(&a)
		u := transmute(UT)k^
		ind := 0xff & (u >> ((SIZE - 1) * 8))
		u ~= ((u >> SIZEm1) - 1) | (1 << SIZEm1)
		k^ = transmute(F)u
		swap[counts[SIZE-1][ind]] = a
		counts[SIZE-1][ind] += 1
	}
	swap, arr = arr, swap

	if !slice_eq(arr, data) {
		my_copy(arr, swap)
		swap, arr = arr, swap
	}
}
radix_float2 :: proc(data: $A, $key: proc(^$T) -> ^$F, allocator := context.allocator) 
where intrinsics.type_is_float(F) {
	
	SIZE :: size_of(F)

	when SIZE == 2 {
		UT :: u16
		IT :: i16
	} else when SIZE == 4 {
		UT :: u32
		IT :: i32
	} else when SIZE == 8 {
		UT :: u64
		IT :: i64
	} else {
		#panic()
	}
	
	
	BASE :: 256
	swap := make(A, len(data), allocator)
	defer delete(swap, allocator)
	arr := data
	SIZEm1 :: SIZE * 8 - 1
	counts : [SIZE][BASE + 1]i32

	for &a in arr {
		k := transmute(UT)key(&a)^
		
		k2 := k ~ (transmute(UT)((-cast(IT)(k >> SIZEm1))) | (1 << SIZEm1))
		#unroll for c in uint(0)..<SIZE {
			ind := 0xff & (k2 >> (c * 8))
			counts[c][ind + 1] += 1
		}
	}

	for i in 1..<BASE {
		#unroll for c in 0..<SIZE {
			counts[c][i] += counts[c][i - 1]
		}
	}

	for &a in arr {
		k := key(&a)
		u := transmute(UT)k^
		u ~= transmute(UT)(-cast(IT)(u >> SIZEm1)) | (1 << SIZEm1)
		k^ = transmute(F)u
		ind := 0xff & u
		swap[counts[0][ind]] = a
		counts[0][ind] += 1
	}
	swap, arr = arr, swap

	when F != f16 {
		for c in 1..<SIZE - 1 {
			count := counts[c]
			if count[1] == i32(len(arr)) {
				continue
			}
			
			for &a in arr {
				k := transmute(UT)key(&a)^
				ind := 0xff & (k >> (uint(c) * 8))
				swap[count[ind]] = a
				count[ind] += 1
			}
			swap, arr = arr, swap
		}
	}


	for &a in arr {
		k := key(&a)
		u := transmute(UT)k^
		ind := 0xff & (u >> ((SIZE - 1) * 8))
		u ~= ((u >> SIZEm1) - 1) | (1 << SIZEm1)
		k^ = transmute(F)u
		swap[counts[SIZE-1][ind]] = a
		counts[SIZE-1][ind] += 1
	}
	swap, arr = arr, swap

	if !slice_eq(arr, data) {
		my_copy(arr, swap)
		swap, arr = arr, swap
	}
}

radix_integer :: proc(data: $A, $key: proc($T) -> ^$I, allocator := context.allocator) 
where intrinsics.type_is_integer(I), I != i8 {

	SIZE :: size_of(I)
	BASE :: 256
	swap := make(A, len(data), allocator)
	defer delete(swap, allocator)
	arr := data
	SIZEm1 :: SIZE * 8 - 1
	counts : [SIZE][BASE + 1]i32

	for &a in arr {
		k := key(&a)
		k^ ~= min(I)
		
		#unroll for c in uint(0)..<SIZE {
			ind := 0xff & (k^ >> (c * 8))
			counts[c][ind + 1] += 1
		}
	}

	for i in 1..<BASE {
		#unroll for c in 0..<SIZE {
			counts[c][i] += counts[c][i - 1]
		}
	}

	for c in 0..<SIZE - 1 {
		count := counts[c]
		if count[1] == i32(len(arr)) {
			continue
		}
		
		for &a in arr {
			k := key(&a)^
			ind := 0xff & (k >> (uint(c) * 8))
			swap[count[ind]] = a
			count[ind] += 1
		}
		swap, arr = arr, swap
	}



	for &a in arr {
		k := key(&a)
		ind := 0xff & (k^ >> ((SIZE - 1) * 8))
		k^ ~= min(I)
		swap[counts[SIZE-1][ind]] = a
		counts[SIZE-1][ind] += 1
	}
	swap, arr = arr, swap

	if !slice_eq(arr, data) {
		my_copy(arr, swap)
		swap, arr = arr, swap
	}
}

slice_eq :: proc(l, r: $A) -> bool {
	when intrinsics.type_is_slice(A) {
		return raw_data(l) == raw_data(r)
	} else {
		arr1 := l
		arr2 := r
		return (^int)(&arr1)^ == (^int)(&arr2)^
	}
}

my_copy :: proc(dst, src: $A) {
	when intrinsics.type_is_slice(A) {
		copy(dst, src)
	} else {
		length := min(len(dst), len(src))
		for i in 0..<length {
			dst[i] = src[i]
		}
	}
}