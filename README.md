# odin-utils
just some (maybe) usefull code

| Sort      | Memory | Stable  | adatability | Speed |
| ----------- | --- | ----------- | --- | --- |
| piposort      | O(n) | yes      | no | best for random data |
| powersort   | O(n/2)  | yes      | yes | best for partially sorted |
| quicksort   | O(log n) (stack)  | no      | no | best for random data |

piposort is a stable, outof-place, branchless comparison sort, faster than quicksort uses O(n) memory

powersort is a fast stable sorting algorithm used by cphyton <br>
quicksort is faster, but unstable


sparse set is usefull to keep track of entities by id even when deleting/inserting <br>
fast iteration, because densly packed in data arr
