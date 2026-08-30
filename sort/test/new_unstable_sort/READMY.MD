```
test_highly_ordered(100_000 int)
size 100000    lumoto:  5.5305ms

test_many_similar(100_000 int)
size 100000    lumoto:  1.6337ms

test_random(100_000 int)
size 100000    lumoto:  10.2806ms

test_slice_with_data_indecies_100_000
size 100000    lumoto:  12.6696ms

slice.big(100_00 1600 byte )
size 100000    lumoto:  8.0777ms

sort_with_indecies(int)
iter 10000 size 10  in cycles / item  slice.sort:  66
iter 10000 size 100  in cycles / item  slice.sort:  123
iter 1000 size 1000  in cycles / item  slice.sort:  171
iter 100 size 10000  in cycles / item  slice.sort:  240
iter 10 size 100000  in cycles / item  slice.sort:  362

sort_by_with_indecies([10]int)
iter 10000 size 10  in cycles / item  slice.sort:  86
iter 10000 size 100  in cycles / item  slice.sort:  199
iter 1000 size 1000  in cycles / item  slice.sort:  328
iter 100 size 10000  in cycles / item  slice.sort:  456
iter 10 size 100000  in cycles / item  slice.sort:  830
```

```
test_highly_ordered(100_000 int)
size 100000    _smoothsort:  4.2111ms

test_many_similar(100_000 int)
size 100000    _smoothsort:  17.2895ms

test_random(100_000 int)
size 100000    _smoothsort:  21.4528ms

test_slice_with_data_indecies_100_000
size 100000    _smoothsort:  46.9443ms

slice.big(100_00 1600 byte )
size 100000    _smoothsort:  15.2466ms

sort_with_indecies(int)
iter 10000 size 10  in cycles / item  slice.sort:  90
iter 10000 size 100  in cycles / item  slice.sort:  191
iter 1000 size 1000  in cycles / item  slice.sort:  301
iter 100 size 10000  in cycles / item  slice.sort:  427
iter 10 size 100000  in cycles / item  slice.sort:  658

sort_by_with_indecies([10]int)
iter 10000 size 10  in cycles / item  slice.sort:  126
iter 10000 size 100  in cycles / item  slice.sort:  282
iter 1000 size 1000  in cycles / item  slice.sort:  490
iter 100 size 10000  in cycles / item  slice.sort:  715
iter 10 size 100000  in cycles / item  slice.sort:  1519
```