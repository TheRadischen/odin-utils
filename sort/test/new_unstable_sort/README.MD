```
Data :: struct($T: typeid) {
	rand: T,
	junk: [N]int,
}
```

```
odin run . -o:speed  -define:N=1
type: int size:  10 quick: time: 100ns comps: 34   ||  smooth: time 300ns comps: 54
type: f32 size:  10 quick: time: 200ns comps: 44   ||  smooth: time 300ns comps: 51
type: int size:  100 quick: time: 5.2µs comps: 1064   ||  smooth: time 9.3µs comps: 1695
type: f32 size:  100 quick: time: 5.8µs comps: 975   ||  smooth: time 10µs comps: 1739
type: int size:  1000 quick: time: 83.5µs comps: 16029   ||  smooth: time 158.4µs comps: 31201
type: f32 size:  1000 quick: time: 90.4µs comps: 16270   ||  smooth: time 170.9µs comps: 31195
type: int size:  10000 quick: time: 1.1076ms comps: 214159   ||  smooth: time 2.1577ms comps: 453029
type: f32 size:  10000 quick: time: 1.205ms comps: 212432   ||  smooth: time 2.3343ms comps: 453157
type: int size:  100000 quick: time: 13.7303ms comps: 2667249   ||  smooth: time 28.6057ms comps: 5960594
type: f32 size:  100000 quick: time: 15.0268ms comps: 2675075   ||  smooth: time 30.8773ms comps: 5957439
type: int size:  1000000 quick: time: 168.0812ms comps: 31834520   ||  smooth: time 516.5231ms comps: 74003537
type: f32 size:  1000000 quick: time: 180.0711ms comps: 31788512   ||  smooth: time 547.2304ms comps: 73984239
```

```
odin run . -o:speed  -define:N=50
type: int size:  10 quick: time: 400ns comps: 38   ||  smooth: time 700ns comps: 56
type: f32 size:  10 quick: time: 400ns comps: 42   ||  smooth: time 800ns comps: 51
type: int size:  100 quick: time: 15.5µs comps: 1134   ||  smooth: time 30.7µs comps: 1719
type: f32 size:  100 quick: time: 16µs comps: 1057   ||  smooth: time 30.9µs comps: 1684
type: int size:  1000 quick: time: 248.7µs comps: 16213   ||  smooth: time 545.5µs comps: 31076
type: f32 size:  1000 quick: time: 256.9µs comps: 15414   ||  smooth: time 552.2µs comps: 30915
type: int size:  10000 quick: time: 3.3762ms comps: 212699   ||  smooth: time 8.0792ms comps: 453507
type: f32 size:  10000 quick: time: 3.4459ms comps: 211376   ||  smooth: time 8.2059ms comps: 452682
type: int size:  100000 quick: time: 52.4247ms comps: 2610702   ||  smooth: time 155.7989ms comps: 5959275
type: f32 size:  100000 quick: time: 53.5325ms comps: 2672896   ||  smooth: time 158.1875ms comps: 5957138
type: int size:  1000000 quick: time: 948.9778ms comps: 32171736   ||  smooth: time 2.9705208s comps: 73992618
type: f32 size:  1000000 quick: time: 721.0661ms comps: 31571667   ||  smooth: time 4.0513178s comps: 73999495
```


```
odin run .  -define:N=1
type: int size:  10 quick: time: 300ns comps: 38   ||  smooth: time 900ns comps: 54
type: f32 size:  10 quick: time: 400ns comps: 42   ||  smooth: time 1.1µs comps: 54
type: int size:  100 quick: time: 9.3µs comps: 1118   ||  smooth: time 26.3µs comps: 1669
type: f32 size:  100 quick: time: 13.9µs comps: 1069   ||  smooth: time 35.2µs comps: 1657
type: int size:  1000 quick: time: 146.4µs comps: 15675   ||  smooth: time 420.5µs comps: 31133
type: f32 size:  1000 quick: time: 218.7µs comps: 15518   ||  smooth: time 624µs comps: 30850
type: int size:  10000 quick: time: 1.9102ms comps: 216095   ||  smooth: time 5.7429ms comps: 452765
type: f32 size:  10000 quick: time: 2.8892ms comps: 221341   ||  smooth: time 8.743ms comps: 453472
type: int size:  100000 quick: time: 43.0251ms comps: 2635917   ||  smooth: time 181.1416ms comps: 5958819
type: f32 size:  100000 quick: time: 84.4053ms comps: 2668437   ||  smooth: time 173.4864ms comps: 5955764
type: int size:  1000000 quick: time: 609.5492ms comps: 31438447   ||  smooth: time 1.6098038s comps: 74004770
type: f32 size:  1000000 quick: time: 500.5873ms comps: 31581967   ||  smooth: time 2.2040983s comps: 73998520
```

```
odin run .  -define:N=50
type: int size:  10 quick: time: 500ns comps: 32   ||  smooth: time 1.5µs comps: 51
type: f32 size:  10 quick: time: 600ns comps: 54   ||  smooth: time 1.6µs comps: 54
type: int size:  100 quick: time: 28.8µs comps: 1037   ||  smooth: time 57.1µs comps: 1751
type: f32 size:  100 quick: time: 28.8µs comps: 1075   ||  smooth: time 55.2µs comps: 1694
type: int size:  1000 quick: time: 499.9µs comps: 15833   ||  smooth: time 942.1µs comps: 31324
type: f32 size:  1000 quick: time: 507.3µs comps: 15614   ||  smooth: time 922.4µs comps: 31223
type: int size:  10000 quick: time: 7.4795ms comps: 213602   ||  smooth: time 13.9206ms comps: 452572
type: f32 size:  10000 quick: time: 7.369ms comps: 211837   ||  smooth: time 13.8604ms comps: 453368
type: int size:  100000 quick: time: 129.6789ms comps: 2679959   ||  smooth: time 264.4816ms comps: 5955899
type: f32 size:  100000 quick: time: 223.4564ms comps: 2630644   ||  smooth: time 242.8356ms comps: 5957302
type: int size:  1000000 quick: time: 1.9776812s comps: 31701117   ||  smooth: time 3.9341216s comps: 73986919
type: f32 size:  1000000 quick: time: 1.4080656s comps: 31779182   ||  smooth: time 3.4721895s comps: 73977901
```
