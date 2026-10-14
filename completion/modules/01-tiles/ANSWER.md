# ANSWER: completion/modules/01-tiles

## The two claims

```tla
Clear == Here!Cells \cap laid = {}

Filled == (next > Wall) => laid = Whole!Cells
```

## Why claim 1 holds on the real corridor

`Here!Cells` is `next..(next + size - 1)` clipped to `1..Wall`, so every cell it
holds sits at `next` or beyond. `laid` only ever gains cells from a tile laid at
an earlier start, and the real corridor moves `next` on by the whole `size`, so
the last cell of the tile just laid is `next - 1`. Nothing in `laid` reaches
`next`.

At `Init` the question does not arise, because `laid` is empty.

## Why claim 2 holds on the real corridor

The starts are 1, then `1 + size`, then `1 + 2 * size`, and each tile covers its
own `size` cells. So the union is an unbroken run from cell 1. `Lay` is guarded
by `next <= Wall`, which means the last tile starts at or before `Wall` and its
clipped cells reach `Wall`. Once `next > Wall` that run is the whole corridor.

The guard is not optional. `laid = Whole!Cells` on its own is false at `Init`.

## Accepted variants

Both of these were run and both score the reference signature:

```tla
Clear == \A c \in laid : c \notin Here!Cells

Filled == (next > Wall) => Cardinality(laid) = Whole!Count
```

`laid \cap Here!Cells = {}` is the same formula commuted. `laid = 1..Wall` in
place of `Whole!Cells` is the same set spelled without the instance.

The `Cardinality` form leans on `TypeOK`. On its own it says `laid` holds `Wall`
elements, and only `laid \in SUBSET (1..Wall)` turns that into `laid = 1..Wall`.

## What each machine measures

`Wall = 7` throughout. Codes from `harness/verdict.sh`.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only |
|---|---|---|---|---|
| `Corridor` | 0, 20 distinct | 0 | 0 | 0 |
| `Lap` | 12, 5 distinct | 0 | 12 | 0 |
| `Gap` | 12, 11 distinct | 0 | 0 | 12 |

Unfilled is 150 on all three machines.

Four distinct signatures, so the three codes separate every half-right answer
from the full one. That is the whole verification contract for this item, and it
is why there are two broken machines rather than one.

Each broken machine is caught by one claim and survives the other, which is the
part worth re-measuring before trusting the item. `Lap` keeps the laid set an
unbroken run from cell 1, so claim 2 still holds on it. `Gap` never lets a tile
reach a laid cell, so claim 1 still holds on it.

`Lap` bites at every `size`, including `size = 1`, where it lays the same cell
twice and never moves `next` at all.
