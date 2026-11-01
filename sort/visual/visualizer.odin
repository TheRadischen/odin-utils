package sorting

import "base:intrinsics"
import "base:runtime"
import "core:math/rand"
import "core:strconv"
import "core:strconv/decimal"
import "core:reflect"
import "core:slice"
import "core:c"
import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:time"

TEST :: #config(TEST, false)

target_fps :: 60
INIT_WIDTH :: 1600
INIT_HEIGHT :: 900
camera : rl.Camera2D
target_ui : rl.RenderTexture2D
target_arr : rl.RenderTexture2D


Gui :: struct {
	screen: rl.Rectangle,
	scale: f32,
}
gui := Gui{{0,0,INIT_WIDTH,INIT_HEIGHT},1}
FONT_SIZE :: 20

pause, backward : bool = false, false

selected_sort: Sorts
selected_shuffle: Shuffles
selected_input: Inputs
selected_action: Action_Type = .Cmp
edit_input, edit_mod, edit_speed : bool
drop_sort, drop_shuffle, drop_input, drop_action: bool
is_drop_selected :: proc() -> bool {
	return drop_sort || drop_shuffle || drop_input || drop_action
}
sort_time : f64 = 6
sort_speed : f64 = 6
sorting_counter :f64= 0



Inputs :: enum c.int {
	Unique,
	Max_Range,
	Mod,
}

Shuffles :: enum c.int {
	Random,
	Ascending,
	Descending,
}


MAX_SIZE :: 100_000
input_size : int = 32

mod_input : int = 10

buf_input: [32]byte = {0 = 49,1..=2 = 48} // 100
buf_mod: [32]byte = {0 = 49,1 = 48} // 10
buf_speed: [32]byte = {0 = 54} // 60

Data :: struct {
	value: int, // to sort
	index: int, // stability
	cmp_count: int,
	move_count: int,
	time_stamp: int,
}
null_data := Data {0,-1,0,0,0}
max_value : int
stop_sort := false


backing_arr : []Data
backing_arr_swap : []Data
sort_arr : []Data
swap_arr: []Data
temp_arr: []Data

data_arr := [Arr_Type]^[]Data{
	.Main = &sort_arr,
	.Swap = &swap_arr,
	.Temp = &temp_arr,
}

initial_arr : []int

array_action: [dynamic]Arr_Action
action_index: int
action_index_target: int = -1
sorce_loc : map[Source][2]int
Source :: struct {
	name: string,
	line: i32,
}

sort_names_rl, shuffle_names_rl, input_names_rl, action_names_rl: cstring

main :: proc(){
	
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(INIT_WIDTH,INIT_HEIGHT,"Sorting")
	defer rl.CloseWindow()
	rl.SetTargetFPS(target_fps)
	rl.GuiSetStyle(.DEFAULT, 16, 15) // fontsize

	target_ui = rl.LoadRenderTexture(INIT_WIDTH, INIT_HEIGHT)
	target_arr = rl.LoadRenderTexture(INIT_WIDTH, INIT_HEIGHT - 200)

	sort_names := reflect.enum_field_names(Sorts)
	sort_names_joined := strings.join(sort_names, sep = ";", allocator = context.temp_allocator)
	sort_names_rl = strings.clone_to_cstring(sort_names_joined)

	shuffle_names := reflect.enum_field_names(Shuffles)
	shuffle_names_joined := strings.join(shuffle_names, sep = ";", allocator = context.temp_allocator)
	shuffle_names_rl = strings.clone_to_cstring(shuffle_names_joined)

	input_names := reflect.enum_field_names(Inputs)
	input_names_joined := strings.join(input_names, sep = ";", allocator = context.temp_allocator)
	input_names_rl = strings.clone_to_cstring(input_names_joined)

	action_names := reflect.enum_field_names(Action_Type)
	action_names_joined := strings.join(action_names, sep = ";", allocator = context.temp_allocator)
	action_names_rl = strings.clone_to_cstring(action_names_joined)
	
	backing_arr = make([]Data, MAX_SIZE)
	backing_arr_swap = make([]Data, MAX_SIZE)
	temp_arr = make([]Data, 10)
	sort_arr = backing_arr[:input_size]
	swap_arr = backing_arr_swap[:input_size]

	initial_arr = make([]int, MAX_SIZE)
	arr = make([]int, MAX_SIZE)
	aux = make([]int, MAX_SIZE)
	// temp_slice = make([]int, 10)

	// temp: ^int = &temp_slice[0]

	// input_gen()
	sort()
	// init_data_arr()
	// draw_arr()
	// sort()

	rl.ClearBackground(rl.BLACK)
	for !rl.WindowShouldClose() {
		ui_update()
	}
}

