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

min_lumoto: unstable, max 2800 byte extra stack space

min_flux: stable, allocates N extra memory

min_blit: stable, allocates [512]T stacak space