blitsort by scandum
---
https://github.com/scandum/blitsort
check his site for explanaition of the algorithm and further benchmarks

Port into Odin
---
the odin port is written generic, that means you can sort any slice or #soa

Pros
---
fast stable adaptive sorting with only 512 stack space // can be changed in blitsort.odin

on average 5x faster than slice.sort() for small types

can sort #soa

Cons
---
big binary size (havent measured yet), be carefull not to create too many inscances with parapoly

performance degrades a bit when the type to be sorted becomes too big, roughly equal to slice.sort()

havent implemented sorting with indexes yet. prefer to [slice.sort_with_indices()](https://github.com/odin-lang/Odin/blob/master/core/slice/sort.odin#L103)


Benchmark
---
benchmarks are done with []int

at the top is len(slice)

at the right side you can see the time in ns / nlogn

compared are:

blitsort

quadsort

slice.sort() // smoothsort

compiled with -o:speed -no-bounds-check

rand_int
<img width="1082" height="752" alt="rand_int" src="https://github.com/user-attachments/assets/7cfa5219-76d3-47e8-86ae-6ce1742ee8e6" />


random_tail25
<img width="1082" height="752" alt="random_tail25" src="https://github.com/user-attachments/assets/85381543-ce92-4848-97e8-4585e8dc845e" />
random_head25
<img width="1082" height="752" alt="random_head25" src="https://github.com/user-attachments/assets/0a0cd340-6470-4474-be5c-fd3cd84427f4" />
ascending_swa7
<img width="1082" height="752" alt="ascending_swa7" src="https://github.com/user-attachments/assets/606f73e1-b86d-4695-ba7e-c4d7a83c4e03" />
descending_swa7
<img width="1082" height="752" alt="descending_swa7" src="https://github.com/user-attachments/assets/6e8e654c-230d-4e39-bcfe-02d481d21a55" />
rand_half
<img width="1082" height="752" alt="rand_half" src="https://github.com/user-attachments/assets/4838c270-6bce-41a8-b0c4-410c9bd88db8" />
ascneding
<img width="1082" height="752" alt="ascneding" src="https://github.com/user-attachments/assets/afff8095-fa8b-49bf-9bb6-dfe5497663a0" />
descending
<img width="1082" height="752" alt="descending" src="https://github.com/user-attachments/assets/51441956-8a06-4def-8a56-5ab8f7093fa2" />
descending
<img width="1082" height="752" alt="descending" src="https://github.com/user-attachments/assets/1426d986-df9e-4821-9925-2205c5b3ef13" />
rand_mod10
<img width="1082" height="752" alt="rand_mod10" src="https://github.com/user-attachments/assets/0289d9b2-63be-4e21-b673-298dab102a1c" />
shell_gap4
<img width="1082" height="752" alt="shell_gap4" src="https://github.com/user-attachments/assets/4c0a3bdc-cce7-4794-9992-ac47d3892056" />

rand_data_416bytes

performance degrades with big structs
<img width="1082" height="752" alt="rand_data_416bytes" src="https://github.com/user-attachments/assets/9aa1505a-7de8-4204-8dc8-5916e3330451" />



