draw_arr :: proc(){
	rl.BeginTextureMode(target_arr)
		rl.ClearBackground(rl.BLACK)
		dist := INIT_WIDTH / f64(len(sort_arr))
		x :f64= 0
		if !uses_aux {
			for a, i in sort_arr {
				defer x += dist
				if a.index == -1 { continue }
				y := a.value * (INIT_HEIGHT - 200) / max_value
				color : rl.Color
				time_diff := action_index - a.time_stamp
				if time_diff > 10 * cast(int)sort_speed {
					color = rl.WHITE
				} else {
					color = rl.ColorLerp(rl.WHITE, rl.RED, 1- f32(time_diff) / (10 * cast(f32)sort_speed))
				}
				rl.DrawRectangle(i32(x),i32(y),5,5,color)
			}
		} else {
			for a, i in sort_arr {
				defer x += dist
				if a.index == -1 { continue }
				y := a.value * (INIT_HEIGHT - 200) / max_value / 2
				color : rl.Color
				time_diff := action_index - a.time_stamp
				if time_diff > 10 * cast(int)sort_speed {
					color = rl.WHITE
				} else {
					color = rl.ColorLerp(rl.WHITE, rl.RED, 1- f32(time_diff) / (10 * cast(f32)sort_speed))
				}
				rl.DrawRectangle(i32(x),i32(y),5,5,color)
			}
			x = 0
			for a, i in swap_arr {
				defer x += dist
				if a.index == -1 { continue }
				y := a.value * (INIT_HEIGHT - 200) / max_value / 2 + 350
				color : rl.Color
				time_diff := action_index - a.time_stamp
				if time_diff > 10 * cast(int)sort_speed {
					color = rl.WHITE
				} else {
					color = rl.ColorLerp(rl.WHITE, rl.RED, 1- f32(time_diff) / (10 * cast(f32)sort_speed))
				}
				rl.DrawRectangle(i32(x),i32(y),5,5,color)
			}
		}

	rl.EndTextureMode()
}

