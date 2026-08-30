Motivation
---

slice.sort is versatile, but slow. #7423 doesnt change that either
a dedicated sort for when performance matters would be usefull
#6739 tried to start that, but that went nowhere


Implementation
---
branchless quicksort + insertion sort

uses median3 rekursively to find the pivot
partitioning is with gapped lumoto for small types and hoare for types > 80 byte
unrolled recursion into bigger partition to keep stack usage low
everything is in-place exept temp variables

main improvements can be found with the smallsort, but there is not much that can be done without using extra memory

because it uses a compile time comparison proc, it generates a new function each time it is called with any change, so i added a warning to each proc.
the name is explicit about what it does: sort_inlined to inicate that the comparison proc gets inlined for more performance, but also more code gen
// WARNING: each call generates a new quicksort, only use in performance critical path

Should i add more documentation?


Benchmarks
---
Within 50% of optimized sorts like [ipnsort](https://github.com/Voultapher/sort-research-rs/blob/main/writeup/ipnsort_introduction/text.md) but significantly simpler and smaller

```
test_highly_ordered(100_000 int)
size 100000   inline_sort:  1.6698ms _smoothsort:  4.6019ms 2.7559587974607735

test_many_similar(100_000 int)
size 100000   inline_sort:  282.2µs _smoothsort:  18.0055ms 63.80403968816442

test_random(100_000 int)
size 100000   inline_sort:  1.7465ms _smoothsort:  22.4256ms 12.840309189808188

test_slice_with_data_indecies_100_000
size 100000   inline_sort:  8.2521ms _smoothsort:  47.415ms 5.745810157414477

slice.big(100_00 1600 byte )
size 10000   inline_sort:  2.4425ms _smoothsort:  15.9196ms 6.517748208802456

sort_with_indecies(int)
size 10   inline_sort:  36 _smoothsort:  88     diff:    2.4444444444444446
size 100   inline_sort:  45 _smoothsort:  203     diff:    4.441048034934497
size 1000   inline_sort:  62 _smoothsort:  317     diff:    5.112254744290769
size 10000   inline_sort:  96 _smoothsort:  439     diff:    4.579292540234432
size 100000   inline_sort:  192 _smoothsort:  682     diff:    3.549356169599221

sort_by_with_indecies([10]int)
size 10   inline_sort:  38 _smoothsort:  106     diff:    2.789473684210526
size 100   inline_sort:  53 _smoothsort:  292     diff:    5.524528301886792
size 1000   inline_sort:  73 _smoothsort:  495     diff:    6.767276700355095
size 10000   inline_sort:  116 _smoothsort:  726     diff:    6.249204793590207
size 100000   inline_sort:  358 _smoothsort:  1532     diff:    4.278196987274467

test_random(int)
size 10   inline_sort:  20 _smoothsort:  92     diff:    4.6
size 100   inline_sort:  23 _smoothsort:  178     diff:    7.747826086956522
size 1000   inline_sort:  28 _smoothsort:  284     diff:    10.102982954545455
size 10000   inline_sort:  32 _smoothsort:  371     diff:    11.44681507060492
size 100000   inline_sort:  35 _smoothsort:  771     diff:    21.929470360539074 // sometimes you get hickups
size 1000000   inline_sort:  43 _smoothsort:  713     diff:    16.5538420141869
```