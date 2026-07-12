Current Problems
---
1. Smoothsort has poor performance, sorting anything besides already highly ordered data is very slow. and altho rare, when you sort slices bigger than L3 cache, performance becomes n * sqrt(n) as random memory access scales badly
2. the current generic way only produces the assembly once, that is good for binary size, but when differenct types of data get sorted the comparison function becomes a function pointer. in my limited benchmark thats ~1.7x worse performance

Proposals / Ideas
---
1. raplace smoothsort with a better sort. i made a quicksort that is a drop in replacement in the current archetecture, more in implementation
2. change the underlying archetecture: i havent thought deeply about how to do all the various functionallities, like slice.sort_with_indecies() with a new algo, since i dont even know if bill would want such a change
3. somewhat less related: some way to opt into additional memory usage, maybe a user provided buffer. currently the sorts use some amount of stack allocation, but no big heap allocation, sorts like sort_by_key() could use radix sort when using N extra memory and expecially for 32 bit and smaller types radix would be a big performance gain. also stable sorting is much easier when using extra memory.
4. some way to sort #soa . i know the sort.sort interface can sort soa, but a more native version wouldnt hurt imo.

Implementation
---
Disclaimer: i only did some amount of testing to see that it works in most cases, to actually use it in core i would need to be more Thorough, and the size could probably be a bit smaller. there is some code dupication that might not be nessessary.

But if i rewrite it in a less generic way i'd need to do more testing anyway.


it is basically a standart [block quicksort](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ESA.2016.38) with two main paths, one for small types: <= 16 bit where swaps are performed immediatly and for big types when data moves become expensive the data is only moved when nessesary. this increases code sice by a lot and i might be able to change that since only the smallsort matters really for this, not the big quicksort.

isnt the width known at compile time? should prpbably wrap that in a when, not an if block -_-

for item count <= 64 it uses ping pong merge, so some extra stack space is used here. the size can be made smaller, if neccessary.

at <= 8 it uses odd-even-sort, a bubble sort variant. hurray for bubble sort.

the small sort is mostly a port of scandum [piposort](https://github.com/scandum/piposort)

pivot selection is done based on the size of the array, up to a sample size of 256, because of that i didnt bother including a fallback like heapsort that most unstable sorts use. to make sure the stack doesnt explode in the rare chance the pivot is selected badly we loop the bigger partition and recurse the smaller one.


Benchmarks
---
diefference between only sorting int vs int and f32
`size: 100_000 slice.sort int:  13.4097ms slice.sort f32:  0s`
`size: 100_000 slice.sort int:  21.7802ms slice.sort f32:  23.3753ms`

difference between slice.sort() and my sort on random data
`size:  10 slice.sort int:  700ns qsort int:  100ns diff:  7`
`size:  100 slice.sort int:  8.1┬Ás qsort int:  1.9┬Ás diff:  4.2631578947368425`
`size:  1000 slice.sort int:  95┬Ás qsort int:  18┬Ás diff:  5.277777777777778`
`size:  10000 slice.sort int:  1.0448ms qsort int:  177.5┬Ás diff:  5.8861971830985915`
`size:  100000 slice.sort int:  27.5498ms qsort int:  3.2161ms diff:  8.566213737135039`
`size:  1000000 slice.sort int:  287.7935ms qsort int:  27.1545ms diff:  10.5983722771548`
`size:  10000000 slice.sort int:  5.226332s qsort int:  289.8975ms diff:  18.028206521270448`

purely ascending, smoothsorts best case, witch im not sure how likely it is in the wild, could add a way to detect that early, more LOC :(
`size:  10 slice.sort int:  400ns qsort int:  100ns diff:  4`
`size:  100 slice.sort int:  2.5┬Ás qsort int:  1┬Ás diff:  2.5`
`size:  1000 slice.sort int:  19.9┬Ás qsort int:  10.9┬Ás diff:  1.8256880733944953`
`size:  10000 slice.sort int:  198.4┬Ás qsort int:  132┬Ás diff:  1.503030303030303`
`size:  100000 slice.sort int:  1.7228ms qsort int:  1.3587ms diff:  1.2679767424744242`
`size:  1000000 slice.sort int:  23.1151ms qsort int:  29.1796ms diff:  0.7921664450506518`
`size:  10000000 slice.sort int:  178.3111ms qsort int:  198.102ms diff:  0.9000974245590655`