ui_update :: proc() {
		reset: {
			debug_messages = 0
		}


		resize: {
			window_width := cast(f32)rl.GetRenderWidth()
			window_height := cast(f32)rl.GetRenderHeight()
			if window_height != gui.screen.height || window_width != gui.screen.width {
				rl.UnloadRenderTexture(target_ui)
				target_ui = rl.LoadRenderTexture(rl.GetRenderWidth(), rl.GetRenderHeight())
				gui.screen.height = window_height
				gui.screen.width = window_width
				
			}
		}
	
		// init_data_arr()
		// draw_arr()

		update_arr: {
			if action_index_target != -1 {
				if action_index_target < action_index {
					for action_index_target < action_index {
						prev_frame()
					}
				} else {
					for action_index_target > action_index {
						next_frame()
					}
				}

				action_index_target = -1
				draw_arr()
				break update_arr
			}
			if pause { break update_arr }
			// #partial switch a in array_action[action_index] {
			// 	case Cmp:
			// 	case Move: {
			// 		data_arr[a.to][a.to_index] = data_arr[a.from][a.from_index]
			// 		data_arr[a.from][a.from_index] = null_data
			// 	}
			// 	case:
			// }
			// action_index += 1
			sorting_counter += sort_speed
			if !backward {
				for sorting_counter > 0 {
					next_frame()
					sorting_counter -= 1
				}
			} else {
				for sorting_counter > 0 {
					prev_frame()
					sorting_counter -= 1
				}
				// prev_frame()
			}
			draw_arr()
		}

		next_action :: proc(next: Action_Type) {
			for {
				type := next_frame()
				fmt.println(type, next, type == next)
				if type == nil || type == next {break}
			}
			draw_arr()
		}
		next_frame :: proc() -> (res: Action_Type = .Cmp) {
			if action_index >= len(array_action) { return .None }
			#partial switch a in array_action[action_index] {
				case Cmp: {
					data_arr[a.l][a.l_index].cmp_count += 1
					data_arr[a.r][a.r_index].cmp_count += 1
					data_arr[a.l][a.l_index].time_stamp = action_index
					data_arr[a.r][a.r_index].time_stamp = action_index
					res = .Cmp
					entry, ok := &sorce_loc[{a.loc.procedure, a.loc.line}]
					if !ok {
						sorce_loc[{a.loc.procedure, a.loc.line}] = {1,int(a.less)}
					} else {
						entry.x += 1
						entry.y += int(a.less)
					}
					// fmt.println(a.less, a.loc.line)
				}
				case Move: {
					data_arr[a.to][a.to_index] = data_arr[a.from][a.from_index]
					data_arr[a.from][a.from_index] = null_data
					data_arr[a.to][a.to_index].move_count += 1
					data_arr[a.to][a.to_index].time_stamp = action_index
					res = .Move
				}
				case Swap: {
					data_arr[a.l][a.li], data_arr[a.r][a.ri] = data_arr[a.r][a.ri], data_arr[a.l][a.li]
					data_arr[a.l][a.li].move_count += 1
					data_arr[a.r][a.ri].move_count += 1
					data_arr[a.l][a.li].time_stamp = action_index
					data_arr[a.r][a.ri].time_stamp = action_index
					res = .Swap
				}
				case: {
					panic("case not reachable")
				}
			}
			action_index += 1
			return
		}

		prev_action :: proc(prev: Action_Type) {
			for {
				type := prev_frame()
				if type == prev || type == .None {break}
			}
			draw_arr()
		}
		prev_frame :: proc() -> (res: Action_Type) {
			if action_index == 0 { return .None }
			action_index -= 1
			#partial switch a in array_action[action_index] {
				case Cmp: {
					res = .Cmp
					entry, ok := &sorce_loc[{a.loc.procedure, a.loc.line}]
					entry.x -= 1
					entry.y -= int(a.less)
					
				}
				case Move: {
					data_arr[a.from][a.from_index] = data_arr[a.to][a.to_index]
					data_arr[a.to][a.to_index] = null_data
					res = .Move
				}
				case Swap: {
					data_arr[a.l][a.li], data_arr[a.r][a.ri] = data_arr[a.r][a.ri], data_arr[a.l][a.li]
					res = .Swap
				}
				case:
			}
			return
		}

		draw_ui: {
			// if pause {
			// 	break draw_update
			// }
			rl.BeginTextureMode(target_ui)
			// rl.ClearBackground({33,22,10,255})
			rl.ClearBackground({0,0,0,0})


			ui_x :f32= 20

			
			draw_text(10, 70, "action: ", action_index)
			draw_text(10, 95, "comps: ", comps, " / n log n ", f64(comps) / f64(input_size * log2(input_size)))
			draw_text(10, 120, "moves: ", moves, " / n log n ", f64(moves) / f64(input_size * log2(input_size)))

			slider_rec := rl.Rectangle{0,150,1600,50}
			slider_rec2 := rl.Rectangle{2,152,1596,46}
			rl.DrawRectangleRec(slider_rec, rl.GREEN)
			rl.DrawRectangleRec(slider_rec2, rl.BLACK)
			if mpos := rl.GetMousePosition(); rl.CheckCollisionPointRec(mpos, slider_rec2) && !is_drop_selected()  {
				rl.DrawRectangleRec(slider_rec2, rl.DARKGRAY)
				mx := i32(mpos.x)
				rl.DrawLine(mx,152,mx,198,rl.RED)
				draw_debug("mpos", mpos)
				draw_debug("len actions", len(array_action))
				goal := int(((mpos.x) / 1600) * cast(f32)len(array_action))
				draw_text(clamp(mx,10,1500), 120, goal)
					draw_debug("index",action_index)
				if rl.IsMouseButtonDown(.LEFT) {
					action_index_target = goal
					draw_debug("goal",action_index_target)
				}
			}
			action_x := c.int(action_index * 1600 / len(array_action))
			rl.DrawLine(action_x,152,action_x,198,rl.RED)


			if rl.GuiDropdownBox({ui_x,20,100,50}, sort_names_rl, cast(^c.int)&selected_sort, drop_sort) {
				drop_sort = !drop_sort
				if !drop_sort {
					fmt.println(selected_sort)
					sort()
				}
			}

			if rl.GuiDropdownBox({add(&ui_x, 120),20,100,50}, shuffle_names_rl, cast(^c.int)&selected_shuffle, drop_shuffle) {
				drop_shuffle = !drop_shuffle
				if !drop_shuffle { 
					fmt.println(selected_shuffle)
					sort()
				}
			}

			add(&ui_x, 120)
			if selected_input == .Mod {
				if rl.GuiTextBox({ui_x,70,100,50}, text=transmute(cstring)(&buf_mod), textSize = 10, editMode = edit_mod) {
					edit_mod = !edit_mod
					if !edit_mod {
						mod_input = 0
						for b in buf_mod {
							if b == 0 { break }
							mod_input = mod_input * 10 + int(b) - 48
						}
						mod_input = min(input_size, mod_input)
					}
					sort()
				}
			}
			
			if rl.GuiDropdownBox({ui_x,20,100,50}, input_names_rl, cast(^c.int)&selected_input, drop_input) {
				drop_input = !drop_input
				if !drop_input { 
					fmt.println(selected_input)
					sort()
				}
			}

			add(&ui_x, 120)
			if rl.GuiButton({ui_x,70,50,30},"<") && !is_drop_selected() {
				pause = true
				prev_action(selected_action)
			}
			if rl.GuiButton({ui_x + 50,70,50,30},">") && !is_drop_selected()  {
				pause = true
				next_action(selected_action)
			}
			if rl.GuiDropdownBox({ui_x,20,100,50}, action_names_rl, cast(^c.int)&selected_action, drop_action) {
				drop_action = !drop_action
				if !drop_action { 
					// selected_action = transmute(Action_Type)(transmute(c.int)selected_action + 1)
					fmt.println(selected_action)
				}
			}


			rl.GuiLabel({add(&ui_x, 120),0,50,20},"Size")
			if rl.GuiTextBox({ui_x,20,100,50}, text=transmute(cstring)(&buf_input), textSize = 10, editMode = edit_input) {
				edit_input = !edit_input
				if !edit_input {
					sort()
				// 	input_size = 0
				// 	for b in buf_input {
				// 		if b == 0 { break }
				// 		input_size = input_size * 10 + int(b) - 48
				// 	}
				// 	sort_arr = backing_arr[:input_size]
				// 	swap_arr = backing_arr_swap[:input_size]
				// 	input_gen()
				}
			}

			rl.GuiLabel({add(&ui_x, 120),0,100,20},"Speed in sec")
			if rl.GuiTextBox({ui_x,20,100,50}, text=transmute(cstring)(&buf_speed), textSize = 10, editMode = edit_speed) {
				edit_speed = !edit_speed
				if !edit_speed {
					sort_time = 0
					for b in buf_speed {
						if b == 0 { break }
						sort_time = sort_time * 10 + f64(b) - 48
					}
					sort_time = clamp(sort_time, 1, 100_000)
					// calc_speed()
				}
			}

			draw_debug("size: ", input_size)
			draw_debug("mod: ", mod_input)
			draw_debug("max",max_value)
			draw_debug("lwngth",len(sort_arr))
			draw_debug("speed", sort_speed)
			// draw_debug("arr visual",sort_arr[:10])
			// draw_debug("arr ini",initial_arr[:10])
			// draw_debug("arr ",arr[:10])

			for key, value in sorce_loc {
				draw_debug(key, f64(value.y) / f64(value.x))
			}

			rl.DrawText("backward" if backward else "forward", 1210, 20, FONT_SIZE, rl.YELLOW if backward else rl.GREEN)
			if rl.GuiButton({1300, 0, 100, 50}, "Forward") {
				backward = !backward
			}

			rl.DrawText("Paused" if pause else "Playing", 1410, 20, FONT_SIZE, rl.RED if pause else rl.GREEN)
			if rl.GuiButton({1500, 0, 100, 50}, "Pause") {
				pause = !pause
			}



			rl.EndTextureMode()
		}

		button_input: {
			for {
				key := rl.GetKeyPressed()
				if key == .KEY_NULL { break }

				
				#partial switch key {
					case .P: pause = !pause
					case .N: selected_sort = Sorts((cast(c.int)selected_sort + 1) % len(Sorts)); sort()
				}
			}
		}



	   	// copy_texture: {
		// 	rl.BeginDrawing()
		// 	rl.ClearBackground(rl.BLACK)
		// 	source := gui.screen
		// 	source.height *= -1
		// 	rl.DrawTexturePro(target_ui.texture, source, gui.screen, {0,0}, 0.0, rl.WHITE)
		// 	arr_dest := gui.screen
		// 	arr_dest.height -= 200
		// 	arr_dest.y += 200
		// 	s : rl.Rectangle
		// 	s.height = cast(f32)target_arr.texture.height
		// 	s.width = cast(f32)target_arr.texture.width
		// 	rl.DrawTexture(target_arr.texture,0,200,rl.WHITE)
		// 	rl.DrawTexturePro(target_arr.texture, s, arr_dest, {0,0}, 0.0, rl.WHITE)
		// 	rl.DrawFPS(20,30)
		// 	rl.EndDrawing()
		// }
	   	copy_texture: {
			rl.BeginDrawing()
			rl.ClearBackground(rl.BLACK)
			rl.DrawTexture(target_arr.texture,0,200,rl.WHITE)
			source := gui.screen
			source.height *= -1
			rl.DrawTexturePro(target_ui.texture, source, gui.screen, {0,0}, 0.0, rl.WHITE)
			rl.DrawFPS(20,30)
			rl.EndDrawing()
		}


		free_all(context.temp_allocator)
		if rl.WindowShouldClose() {rl.CloseWindow()}
}

