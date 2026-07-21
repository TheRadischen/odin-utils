package basic

import "base:intrinsics"


dist :: proc(high, low: [^]byte) -> int{
	return int(uintptr(high) - uintptr(low))
}



trinity_rotation_clean :: proc(arr: [^]byte, left, right: int) {
	SWAP_SIZE :: 64
	SWAP_SIZE_2 :: SWAP_SIZE * 2
	SWAP_SIZE_4 :: SWAP_SIZE_2 * 2
	swap : [4][SWAP_SIZE]byte
	pta_read, pta_write, pta, ptb, ptc, ptd, ptd_read, ptd_write, start: [^]byte
	start = arr

    right := right
    left := left
	// SWAP_SIZE :: 2
	// SWAP_SIZE_2 :: SWAP_SIZE * 2
	// SWAP_SIZE_4 :: SWAP_SIZE_2 * 2
	// swap : [4][SWAP_SIZE]byte = ---
	// d_swap := &swap[SWAP_SIZE_2]
	// a_swap := &swap[SWAP_SIZE]
    

    if left < right {
        if left <= SWAP_SIZE_4 {	
			intrinsics.mem_copy(&swap, arr, left)
			intrinsics.mem_copy(arr, arr[left:], right)
			intrinsics.mem_copy(arr[right:], &swap, left)
        } else {
            // pta, ptb, ptc, ptd : [^]byte
			pta = arr
            ptb = arr[left:]
            loop := right - left

            if loop <= SWAP_SIZE_4 && loop > 0 {
                ptc = arr[right:]
                ptd = ptc[left:]



                intrinsics.mem_copy(&swap, ptb, loop)

                for ; left >= loop; left -= loop {
					ptc = ptc[-loop:]
					ptd = ptd[-loop:]
					intrinsics.mem_copy(ptc,ptd,loop)
					ptb = ptb[-loop:]
					intrinsics.mem_copy(ptd,ptb,loop)
                }
				if left != 0 {
					ptc = ptc[-left:]
					ptd = ptd[-left:]
					intrinsics.mem_copy(ptc,ptd,left)
					ptb = ptb[-left:]
					intrinsics.mem_copy(ptd,ptb,left)
					left -= left
				}

                intrinsics.mem_copy(pta, &swap, loop)

            } else {
                ptc = ptb
                ptd = ptc[right:] // end


				// Phase 1
                loop: = left / 2

                for ; loop >= SWAP_SIZE; loop -= SWAP_SIZE {
					ptb = ptb[-SWAP_SIZE:]
					ptd = ptd[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap, ptb, SWAP_SIZE)
					intrinsics.mem_copy(ptb, pta, SWAP_SIZE)
					intrinsics.mem_copy(pta, ptc, SWAP_SIZE)
					intrinsics.mem_copy(ptc, ptd, SWAP_SIZE)
					intrinsics.mem_copy(ptd, &swap, SWAP_SIZE)
					ptc = ptc[SWAP_SIZE:]
					pta = pta[SWAP_SIZE:]
                }


				pta_write = pta
				pta_read = pta

				ptd_write = ptd
				ptd_read = ptd

				rest := dist(ptb, pta)
	


				// a and d have gaps,
				// d is in swap
				// d -> c -> a -> d
				if rest > SWAP_SIZE {
					ptd_read = ptd_read[-SWAP_SIZE_2:]
					intrinsics.mem_copy(&swap, ptd_read, SWAP_SIZE_2)

					ptd_write = ptd_write[-rest:]
					intrinsics.mem_copy(ptd_write, pta_read, rest)
					pta_read = pta_read[rest:]

					intrinsics.mem_copy(pta_write, ptc, SWAP_SIZE)
					pta_write = pta_write[SWAP_SIZE:]

					intrinsics.mem_copy(ptc, &swap[1], SWAP_SIZE)
					ptc = ptc[SWAP_SIZE:]
				} else {
					ptd_read = ptd_read[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap, ptd_read, SWAP_SIZE)

					ptd_write = ptd_write[-rest:]
					intrinsics.mem_copy(ptd_write, pta_read, rest)
					pta_read = pta_read[rest:]
				}

				// swap[0] is d
				// d -> c -> a -> d

	
				swap_mem := 1


				// phase 2
				loop = dist(ptd_read, ptc) / 2

				// print(arr,length,1)
                for ; loop >= SWAP_SIZE; loop -= SWAP_SIZE {	
					ptd_read = ptd_read[-SWAP_SIZE:]
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap[swap_mem], ptd_read, SWAP_SIZE) // d [swap_mem]
					intrinsics.mem_copy(ptd_write, pta_read, SWAP_SIZE)
					intrinsics.mem_copy(pta_write, ptc, SWAP_SIZE)
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(ptc, &swap[swap_mem], SWAP_SIZE)
					ptc = ptc[SWAP_SIZE:]
					pta_read = pta_read[SWAP_SIZE:]
					pta_write = pta_write[SWAP_SIZE:]
                }	
                
				rest = dist(ptd_read, ptc)


				// a and d have gaps,
				// d is in swap
				// a also in swap
				a_swap1 := &swap[2]
				a_swap2 := &swap[3]
				if rest > SWAP_SIZE {		
					intrinsics.mem_copy(a_swap2, pta_read, SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]
					intrinsics.mem_copy(a_swap1, pta_read, SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]

					ptd_read = ptd_read[-rest:]
					intrinsics.mem_copy(pta_write, ptd_read, rest)
					pta_write = pta_write[rest:]

					intrinsics.mem_copy(&swap[swap_mem], pta_read, SWAP_SIZE) // put a in
					pta_read = pta_read[SWAP_SIZE:]

					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(pta_write, &swap[swap_mem], SWAP_SIZE) // get d out
					pta_write = pta_write[SWAP_SIZE:]

					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(ptd_write, a_swap2, SWAP_SIZE)
				} else {		
					intrinsics.mem_copy(a_swap1, pta_read, SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]

					ptd_read = ptd_read[-rest:]
					intrinsics.mem_copy(pta_write, ptd_read, rest)
					pta_write = pta_write[rest:]

					intrinsics.mem_copy(&swap[swap_mem], pta_read, SWAP_SIZE) // put a in
					pta_read = pta_read[SWAP_SIZE:]

					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(pta_write, &swap[swap_mem], SWAP_SIZE) // get d out
					pta_write = pta_write[SWAP_SIZE:]
				}


				// gap in either a or d, 
				// if d: place swap2 in d
				// if a: place d in a, place swap2 in d


				// a_swap2 hold data
				// s[1 - swap_men] hold data

				if gap_a := dist(pta_read, pta_write); gap_a >= SWAP_SIZE {
					ptd_read = ptd_read[-SWAP_SIZE:]
					intrinsics.mem_copy(pta_write, ptd_read, SWAP_SIZE)
					pta_write = pta_write[SWAP_SIZE:]
				}
				ptd_write = ptd_write[-SWAP_SIZE:]
				intrinsics.mem_copy(ptd_write, a_swap1, SWAP_SIZE)


				// now we have some data in  1 - swap_mem 



				loop = dist(ptd_read, pta_read) / 2

                for ; loop >= SWAP_SIZE; loop -= SWAP_SIZE {	
					ptd_read = ptd_read[-SWAP_SIZE:]
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap[swap_mem], pta_read, SWAP_SIZE)
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(pta_write, ptd_read, SWAP_SIZE)
					intrinsics.mem_copy(ptd_write, &swap[swap_mem], SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]
					pta_write = pta_write[SWAP_SIZE:]
                }	




				if dist(ptd_read, pta_read) == 0 {
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(pta_write,&swap[swap_mem], SWAP_SIZE)
					pta_write = pta_write[SWAP_SIZE:]
				} else { // still one more swap to do
					ptd_read = ptd_read[-SWAP_SIZE:]
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap[swap_mem], ptd_read, SWAP_SIZE)
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(ptd_write, &swap[swap_mem], SWAP_SIZE)
					ptd_write = ptd_write[-SWAP_SIZE:]
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(pta_write, &swap[swap_mem], SWAP_SIZE)
				}
            }
        }
    } else if left > right {
		if right <= SWAP_SIZE_4 {	
			// fmt.println("right stack rotation")
			intrinsics.mem_copy(&swap, arr[left:], right)
			intrinsics.mem_copy(arr[right:], arr, left)
			intrinsics.mem_copy(arr, &swap, right)
        } else {
            // pta, ptb, ptc, ptd : [^]byte
			pta = arr
            ptb = arr[left:]
            loop := left - right

            if loop <= SWAP_SIZE_4 && loop > 0 {
				// fmt.println("right bridge rotation")
                ptc = arr[right:]
                ptd = ptc[left:]



                intrinsics.mem_copy(&swap, ptc, loop)

                for ; right >= loop; right -= loop {
					intrinsics.mem_copy(ptc,pta,loop)
					intrinsics.mem_copy(pta,ptb,loop)
					pta = pta[loop:]
					ptc = ptc[loop:]
					ptb = ptb[loop:]
                }
				if right > 0 {					
					intrinsics.mem_copy(ptc,pta,right)
					intrinsics.mem_copy(pta,ptb,right)
					pta = pta[right:]
					ptc = ptc[right:]
					ptb = ptb[right:]
				}

                intrinsics.mem_copy(ptd[-loop:], &swap, loop)

            } else {
			// fmt.println("right trev rotation")
                ptc = ptb
                ptd = ptc[right:] // end


				// Phase 1

                loop: = right / 2
			// fmt.println("right trev rotation loop 1", loop, dist(ptd, ptc), right)

                for ; loop >= SWAP_SIZE; loop -= SWAP_SIZE {
					ptb = ptb[-SWAP_SIZE:]
					ptd = ptd[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap, ptb, SWAP_SIZE)
					intrinsics.mem_copy(ptb, pta, SWAP_SIZE)
					intrinsics.mem_copy(pta, ptc, SWAP_SIZE)
					intrinsics.mem_copy(ptc, ptd, SWAP_SIZE)
					intrinsics.mem_copy(ptd, &swap, SWAP_SIZE)
					ptc = ptc[SWAP_SIZE:]
					pta = pta[SWAP_SIZE:]
                }


				pta_write = pta
				pta_read = pta

				ptd_write = ptd
				ptd_read = ptd

				rest := dist(ptd, ptc)
		// <--
			// fmt.println("right trev rotation 2", rest)

				// fmt.println("right trev rotation" , rest)

				// a and d have gaps,
				// d is in swap
				// a -> b -> d -> a
				// fmt.println(rest)
				if rest > SWAP_SIZE {
					// fmt.println("left")
					intrinsics.mem_copy(&swap, pta_read, SWAP_SIZE_2)
					// print(pta_read,2,1)
					pta_read = pta_read[SWAP_SIZE_2:]

					ptd_read = ptd_read[-rest:]
					intrinsics.mem_copy(pta_write, ptd_read, rest)
					// print(pta_write,2,1)
					pta_write = pta_write[rest:]

					ptb = ptb[-SWAP_SIZE:]
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(ptd_write, ptb, SWAP_SIZE)
					// print(ptd_write,2,1)

					intrinsics.mem_copy(ptb, &swap[0], SWAP_SIZE)
					// print(ptb,2,1)
				} else {
					// fmt.println("right")
					// print(raw_data(swap[0][:]),8,1)
					intrinsics.mem_copy(&swap[1], pta_read, SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]

					ptd_read = ptd_read[-rest:]
					intrinsics.mem_copy(pta_write, ptd_read, rest)
					// print(raw_data(swap[0][:]),8,1)
					pta_write = pta_write[rest:]
				}

				// swap[0] is a
				// a -> b -> d -> a

	
				swap_mem := 0


				// phase 2
				loop = dist(ptb, pta_read) / 2
			// fmt.println("right trev rotation 3", loop)

				// print(arr,length,1)
                for ; loop >= SWAP_SIZE; loop -= SWAP_SIZE {	
					ptd_read = ptd_read[-SWAP_SIZE:]
					ptd_write = ptd_write[-SWAP_SIZE:]
					ptb = ptb[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap[swap_mem], pta_read, SWAP_SIZE) // d [swap_mem]
					intrinsics.mem_copy(pta_write, ptd_read, SWAP_SIZE)
					intrinsics.mem_copy(ptd_write, ptb, SWAP_SIZE)
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(ptb, &swap[swap_mem], SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]
					pta_write = pta_write[SWAP_SIZE:]
                }	
                
				rest = dist(ptb, pta_read)

			// fmt.println("right trev rotation 4", rest)

				// a and d have gaps,
				// d is in swap
				// a also in swap
				d_swap1 := &swap[2]
				d_swap2 := &swap[3]
				if rest > SWAP_SIZE {		
					ptd_read = ptd_read[-SWAP_SIZE:]
					intrinsics.mem_copy(d_swap2, ptd_read, SWAP_SIZE)
					ptd_read = ptd_read[-SWAP_SIZE:]
					intrinsics.mem_copy(d_swap1, ptd_read, SWAP_SIZE)

					ptd_write = ptd_write[-rest:]
					intrinsics.mem_copy(ptd_write, pta_read, rest)
					pta_read = pta_read[rest:]

					ptd_read = ptd_read[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap[swap_mem], ptd_read, SWAP_SIZE) // put d in

					swap_mem = 1 - swap_mem 
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(ptd_write, &swap[swap_mem], SWAP_SIZE) // get a out
					

					intrinsics.mem_copy(pta_write, d_swap2, SWAP_SIZE)
					pta_write = pta_write[-SWAP_SIZE:]
				} else {		
					ptd_read = ptd_read[-SWAP_SIZE:]
					intrinsics.mem_copy(d_swap1, ptd_read, SWAP_SIZE)

					ptd_write = ptd_write[-rest:]
					intrinsics.mem_copy(ptd_write, pta_read, rest)
					pta_read = pta_read[rest:]

					ptd_read = ptd_read[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap[swap_mem], ptd_read, SWAP_SIZE) // put d in
					
					swap_mem = 1 - swap_mem 
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(ptd_write, &swap[swap_mem], SWAP_SIZE) // get a out
				}


				// gap in either a or d, 
				// if d: place swap2 in d
				// if a: place d in a, place swap2 in d


				// d_swap2 hold data
				// s[1 - swap_men] hold data

				if gap_d := dist(ptd_write, ptd_read); gap_d >= SWAP_SIZE {
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(ptd_write, pta_read, SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]
				}
				intrinsics.mem_copy(pta_write, d_swap1, SWAP_SIZE)
				pta_write = pta_write[SWAP_SIZE:]


				// now we have some data in  1 - swap_mem 



				loop = dist(ptd_read, pta_read) / 2
			// fmt.println("right trev rotation 5", loop)

                for ; loop >= SWAP_SIZE; loop -= SWAP_SIZE {	
					ptd_read = ptd_read[-SWAP_SIZE:]
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(&swap[swap_mem], ptd_read, SWAP_SIZE)
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(ptd_write, pta_read, SWAP_SIZE)
					intrinsics.mem_copy(pta_write, &swap[swap_mem], SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]
					pta_write = pta_write[SWAP_SIZE:]
                }	


				// for i in 0..<30 do draw()


				if dist(ptd_read, pta_read) == 0 {
					swap_mem = 1 - swap_mem 
					ptd_write = ptd_write[-SWAP_SIZE:]
					intrinsics.mem_copy(ptd_write,&swap[swap_mem], SWAP_SIZE)
				} else { // still one more swap to do
					intrinsics.mem_copy(&swap[swap_mem], pta_read, SWAP_SIZE)
					pta_read = pta_read[SWAP_SIZE:]
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(pta_write, &swap[swap_mem], SWAP_SIZE)
					// pta_write = pta_write[SWAP_SIZE:]
					ptd_write = ptd_write[-SWAP_SIZE:]
					swap_mem = 1 - swap_mem 
					intrinsics.mem_copy(ptd_write, &swap[swap_mem], SWAP_SIZE)
				}
            }
        }
	} else {
		pta := arr
		ptb := arr[left:]
        for ; left >= SWAP_SIZE; left -= SWAP_SIZE {
			intrinsics.mem_copy(&swap, pta, SWAP_SIZE)
			intrinsics.mem_copy(pta, ptb, SWAP_SIZE)
			intrinsics.mem_copy(ptb, &swap, SWAP_SIZE)
			pta = pta[SWAP_SIZE:]
			ptb = ptb[SWAP_SIZE:]
        }
		intrinsics.mem_copy(&swap, pta, left)
		intrinsics.mem_copy(pta, ptb, left)
		intrinsics.mem_copy(ptb, &swap, left)
		// panic("wrong roation, left = right")
	}
}
