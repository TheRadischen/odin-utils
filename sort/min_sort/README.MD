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

min_flux and min_blit have a version that can also sort #soa

Benchmark
---
min_lumoto is almost as fast as rust unstable sort
100_000 random int; best of 100 iterations
min_lumoto: 1.6 ms
rust unstable: 1.4 ms


```
sorting 100_000 elements; Iterations 10
fastest time | 25% time | 50% time | function name

random []int
1.7741ms  |  2.0184ms  |  2.8089ms  |  sort_inlined
2.0517ms  |  2.0843ms  |  3.1326ms  |  sort_stable
4.2654ms  |  4.7624ms  |  11.6303ms  |  sort_stable_stack
22.6866ms  |  22.7075ms  |  23.0311ms  |  slice.sort
1.0171ms  |  1.0536ms  |  1.1926ms  |  radix

random []Data by less
106.1517ms  |  109.8339ms  |  111.4715ms  |  sort_inlined_by
282.2424ms  |  301.5084ms  |  317.3886ms  |  sort_stable_by
574.7328ms  |  607.7588ms  |  614.2363ms  |  sort_stable_stack_by
552.1983ms  |  563.1321ms  |  573.3141ms  |  slice.sort_by
196.4936ms  |  196.7579ms  |  198.4365ms  |  radix_by

random []int with indecies
4.1169ms  |  4.1702ms  |  4.2272ms  |  sort_inlined_with_indices
4.3729ms  |  4.4689ms  |  4.9065ms  |  sort_stable_with_indices
5.8106ms  |  5.9029ms  |  6.6458ms  |  sort_stable_stack_with_indices
33.4739ms  |  33.896ms  |  34.8921ms  |  slice.sort_with_indices

random []Data with indecies
61.3603ms  |  62.2659ms  |  63.7717ms  |  sort_inlined_by_with_indices
64.134ms  |  64.5702ms  |  66.719ms  |  sort_stable_by_with_indices
67.1322ms  |  67.7938ms  |  68.5954ms  |  sort_stable_stack_by_with_indices
575.6272ms  |  583.4441ms  |  595.7772ms  |  slice.sort_by_with_indices

random []Data with modulus data
68.6158ms  |  73.2631ms  |  76.5458ms  |  sort_inlined_by_with_data
165.3922ms  |  170.5587ms  |  178.3554ms  |  sort_stable_by_with_data
364.086ms  |  381.7694ms  |  398.0805ms  |  sort_stable_stack_by_with_data
362.9487ms  |  374.4941ms  |  397.7117ms  |  slice.sort_by_with_data

random []Data with modulus data with indices
59.5964ms  |  59.7396ms  |  60.5108ms  |  sort_inlined_by_with_indices_with_data
61.2214ms  |  62.1795ms  |  62.4543ms  |  sort_stable_by_with_indices_with_data
61.1983ms  |  62.2655ms  |  63.728ms  |  sort_stable_stack_by_with_indices_with_data
328.405ms  |  340.049ms  |  343.5065ms  |  slice.sort_by_with_indices_with_data
```