add :: proc(base: ^$T, adder: T) -> T {
	base^ += adder
	return base^
}

debug_messages : c.int
draw_debug :: proc(text: ..any) {
	draw_text(800, 10 + 20 * debug_messages, ..text)
	debug_messages += 1
}

draw_text :: proc(x, y: c.int, text: ..any) {
	rl.DrawText(
		strings.clone_to_cstring(
			fmt.aprint(..text, allocator = context.temp_allocator),
			allocator = context.temp_allocator
		),
		x, y, FONT_SIZE, rl.WHITE
	)
}

rect_split_left_right :: proc(rect: rl.Rectangle, p: f32) -> (left, right: rl.Rectangle) {
	left = rect
	right = rect
	left.width = rect.width * p
	right.width = rect.width * (1 - p)
	right.x -= left.width
	return
}

rect_split_top_bottom :: proc(rect: rl.Rectangle, p: f32) -> (top, bottom: rl.Rectangle) {
	top = rect
	bottom = rect
	top.height = rect.height * p
	bottom.height = rect.height * (1 - p)
	bottom.x -= top.height
	return
}


is_sorted_data :: proc(arr: []Data) -> bool {
	for i in 1..<len(arr) {
		if arr[i - 1].value > arr[i].value { return false }
	}
	return true
}
is_sorted_int :: proc(arr: []int) -> bool {
	for i in 1..<len(arr) {
		if arr[i - 1] > arr[i] { return false }
	}
	return true
}

