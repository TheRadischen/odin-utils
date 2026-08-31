package msort

import "core:sort"
import "core:time"
import "core:slice"
import "core:math/rand"
import "core:fmt"
main :: proc(){
	T :: u16
	Data :: struct {
		data2: int,
		rand: T,
		data: [1]int,
	}
	arr := make([]Data, 100_000)
	// arr := []u32{9,8,7,6,5,4,3,2,1}

	
	mint := time.MAX_DURATION
	for i in 0..<100 {
		for &a in arr {
			a.rand = cast(T) rand.uint64()
		}
			
		start := time.tick_now()
		// radix_generic_by(arr, proc(t: ^Data) -> ^T {return &t.rand} )
		sort.sort_inlined_by(arr, proc(l,r: Data)->bool{return l.rand < r.rand})
		
		dur := time.tick_since(start)

		mint = min(mint, dur)
	}
	// fmt.println(arr)
	// fmt.println(arr)
	fmt.println(slice.is_sorted_by(arr, proc(l,r: Data)->bool{return l.rand < r.rand}), mint)
}