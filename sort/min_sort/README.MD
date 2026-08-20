#Overview
---
min_sort is based on readability and minimal LOC

| Sort |  allocates | stable | comment |
| ----------- | --- | ----------- | --- |
| min_lumoto | no | no | great general sort |
| min_flux | yes | yes | ~ 20 % slower |
| min_blit | no* | yes | worse growth |
| radix | yes | yes | only works for numeric types, but fastest in many cases |


Functinality
---
many, not all of core:slice are implemented, including: (not for all sorts)
```
sort(arr, allocator)
sort_by(arr, less, allocator)
sort_with_indices(arr, less, allocator)
sort_by_with_indices(arr, less, allocator)
sort_by_with_data(arr, data, less, allocator)
sort_by_with_indices_with_data(arr, data, less, allocator)

soa_sort_by(arr: #soa[], less, allocator)
```
allocator are optional, default to context.allocator

Benchmarks
---

```
sort(int)
iter 10000 size 10  | in cycles / items  mini_flux:  10 slice.sort:  62 diff:  6.2
iter 10000 size 100 | in cycles / items  mini_flux:  22 slice.sort:  131 diff:  5.990909090909091
iter 1000 size 1000 | in cycles / items  mini_flux:  28 slice.sort:  214 diff:  7.614509246088193
iter 100 size 10000 | in cycles / items  mini_flux:  37 slice.sort:  287 diff:  7.594145569620253
iter 10 size 100000 | in cycles / items  mini_flux:  42 slice.sort:  373 diff:  8.771449245400042
iter 4 size 1000000 | in cycles / items  mini_flux:  49 slice.sort:  723 diff:  14.657434074386346

sort_with_indecies(int)
iter 10000 size 10  | in cycles / items  mini_flux:  28 slice.sort:  69 diff:  2.4964285714285714
iter 10000 size 100 | in cycles / items  mini_flux:  43 slice.sort:  155 diff:  3.585253456221198
iter 1000 size 1000 | in cycles / items  mini_flux:  57 slice.sort:  245 diff:  4.244544509871839
iter 100 size 10000 | in cycles / items  mini_flux:  99 slice.sort:  354 diff:  3.5491737440910183
iter 10 size 100000 | in cycles / items  mini_flux:  206 slice.sort:  593 diff:  2.869145596695963

sort_by_with_indecies([10]int)
iter 10000 size 10  | in cycles / items  mini_flux:  38 slice.sort:  106 diff:  2.789473684210526
iter 10000 size 100 | in cycles / items  mini_flux:  51 slice.sort:  251 diff:  4.856949806949807
iter 1000 size 1000 | in cycles / items  mini_flux:  69 slice.sort:  435 diff:  6.297312915342387
iter 100 size 10000 | in cycles / items  mini_flux:  116 slice.sort:  663 diff:  5.694157158788711
iter 10 size 100000 | in cycles / items  mini_flux:  309 slice.sort:  1467 diff:  4.745670499521189

soa_sort_by([4]int)
iter 10000 size 10  | in cycles / items  mini_flux:  12
iter 10000 size 100 | in cycles / items  mini_flux:  38
iter 1000 size 1000 | in cycles / items  mini_flux:  63
iter 100 size 10000 | in cycles / items  mini_flux:  87
iter 10 size 100000 | in cycles / items  mini_flux:  131
```
