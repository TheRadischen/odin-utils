#Overview
---
min_sort features fast sorting algorithms that are easy to read and small in size

| Sort |  allocates | stable | comment |
| ----------- | --- | ----------- | --- |
| min_lumoto | no | no | default general sort |
| min_flux | yes | yes | default stable sort |
| min_blit | no* | yes | only allocates stack memory (unless sorting with indices) |
| radix | yes | yes | only works for numeric types |



API
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
sorting 100_000 elements; Iterations 10
fastest time | 25% time | 50% time | function name

random []int
2.1643ms  |  2.1922ms  |  3.0505ms  |  sort_inlined
2.431ms  |  2.5907ms  |  5.4558ms  |  sort_stable
3.8375ms  |  4.6162ms  |  5.3995ms  |  sort_stable_stack
36.2465ms  |  37.1682ms  |  42.2218ms  |  slice.sort
1.0044ms  |  1.0309ms  |  1.0549ms  |  radix

random []Data by less
104.8845ms  |  107.492ms  |  114.7784ms  |  sort_inlined_by
282.2041ms  |  284.7693ms  |  304.98ms  |  sort_stable_by
598.9837ms  |  617.5429ms  |  625.4188ms  |  sort_stable_stack_by
533.713ms  |  545.5614ms  |  557.6684ms  |  slice.sort_by
194.326ms  |  196.1336ms  |  197.4635ms  |  radix_by

random []int with indecies
4.2286ms  |  4.311ms  |  6.2003ms  |  sort_inlined_with_indices
4.3189ms  |  4.6621ms  |  6.9559ms  |  sort_stable_with_indices
5.7476ms  |  5.8898ms  |  5.9859ms  |  sort_stable_stack_with_indices
33.7083ms  |  34.0284ms  |  35.0077ms  |  slice.sort_with_indices

random []Data with indecies
61.3911ms  |  61.7215ms  |  62.7057ms  |  sort_inlined_by_with_indices
64.304ms  |  64.393ms  |  65.0005ms  |  sort_stable_by_with_indices
67.4241ms  |  68.0688ms  |  69.0781ms  |  sort_stable_stack_by_with_indices
561.5151ms  |  571.1658ms  |  580.6093ms  |  slice.sort_by_with_indices

random []Data with modulus data
66.607ms  |  70.2537ms  |  72.3382ms  |  sort_inlined_by_with_data
164.8031ms  |  170.5777ms  |  178.9233ms  |  sort_stable_by_with_data
359.8763ms  |  367.5045ms  |  387.4808ms  |  sort_stable_stack_by_with_data
350.3658ms  |  359.7477ms  |  374.5783ms  |  slice.sort_by_with_data

random []Data with modulus data with indices
60.3626ms  |  60.8296ms  |  61.367ms  |  sort_inlined_by_with_indices_with_data
61.5622ms  |  61.8037ms  |  63.9826ms  |  sort_stable_by_with_indices_with_data
61.449ms  |  62.3486ms  |  62.9199ms  |  sort_stable_stack_by_with_indices_with_data
328.1906ms  |  339.3699ms  |  346.0334ms  |  slice.sort_by_with_indices_with_data
```
