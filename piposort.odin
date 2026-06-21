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

MIN_ODD_EVEN :: 7

piposort :: proc(arr: $A , cmp: proc($T,T)->bool){
    swap := make_slice([]T, len(arr))
    ping_pong_merge(arr,swap,cmp)
    delete(swap)
}
insertion_sort_cmp :: proc(arr: $A, cmp: proc($T, T) -> bool) {
    for i in 1..<len(arr) {
        x := arr[i]
        j := i
        for ; j > 0 && cmp(arr[j - 1],x ); j -= 1 {
            arr[j] = arr[j - 1]
        }
        arr[j] = x
    }
}
ping_pong_merge :: proc(arr, swap: $A, cmp: proc($T,T)->bool){
    n := len(arr)
    if n <= MIN_ODD_EVEN {
        insertion_sort_cmp(arr,cmp)
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

    if !cmp(arr[quad1 - 1],arr[quad1]) &&
       !cmp(arr[half1 - 1], arr[half1]) &&
       !cmp(arr[half1 + quad3 - 1], arr[half1 + quad3]) {
        return
    }

    if cmp(arr[0], arr[half1 - 1]) && 
       cmp(arr[quad1], arr[half1 + quad3 - 1]) &&
       cmp(arr[half1], arr[len(arr) - 1]) {
        aux_rotation(arr,swap,quad1,quad2+half2)
        aux_rotation(arr,swap,quad2,half2)
        aux_rotation(arr,swap,quad3,quad4)
        return
    }

    oddeven_parity_merge(arr, swap, quad1, quad2, cmp)
    oddeven_parity_merge(arr[half1:], swap[half1:],quad3, quad4, cmp)
    oddeven_parity_merge(swap,arr, half1, half2, cmp)

}
oddeven_parity_merge :: proc(from, dest: $A, left, right: int, greater: proc($T,T)-> bool){

    dest := dest; from := from
    
    ptl := 0
    ptr := left
    ptd := 0 
    tpl := ptr - 1
    tpr := tpl + right
    tpd := left + right - 1

    if left < right {
        dest[ptd] = !greater(from[ptl],from[ptr]) ? pp(from, &ptl, T) : pp(from, &ptr, T); ptd += 1    
    }
    dest[ptd] = !greater(from[ptl],from[ptr]) ? pp(from, &ptl, T) : pp(from, &ptr, T); ptd += 1

    for left := left - 1; left > 0; left -= 1 {
        dest[ptd] = !greater(from[ptl],from[ptr]) ? pp(from, &ptl, T) : pp(from, &ptr, T); ptd += 1
        dest[tpd] = greater(from[tpl],from[tpr]) ? nn(from, &tpl, T) : nn(from, &tpr, T); tpd -= 1
    }
    
    dest[tpd] = greater(from[tpl],from[tpr]) ? from[tpl] : from[tpr]
}
pp :: #force_inline proc(arr: $A, pointer: ^int, $T: typeid) -> T #no_bounds_check {
    res := arr[pointer^]
    pointer^ += 1
    return res
}
nn :: #force_inline proc(arr: $A, pointer: ^int, $T: typeid) -> T #no_bounds_check {
    res := arr[pointer^]
    pointer^ -= 1
    return res
}


aux_rotation :: proc(arr,swap: $A,left, right: int){
    copy(swap,arr[:left])
    copy(arr,arr[left:][:right])
    copy(arr[right:],swap[:left])
}
