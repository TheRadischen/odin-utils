package msort

import "core:slice"
import "base:intrinsics"

USIN :: intrinsics.type_is_integer
SIN :: intrinsics.type_is_unsigned
FLOAT :: intrinsics.type_is_float
/*
radix sorter, can sort any numeric type exept i8

to sort a Struct provide a key proc like so:

Data :: struct {data: [4]int, key: f64}

radix(arr, proc(s: Data) -> f64{return s.key})
*/
radix_generic :: proc(arr: []$T) where USIN(T) || SIN(T) || FLOAT(T) {
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
		radix_generic_unsigned(raw, len(arr), SIZE, 0)
	} else when SIN(T) {
		
	} else {

	}
}
radix_generic_by :: proc(arr: []$T, key: proc(t: ^T) -> ^$K) where USIN(K) || SIN(K) || FLOAT(K) {
	if len(arr) <= 64 {
		for i in 1..<len(arr) {
			current := arr[i]
			j := i
			for ; j > 0 && key(arr[j - 1]) > key(current); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = current
		}
		return
	}
	when USIN(K) {

	} else when SIN(K) {
		
	} else {

	}
}

radix_generic_unsigned :: proc(arr: [^]byte, length, size, offset: int) {

}