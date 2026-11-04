package unstable

import "base:builtin"
import "base:intrinsics"
import "core:slice"
import "core:math/rand"
import "core:time"
import "core:fmt"

Ordering :: enum {
	Less    = -1,
	Equal   =  0,
	Greater = +1,
}

Generic_Cmp :: #type proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering

N :: #config(N, 1)
base : []int
main :: proc() {

	for i := 10; i <= 1_000_000; i *= 10 {
		sort_sizes(i, int)
		// sort_sizes(i, i32)
		// sort_sizes(i, f64)
		sort_sizes(i, f32)
	}
}

Data :: struct($T: typeid) {
	rand: T,
	junk: [N]int,
}
comps: int
sort_sizes :: proc(size: int, $T: typeid) {
	arr := make([]Data(T), size)
	defer delete(arr)
	iter := 1_00_000 / size 
	min_time : time.Duration = time.MAX_DURATION
	min_time2 : time.Duration = time.MAX_DURATION
	smooth_cmp: int
	quick_cmp: int
	for i in 0..<clamp(iter, 1, 10_000) {
		ran(arr)
		start := time.tick_now()
		comps = 0
		slice.sort_by(arr, proc(l,r: Data(T))->bool{
			comps += 1
			return l.rand < r.rand
		})
		quick_cmp = comps
		dur := time.tick_since(start)
		min_time = min(min_time, dur)
		if !slice.is_sorted_by(arr, proc(l,r: Data(T))->bool{
			return l.rand < r.rand
		}) {
			fmt.println(arr)
			panic("not sorted")
		}

		ran(arr)
		start = time.tick_now()
		comps = 0
		sort_by(arr, proc(l,r: Data(T))->bool{
			comps += 1
			return l.rand < r.rand
		})
		dur = time.tick_since(start)
		min_time2 = min(min_time2, dur)
		if !slice.is_sorted_by(arr, proc(l,r: Data(T))->bool{
			return l.rand < r.rand
		}) {
			fmt.println(arr)
			panic("not sorted")
		}
		smooth_cmp = comps
	}
	fmt.println("type:", typeid_of(T), "size: ",size,"quick: time:", min_time,"comps:", quick_cmp, "  ||  smooth: time", min_time2,"comps:", smooth_cmp)
}
ran :: proc(arr: []Data($T)) {
	for &a,i in arr {
		a.rand = cast(T)(len(arr) / 2 - rand.int_max(len(arr)))
		a.junk[0] = i
	}
}



sort_by :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			raw := ([^]byte)(raw_data(data))
			_smoothsort(raw, uint(len(data)), size_of(E), proc(lhs, rhs: rawptr, user_data: rawptr) -> Ordering {
				x, y := (^E)(lhs)^, (^E)(rhs)^
				less := (proc(E, E) -> bool)(user_data)
				switch {
				case less(x, y): return .Less
				case less(y, x): return .Greater
				}
				return .Equal
			}, rawptr(less))
		}
	}
}


