package piposort

/*
	Copyright (C) 2014-2022 Igor van den Hoven ivdhoven@gmail.com
*/

/*
	Permission is hereby granted, free of charge, to any person obtaining
	a copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
	piposort 1.1.5.4
*/


// stable sort, uses O(n) memory
piposort :: proc(arr: $A/[]$T , cmp: proc(T,T)->bool){
    swap := make_slice([]T, len(arr))
    ping_pong_merge(arr,swap,cmp)
    delete(swap)
}

ping_pong_merge :: proc(arr, swap: $A/[]$T, cmp: proc(T,T)->bool){
    n := len(arr)
    if n <= 7 {
        branchless_odd_even_sort(arr, cmp)
        return
    }

    half1 := n >> 1
    quad1 := half1 >> 1
    quad2 := half1 - quad1
    half2 := n - half1
    quad3 := half2 >> 1
    quad4 := half2 - quad3

    ping_pong_merge(arr[:quad1],swap,cmp)
    ping_pong_merge(arr[quad1:][:quad2],swap,cmp)
    ping_pong_merge(arr[half1:][:quad3],swap,cmp)
    ping_pong_merge(arr[half1 + quad3:],swap,cmp)

    if !cmp(arr[quad1 - 1],arr[quad1]) && !cmp(arr[half1 - 1], arr[half1]) && !cmp(arr[half1 + quad3 - 1], arr[half1 + quad3]) {
        return
    }

    if cmp(arr[0], arr[half1 - 1]) && cmp(arr[quad1], arr[half1 + quad3 - 1]) && cmp(arr[half1], arr[len(arr) - 1]) {
        aux_rotation(arr,swap,quad1,quad2+half2)
        aux_rotation(arr,swap,quad2,half2)
        aux_rotation(arr,swap,quad3,quad4)
        return
    }

    oddeven_parity_merge(arr, swap, quad1, quad2, cmp)
    oddeven_parity_merge(arr[half1:], swap[half1:],quad3, quad4, cmp)
    oddeven_parity_merge(swap,arr, half1, half2, cmp)

}
oddeven_parity_merge :: proc(from, dest: $A/[]$T,left,right: int, cmp: proc(T, T) -> bool){
    left := left
    right := right
    ptl := ptr_slice(from)
    ptr := ptr_slice(from) + uintptr(left) * size_of(T)
    ptd := ptr_slice(dest)

    tpl := ptr_slice(from) + uintptr(left - 1)  * size_of(T)
    tpr := ptr_slice(from) + uintptr(left + right - 1) * size_of(T)
    tpd := ptr_slice(dest) + uintptr(left + right - 1) * size_of(T)

    if left < right {
        if !cmp(a0(ptl,T),a0(ptr,T)) {
            p0(ptd,T)^ = a0(ptl,T)
            ptl += size_of(T)
        } else {
            p0(ptd,T)^ = a0(ptr,T)
            ptr += size_of(T)
        }
        ptd += size_of(T)
    }

    x : int
    for left -= 1;left > 0;left -= 1 {
        x = cast(int)!cmp(a0(ptl,T),a0(ptr,T))
        p0(ptd,T)^ = a0(ptl,T)
        ptl += cast(uintptr)x * size_of(T)
        p(ptd,x,T)^ = a0(ptr,T)
        ptr += cast(uintptr)(1 - x) * size_of(T)
        ptd += cast(uintptr)size_of(T)
        
        x = cast(int)!cmp(a0(tpl,T),a0(tpr,T))
        p0(tpd,T)^ = a0(tpl,T)
        tpl -= cast(uintptr)(1 - x) * size_of(T)
        tpd -= cast(uintptr)size_of(T)
        p(tpd,x,T)^ = a0(tpr,T)
        tpr -= cast(uintptr)x * size_of(T)
    }
    p0(tpd, T)^ = cmp(a0(tpl,T),a0(tpr,T)) ? a0(tpl, T) : a0(tpr, T)
    p0(ptd, T)^ = !cmp(a0(ptl,T),a0(ptr,T)) ? a0(ptl, T) : a0(ptr, T)

}

ptr_slice :: proc(arr: $A/[]$T) -> uintptr {
    return uintptr(raw_data(arr))
}

aux_rotation :: proc(arr,swap: $A/[]$T,left, right: int){
    copy(swap,arr[:left])
    copy(arr,arr[left:][:right])
    copy(arr[right:],swap[:left])
}

branchless_odd_even_sort :: proc(a: $A/[]$T, cmp: proc(T,T)->bool){
    switch len(a){
        case:
            w := 1
            z :uintptr=1
            n := len(a)
            arr_ptr := uintptr(raw_data(a))
            pte := arr_ptr + (uintptr(n) - 3) * size_of(T)
            for {
                z = 1 - z
                pta := pte + z * size_of(T)
                for {
                
                    x := cast(int)cmp(arr(pta,0,T),arr(pta,1,T))
                    y := 1 - x
                    swap := arr(pta,y, T)
                    p(pta,0, T)^ = arr(pta,x, T)
                    p(pta,1, T)^ = swap
                    pta -= 2 * size_of(T)
                    w |= x
                    if pta < arr_ptr do break
                }
                n -= 1
                if w < 1 && n < 1 do break
                w -= 1
            }
            
            return
        case 3:
            x := u8(cmp(a[0],a[1]))
            y := 1 - x
            temp := a[y]
            a[0] = a[x]
            a[1] = temp
            b := a[1:]
            x = u8(cmp(b[0],b[1]))
            y = 1 - x
            temp = b[y]
            b[0] = b[x]
            b[1] = temp
            
            x = u8(cmp(a[0],a[1]))
            y = 1 - x
            temp = a[y]
            a[0] = a[x]
            a[1] = temp
        case 2:
            x := u8(cmp(a[0],a[1]))
            y := 1 - x
            temp := a[y]
            a[0] = a[x]
            a[1] = temp
            return
        case 1:
        case 0:
            return
    }
}
arr :: #force_inline proc(ptr: uintptr, index: int, $T: typeid) -> T {
	offset := cast(uintptr)(index * size_of(T))
	return (^T)(ptr + offset)^
}
a0 :: proc(ptr: uintptr, $T: typeid) -> T {
	return (^T)(ptr)^
}
p :: #force_inline proc(ptr: uintptr, index: int, $T: typeid) -> ^T {
	offset := cast(uintptr)(index * size_of(T))
	return (^T)(ptr + offset)
}
p0 :: #force_inline proc(ptr: uintptr, $T: typeid) -> ^T {
	return (^T)(ptr)
}
