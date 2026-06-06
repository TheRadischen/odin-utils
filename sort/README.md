reasons for updating slice._stable_sort_general:

old algorithm: insertion sort
time: O(n²)
space: O(1)

new algorithm: merge rotate sort
time: O(nlog(n)²)
space: O(logn) stack, because of recursion


benchmark for 

what we are interested in is the blue and red algos
the chagne in slice.stable_sort is from insert to rotate_merge
<img width="605" height="341" alt="int70" src="https://github.com/user-attachments/assets/aaf48d20-abe2-442e-a523-19df4b73f81d" />
<img width="605" height="341" alt="int 10" src="https://github.com/user-attachments/assets/78e6b366-742f-4723-9f57-ab9365b51717" />
<img width="605" height="341" alt="int 1" src="https://github.com/user-attachments/assets/51455fb9-8a96-462d-b987-37127fc0ca35" />
<img width="605" height="341" alt="f32 10" src="https://github.com/user-attachments/assets/ac043684-fbab-4c22-93e9-73d51f91ea11" />
<img width="605" height="341" alt="desending" src="https://github.com/user-attachments/assets/45ddf631-901a-4f27-a696-9cab1b8d1440" />
