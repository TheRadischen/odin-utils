# odin-utils
just some (maybe) usefull code

| Sort      | Memory | Stable  | adatability | Speed |
| ----------- | --- | ----------- | --- | --- |
| blitsort      | O(512) | yes      | yes | adapts to sorted data |
| quadsort      | O(n) | yes      | yes | adapts to sorted data |
| quadsort_swap | O(32) | yes      | yes | adapts to sorted data |
| piposort      | O(n) | yes      | no | best for random data |
| mini_flux     | O(n) | yes      | no | best for random data |
| radix         | O(n) | yes      | no  | fastest for random  |
