# odin-utils


blitsort
---
a stable, stack based quick/merge sort both for soa and aos

it compiles to 25kb with o:speed

quadsort
---
a stable, adaptive merge sort both for soa and aos


small sorts
---
if you need something smaller goto min_sort

speed comparable to modern sorts such as rust std::sort


min_lumoto: unstable, max 2800 byte extra stack space

min_flux: stable, allocates N extra memory

min_blit: stable, allocates [512]T stack space


they implement most of odins interface, such as 

sort, sort_by, sort_by_with_intedies, sort_by_with_data ...

at 10x the speed of slice.sort

downside: they generate new bytecode each call, so use sparingly or your executable will bloat