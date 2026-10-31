Functionality
---
implements most of core:slice functionality, such as
```
sort
sort_by
sort_with_indices
sort_by_with_indices
sort_by_with_data
sort_by_with_indices_with_data
sort_by_cmp
sort_by_cmp_with_data
```

each file can be used indipendently.
copy files depending on your need, or all of them together

Sorts
---
| Sort |  allocates | stable | comment |
| ----------- | --- | ----------- | --- |
| min_lumoto | no | no | default general sort |
| min_flux | yes | yes | default stable sort |
| min_blit | no* | yes | *only allocates stack memory (unless sorting with indices) |
| radix | yes | yes | only works for numeric types (can sort int and float correctly) |

they have a version that can also sort #soa

Benchmark
---



```
sorting 100_000 elements; Iterations 100
fastest time | 25% time | 50% time | function name

random []int
1.3688ms  |  1.3926ms  |  1.4189ms  |  sort_inlined
1.5943ms  |  1.6116ms  |  1.6359ms  |  sort_stable
1.8872ms  |  1.9129ms  |  2.504ms  |  piposort
2.1388ms  |  2.1708ms  |  2.2014ms  |  sort_stable_stack
21.1369ms  |  21.4248ms  |  23.1192ms  |  slice.sort
1.7606ms  |  1.8505ms  |  1.9095ms  |  radix

ascending []int
1.223ms  |  1.2411ms  |  1.2519ms  |  sort_inlined
734.4µs  |  780.5µs  |  802.9µs  |  sort_stable
278µs  |  292.6µs  |  431.6µs  |  piposort
888.7µs  |  896.4µs  |  1.0156ms  |  sort_stable_stack
2.5714ms  |  2.5936ms  |  2.6157ms  |  slice.sort
1.9776ms  |  2.0234ms  |  2.0611ms  |  radix

i % 1000 []int
715.1µs  |  733.5µs  |  745.7µs  |  sort_inlined
1.5028ms  |  1.5222ms  |  1.5316ms  |  sort_stable
1.3964ms  |  1.6139ms  |  1.634ms  |  piposort
2.0459ms  |  2.075ms  |  2.2656ms  |  sort_stable_stack
25.355ms  |  26.0007ms  |  32.105ms  |  slice.sort

random []Data by less | size of Data:  176
13.8529ms  |  14.5051ms  |  15.2916ms  |  sort_inlined_by
26.2851ms  |  35.3493ms  |  41.608ms  |  sort_stable_by
39.679ms  |  57.5522ms  |  70.3887ms  |  sort_stable_stack_by
93.8887ms  |  98.0063ms  |  108.7073ms  |  slice.sort_by
33.9405ms  |  34.9188ms  |  35.496ms  |  radix_by

random []int with indecies
3.0785ms  |  3.258ms  |  3.4049ms  |  sort_inlined_with_indices
4.0802ms  |  4.3628ms  |  4.7765ms  |  sort_stable_with_indices
4.3982ms  |  4.7343ms  |  6.2214ms  |  sort_stable_stack_with_indices
49.4987ms  |  60.4048ms  |  65.2793ms  |  slice.sort_with_indices

random []Data with indecies
13.8714ms  |  17.9611ms  |  22.4764ms  |  sort_inlined_by_with_indices
16.8184ms  |  21.2025ms  |  25.7046ms  |  sort_stable_by_with_indices
17.9295ms  |  21.8308ms  |  27.0272ms  |  sort_stable_stack_by_with_indices
213.5886ms  |  240.0649ms  |  250.4163ms  |  slice.sort_by_with_indices

random []Data with modulus data
7.7855ms  |  8.5584ms  |  12.0423ms  |  sort_inlined_by_with_data
21.3743ms  |  36.1301ms  |  38.1364ms  |  sort_stable_by_with_data
45.4303ms  |  53.1111ms  |  61.8736ms  |  sort_stable_stack_by_with_data
106.0168ms  |  118.2251ms  |  126.64ms  |  slice.sort_by_with_data

random []Data with modulus data with indices
11.3786ms  |  16.914ms  |  22.1776ms  |  sort_inlined_by_with_indices_with_data
19.2826ms  |  25.5871ms  |  30.3277ms  |  sort_stable_by_with_indices_with_data
17.6128ms  |  23.4195ms  |  30.7375ms  |  sort_stable_stack_by_with_indices_with_data
85.6884ms  |  89.7031ms  |  103.0799ms  |  slice.sort_by_with_indices_with_data
38.8702ms  |  40.649ms  |  44.0075ms  |  sort_stable_stack_by_with_data
```
