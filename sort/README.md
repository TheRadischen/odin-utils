reasons for updating slice._stable_sort_general:

old algorithm: insertion sort
- time: O(n²)
- space: O(1)

new algorithm: merge rotate sort
- time: O(nlog(n)²)
- space: O(logn) stack, because of recursion (24 depth at 1_000_000, 14 at 1000), but we only allocate a few variables
- used in c++ stdlib:
- and go (go uses tail call optimization, so no stack)

speed benchmark

what we are interested in is the blue and red algos

the change in slice.stable_sort is from insert to rotate_merge

for comparison i added some other algos, that are not prototypes:
- branchless qsort is the main algo behind pattern defeating quicksort that is a widely used unstable sort
- ping pong sort is an out of place O(n) memory, stable merge sort almost on par with pdqsort, but much simpler
- lastly is slice.sort, odins smoothsort implementation, that does well on almost sorted arrays, but is up to 10x slower on random data

to interpret the diagrams

on the left is input size

on the bottom is log(time / n*log(n))

exponential insertion sort becomes linear

nlogn sorts become vertical

nlog²n merge_rotate has a small uptick (not much, my benchmarks arent that precice...)

<img width="605" height="341" alt="int70" src="https://github.com/user-attachments/assets/aaf48d20-abe2-442e-a523-19df4b73f81d" />
<img width="605" height="341" alt="int 10" src="https://github.com/user-attachments/assets/78e6b366-742f-4723-9f57-ab9365b51717" />
<img width="605" height="341" alt="int 1" src="https://github.com/user-attachments/assets/51455fb9-8a96-462d-b987-37127fc0ca35" />
<img width="605" height="341" alt="f32 10" src="https://github.com/user-attachments/assets/ac043684-fbab-4c22-93e9-73d51f91ea11" />
<img width="605" height="341" alt="desending" src="https://github.com/user-attachments/assets/45ddf631-901a-4f27-a696-9cab1b8d1440" />