_smoothsort :: proc(base: [^]byte, nel: uint, width: uint, cmp: Generic_Cmp, arg: rawptr) {
	pntz :: proc "contextless" (p: [2]uint) -> int {
		r := intrinsics.count_trailing_zeros(p[0] - 1)
		if r != 0 {
			return int(r)
		}
		r = (8*size_of(uint) + intrinsics.count_trailing_zeros(p[1]))
		if r != 8*size_of(uint) {
			return int(r)
		}
		return 0
	}

	shl :: proc "contextless" (p: []uint, n: int) {
		n := n
		if n >= 8*size_of(uint) {
			n -= 8*size_of(uint)
			p[1] = p[0]
			p[0] = 0
		}
		p[1] <<= uint(n)
		p[0] |= p[0] >> uint(8*size_of(uint) - n)
		p[0] <<= uint(n)
	}
	shr :: proc "contextless" (p: []uint, n: int) {
		n := n
		if n >= 8*size_of(uint) {
			n -= 8*size_of(uint)
			p[0] = p[1]
			p[1] = 0
		}
		p[0] >>= uint(n)
		p[0] |= p[1] << uint(8*size_of(uint) - n)
		p[1] >>= uint(n)
	}

	cycle :: proc "contextless" (width: uint, data: [][^]byte, n: int) {
		if len(data) < 2 || n < 1 {
			return
		}
		buf: [256]u8 = ---
		width := width
		for width != 0 {
			l := builtin.min(size_of(buf), int(width))
			copy(buf[:l], data[0][:l])
			for i in 0..<n-1 {
				copy(data[i][:l], data[i+1][:l])
				data[i] = data[i][l:]
			}
			copy(data[n-1][:l], buf[:l])
			data[n-1] = data[n-1][l:]
			width -= uint(l)
		}
	}

	sift :: proc(head: [^]byte, width: uint, cmp: Generic_Cmp, arg: rawptr, pshift: int, lp: []uint) {
		head := head
		buf: [14*size_of(uint)+1][^]byte = ---
		buf[0] = head
		i := 1
		pshift := pshift
		for pshift > 1 {
			rt := head[-width:]
			lf := head[-width:][-lp[pshift - 2]:]
			if cmp(buf[0], lf, arg) >= .Equal && cmp(buf[0], rt, arg) >= .Equal {
				break
			}
			if cmp(lf, rt, arg) >= .Equal {
				buf[i], head = lf, lf
				pshift -= 1
			} else {
				buf[i], head = rt, rt
				pshift -= 2
			}
			i += 1
		}
		cycle(width, buf[:], i)
	}

	trinkle :: proc(head: [^]byte, width: uint, cmp: Generic_Cmp, arg: rawptr, pp: []uint, pshift: int, trusty: bool, lp: []uint) {
		head := head

		p := [2]uint{pp[0], pp[1]}

		buf: [14*size_of(uint)+1][^]byte = ---
		buf[0] = head

		i := 1
		trail := 0
		pshift := pshift
		trusty := trusty
		for p[0] != 1 || p[1] != 0 {
			stepson := head[-lp[pshift]:]
			if cmp(stepson, buf[0], arg) <= .Equal {
				break
			}
			if !trusty && pshift > 1 {
				rt := head[-width:]
				lf := head[-width:][-lp[pshift-2]:]
				if cmp(rt, stepson, arg) >= .Equal || cmp(lf, stepson, arg) >= .Equal {
					break
				}
			}
			buf[i] = stepson
			head = stepson
			trail = pntz(p)
			shr(p[:], trail)
			pshift += trail
			trusty = false
			i += 1
		}
		if trusty {
			return
		}
		cycle(width, buf[:], i)
		sift(head, width, cmp, arg, pshift, lp)
	}

	size := nel * width
	if size == 0 {
		return
	}

	lp: [12*size_of(uint)]uint = ---
	lp[1] = width
	lp[0] = lp[1]
	for i := 2; true; i += 1 {
		lp[i] = lp[i-2] + lp[i-1] + width
		if lp[i] >= size {
			break
		}
	}

	head := base
	high := head[size - width:]
	p := [2]uint{1, 0}
	pshift := 1
	for head < high {
		if (p[0] & 3) == 3 {
			sift(head, width, cmp, arg, pshift, lp[:])
			shr(p[:], 2)
			pshift += 2
		} else {
			if lp[pshift - 1] >= uint(uintptr(high) - uintptr(head)) {
				trinkle(head, width, cmp, arg, p[:], pshift, false, lp[:])
			} else {
				sift(head, width, cmp, arg, pshift, lp[:])
			}
			if pshift == 1 {
				shl(p[:], 1)
				pshift = 0
			} else {
				shl(p[:], pshift - 1)
				pshift = 1
			}
		}
		p[0] |= 1
		head = head[width:]
	}
	trinkle(head, width, cmp, arg, p[:], pshift, false, lp[:])
	for pshift != 1 || p[0] != 1 || p[1] != 0 {
		if pshift <= 1 {
			trail := pntz(p)
			shr(p[:], trail)
			pshift += trail
		} else {
			shl(p[:], 2)
			pshift -= 2
			p[0] ~= 7
			shr(p[:], 1)
			trinkle(head[-width:][-lp[pshift]:], width, cmp, arg, p[:], pshift + 1, true, lp[:])
			shl(p[:], 1)
			p[0] |= 1
			trinkle(head[-width:], width, cmp, arg, p[:], pshift, true, lp[:])
		}
		head = head[-width:]
	}
}