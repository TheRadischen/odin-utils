reasons for updating slice._stable_sort_general:

old algorithm: insertion sort
- time: O(n²)
- space: O(1)

new algorithm: merge rotate sort
- time: O(nlog(n)²)
- space: O(logn) stack, because of recursion (24 depth at 1_000_000, 14 at 1000) (twice in worst case), but we only allocate a few variables
- used in c++ stdlib:
- and go (go uses tail call optimization, so no stack)

speed benchmark

what we are interested in is the blue and red algos

the change in slice.stable_sort is from insert to rotate_merge

for comparison i added some other algos, that are prototypes:
- branchless qsort is the main algo behind pattern defeating quicksort that is a widely used unstable sort, but can be made stable with extra space
- ping pong sort is an out of place O(n) memory, stable merge sort almost on par with pdqsort, but much simpler
- lastly is slice.sort, odins smoothsort implementation, that does well on almost sorted arrays, but is up to 10x slower on random data

to interpret the diagrams

on the bottom is input size

on the left is log(time / n*log(n)) the log of the time per sorted element logged
normally benchmarks have time / n*log(n) without the extra log in the beginning, but insertion sorts exponential nature makes that necessary

exponential insertion sort becomes linear

nlogn sorts become vertical

nlog²n merge_rotate has a small uptick (not much, my benchmarks arent that accurate...)

pc: i have a laptop, so dont expect much: ASUS Vivobook with windows 11 

cpu: AMD Ryzen 7 4700U with Radeon Graphics (2.00 GHz)

for small arrays < 1000 item insertion sort is directly called, as rotate_merge has a big constant factor, the diagrams dont show this as i added that after discovering that small arrays are kinda slow

in the data sheet some big inputs arent done with insertion sort as they take too long, the diagrams show an extrapolated graph for 1_000_000 items

benchmarks compiled with -o:speed

<img width="605" height="341" alt="int70" src="https://github.com/user-attachments/assets/aaf48d20-abe2-442e-a523-19df4b73f81d" />
<img width="605" height="341" alt="int 10" src="https://github.com/user-attachments/assets/78e6b366-742f-4723-9f57-ab9365b51717" />
<img width="605" height="341" alt="int 1" src="https://github.com/user-attachments/assets/51455fb9-8a96-462d-b987-37127fc0ca35" />
<img width="605" height="341" alt="f32 10" src="https://github.com/user-attachments/assets/ac043684-fbab-4c22-93e9-73d51f91ea11" />
<img width="605" height="341" alt="desending" src="https://github.com/user-attachments/assets/45ddf631-901a-4f27-a696-9cab1b8d1440" />

data table: https://docs.google.com/spreadsheets/d/1OCvHLQo5C_MKDZ6BmUwvTb4UqK2TAMSjCzBs7AvohpA/edit?usp=sharing

further reading on sorts:

main tradeoff modern sorts need to make is binary size / complexity to implement / speed / extra memory usage

requirements: adaptability, no worst case, speed (ILP, branchless)
  
rust: had recent changes to both its stable and unstable sorts
- https://github.com/Voultapher/sort-research-rs/blob/main/writeup/driftsort_introduction/text.md
- https://github.com/Voultapher/sort-research-rs/blob/main/writeup/ipnsort_introduction/text.md

java:
- timsort for stable sort, dual pivot quicksort for unstable
- a bit outdated, but fast enough. timsort is not inplace

zig:
- wikisort for stable, i kinda laughed when i saw that. block merge sorts are cool algos, but not practical, they have a constant factor of 10x merge_rotate sort. and their nlogn nature only makes them better at 10m items or so. rust looked into implementing grailsort, but got scared, because the algo is too difficult to implement
- pdqsort for unstable, pretty standard


my question for odin is what are the requirements?

- binary size is an issue when para poly makes it easy to have multiple sorts in the same programm, so standart sort needs to be reasonably small, but in core:sort i could add a bigger sort, that could be used when sorting many items and performance is a priority. rust had big algos before the recent changes, altho the current ones still arent small
- extra memory: unstable sorts only need a bit of stack space (512 is more than enough). but stable algos benefit a lot from extra memory. as in the case of ping pong sort o(n) is needed, slice.stable_sort could have a check to see if the memory was succesfully allocated and switch to inplace if no memory was allocated, or again just add them to core:sort




as it is odin doesnt have fast modern algos for sorting