is_sorted_stable_data :: proc(arr: []Data) -> (sorted: bool = true, stable: bool = true) {
	for i in 1..<len(arr) {
		if arr[i - 1].value < arr[i].value { continue }
		if arr[i - 1].value > arr[i].value { sorted = false; break }
		if arr[i - 1].index > arr[i].index { stable = false }
	}
	return 
}

input_gen :: proc() {
	arr := arr[:input_size]
	switch selected_input {
		case .Unique: {
			for &a, i in arr {
				a = i
			}
			max_value = len(arr)
		}
		case .Max_Range: {
			div := cast(int)max(i32) / len(arr)
			for &a, i in arr {
				a = i * div
			}
			max_value = cast(int)max(i32)
		}
		case .Mod: {
			add := f64(mod_input) / f64(len(arr))
			for &a, i in arr {
				a = int(add * f64(i))
			}
			max_value = mod_input
		}
	}
	shuffle()
}

shuffle :: proc() {
	arr := arr[:input_size]
	switch selected_shuffle {
		case .Random: {
			for i in 0..<len(arr) {
				goal := rand.int_max(len(arr))
				arr[i], arr[goal] = arr[goal], arr[i]
			}
		}
		case .Ascending: {
			slice.sort(arr)
		}
		case .Descending: {
			slice.reverse_sort(arr)
		}
	}
	copy(initial_arr, arr)
	init_data_arr()
	draw_arr()
	// sort()
}

