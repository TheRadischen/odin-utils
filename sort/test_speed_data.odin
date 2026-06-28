package blit


import "core:strings"
import "core:math/linalg"

import "core:slice"
import "core:time"
import rl "vendor:raylib"
import "core:fmt"




times : [3][dynamic]f64
sizes : [dynamic]i32
main :: proc(){

    for i :f64= 20; i <= 1_000_000; i *= 1.9 {
        visual_test(int(i)-0)
    }

    draw()
}
max_time : f64
visual_test :: proc(size: int){
    append(&sizes, cast(i32)size)
    
    min_time_blit :time.Duration=time.MAX_DURATION
    min_time_slice :time.Duration=time.MAX_DURATION
    min_time_quad :time.Duration=time.MAX_DURATION
    swap := make([]Data,size)
    defer delete(swap)

    iterations := max(2, 500_000 / size)

    for _ in 0..<iterations {
        arr := rand_Data_10(size)
        // arr2 := rand_Data_soa(size)
        // arr3 := rand_Data(size)

        arr2 := slice.clone(arr)
        arr3 := slice.clone(arr)
        defer delete(arr)
        defer delete(arr2)
        defer delete(arr3)
        
        start := time.tick_now()
        blitsort(arr, greater_data)
        dur := time.tick_since(start)

        start = time.tick_now()
        quadsort_swap(arr2, swap, greater_data)
        dur2 := time.tick_since(start)

        start = time.tick_now()
        slice.sort_by(arr3, proc(l,r:Data)->bool{return l.rand < r.rand})
        dur3 := time.tick_since(start)

        min_time_blit = min(min_time_blit, dur)
        min_time_slice = min(min_time_slice, dur2)
        min_time_quad = min(min_time_quad, dur3)

        // if !is_sorted_data(arr) {fmt.println("blit fail")} 
        // if !is_sorted_data(arr2) do fmt.println("quad fail")
        // if !is_sorted_data(arr3) do fmt.println("slice fail")
    }
    t0 := nlogn(size, min_time_blit)
    t1 := nlogn(size, min_time_slice)
    t2 := nlogn(size, min_time_quad)
    fmt.println(size, min_time_blit, min_time_slice, min_time_quad)
    max_time = max(max_time,t0,t1,t2)
    append(&times[0], t0)
    append(&times[1], t1)
    append(&times[2], t2)
}
greater_data :: proc(l, r: Data) -> bool {
    return l.rand > r.rand
}

custom_print :: proc(args: ..any){}
counter := 0
greater :: proc(l, r: int) -> bool {
    return l > r
}
nlogn :: proc(n:int,t : time.Duration) -> f64 {
    t := f64(t)
    n := f64(n)
    t = t / linalg.log2(n) / n
    return t
}


GAME_SCREEN_WIDTH :: 1080
GAME_SCREEN_HEIGHT :: 720

draw :: proc(){

    init()

    for !rl.WindowShouldClose(){
        rl.BeginDrawing()

            rl.ClearBackground(rl.BLACK)

            n := len(times[0])
            height := (GAME_SCREEN_HEIGHT-40) / max_time
            step := (GAME_SCREEN_WIDTH - 40) / f64(n)
            base_height :: GAME_SCREEN_HEIGHT-40

            max_time = min(max_time, 100)
            step_time :f64= max_time > 20 ? 5 : 1
            for i:f64= 0; i < max_time; i+= step_time {
                h := i32(base_height-i*height)
                rl.DrawLine(0,h,GAME_SCREEN_WIDTH-40,h,rl.WHITE)
                rl.DrawText(strings.clone_to_cstring(fmt.aprint(i)),GAME_SCREEN_WIDTH-35,h,20,rl.WHITE)
            }
            
            right :f64= 1
            for i in 0..<n-1 {
                rl.DrawLine(i32(right),base_height-cast(i32)(times[0][i]*height),i32(right+step),base_height-cast(i32)(times[0][i+1]*height),rl.RED)
                rl.DrawLine(i32(right),base_height-cast(i32)(times[1][i]*height),i32(right+step),base_height-cast(i32)(times[1][i+1]*height),rl.YELLOW)
                rl.DrawLine(i32(right),base_height-cast(i32)(times[2][i]*height),i32(right+step),base_height-cast(i32)(times[2][i+1]*height),rl.BLUE)
                right += step
                rl.DrawText(strings.clone_to_cstring(fmt.aprint(sizes[i])),i32(right),10+i32((i%3)*30),25,rl.LIGHTGRAY)
            }

            rl.DrawText("1 Blitsort",100,50,30,rl.RED)
            rl.DrawText("2 Quadsort",100,80,30,rl.YELLOW)
            rl.DrawText("3 slice.sort()",100,110,30,rl.BLUE)

            rl.EndDrawing()
        }
}
init :: proc(){
    rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
    rl.InitWindow(GAME_SCREEN_WIDTH,GAME_SCREEN_HEIGHT,"sort")
    rl.SetTargetFPS(1)
}