max_len := [Sorts]int{
	.Network = 32,
	.Stupid = 1000,
	.Selection_opt = 1000,
	.Selection = 1000,
	.Selection_double = 1000,
	.Cycle = 1000,
	.Bubble = 1000,
	.Odd_even = 1000,
	.Insertion = 1000,
	.Insert_bin = 2_000,
	.Circle = 20_000,
	.Heap = 100_000,
	.Shell = 100_000,
	.Comb = 100_000,
	.Quicksort_LL = 100_000,
	.Quicksort_LR = 100_000,
	.Pingpong = 100_000,
	.Merge_rotate = 100_000,
	.Min_lomuto = 100_000,
}

Sorts :: enum c.int {
	Network,
	Min_lomuto,
	Stupid,
	Selection_opt,
	Selection,
	Selection_double,
	Cycle,
	Bubble,
	Odd_even,
	Insertion,
	Insert_bin,
	Heap,
	Shell,
	Merge_rotate,
	Comb,
	Circle,
	Quicksort_LL,
	Quicksort_LR,
	Pingpong,
}

uses_aux := false
moves := 0
comps := 0
sort :: proc() {
	fmt.println("sorting algo", selected_sort)
	
	input_size = 0
	for b in buf_input {
		if b == 0 { break }
		input_size = input_size * 10 + int(b) - 48
	}
	input_size = min(input_size, max_len[selected_sort])
	sort_arr = backing_arr[:input_size]
	swap_arr = backing_arr_swap[:input_size]
	input_gen()
	arr := arr[:input_size]

	copy(initial_arr, arr)
	clear(&array_action)
	clear(&sorce_loc)
	action_index = 0
	moves = 0
	comps = 0

	uses_aux = false


	switch selected_sort {
		case .Network: networks(arr)
		case .Stupid: stupid_sort(arr)
		case .Selection_opt: selection_optimized_sort(arr)
		case .Selection: selection_sort(arr)
		case .Selection_double: selection_double(arr)
		case .Cycle: cycle_sort(arr)
		case .Bubble: bubble_sort(arr)
		case .Odd_even: odd_even(arr)
		case .Heap: heap_sort(arr)
		case .Shell: shell_sort(arr)
		case .Comb: comb_sort(arr)
		case .Circle: circle_sort(arr)
		case .Insertion: insertion_sort(arr)
		case .Insert_bin: insertion_sort_binary(arr)
		case .Quicksort_LL: quick_sort_ll(arr)
		case .Quicksort_LR: quick_sort_lr(arr)
		case .Min_lomuto: sort_inlined(arr)
		case .Pingpong: pipo_sort(arr, aux); uses_aux = true
		case .Merge_rotate: merge_rotate(arr)
	}

	sort_speed = cast(f64)len(array_action) / (sort_time * 60)
	init_data_arr()
}

calc_speed :: proc() {
	sort_speed = cast(f64)len(array_action) / (sort_time * 60)
}

init_data_arr :: proc() {
	for &a, i in sort_arr {
		a.cmp_count = 0
		a.move_count = 0
		a.index = i
		a.value = initial_arr[i]
	}
	for &a, i in swap_arr {
		a.cmp_count = 0
		a.move_count = 0
		a.index = -1
		a.value = 0
	}

}
// random_data :: proc(size: int) -> (res: []Data) {
// 	res = make([]Data, size)
// 	for &a, i in &res {
// 		a.value = rand.int_max(size)
// 		a.index = i
// 	}
// 	return
// }
random_int :: proc(size: int) -> (res: []int) {
	res = make([]int, size)
	for &a in &res {
		a = rand.int_max(size)
	}
	return
}


Arr_Action :: union {
	Cmp,
	Move,
	Swap,
	Block_swap,
	Rotation,
	Reverse,
}
Cmp :: struct {
	l: Arr_Type,
	l_index: int,
	r: Arr_Type,
	r_index: int,
	less: bool,
	loc: runtime.Source_Code_Location,
}
Move :: struct {
	to: Arr_Type,
	to_index: int,
	from: Arr_Type,
	from_index: int,
}
Swap :: struct {
	l: Arr_Type,
	li: int,
	r: Arr_Type,
	ri: int,
}
Block_swap :: struct {
	l: Arr_Type,
	l_index1: int,
	l_index2: int,
	r: Arr_Type,
	r_index1: int,
	r_index2: int,
}
Rotation :: struct {
	array: Arr_Type,
	from: int,
	mid: int,
	to: int,
}
Reverse :: struct {
	array: Arr_Type,
	from: int,
	to: int,
}
Action_Type :: enum c.int {
	None,
	Cmp,
	Move,
	Swap,
}

// array := [Arr_Type]^[]int {
// 	.Main = &arr,
// 	.Swap = &aux,
// 	.Temp = &temp_slice,
// }

Arr_Type :: enum {
	Main,
	Swap,
	Temp,
}


// move :: proc(to: Arr_Type, ti: int, from: Arr_Type, fi: int) {
// 	when !TEST {
// 		append(&array_action, Move{
// 			to, ti, from, fi
// 		})
// 	}
// 	array[to][ti] = array[from][fi]
// }

// swap :: proc(l: Arr_Type, li: int, r: Arr_Type, ri: int) {
// 	when !TEST {
// 		append(&array_action, Swap{
// 			l, li, r, ri
// 		})
// 	}
// 	array[l][li], array[r][ri] = array[r][ri], array[l][li]
// }

// less :: proc(la: Arr_Type, li: int, ra: Arr_Type, ri: int, loc := #caller_location) -> (res: bool) {
// 	res = array[la][li] < array[ra][ri]

// 	when !TEST {
// 		append(&array_action, Cmp{
// 			la, li, ra, ri, res, loc
// 		})
// 	}

// 	return 
// }