# Answer: doors of the hall

Files in `verify/`. `Doorway.tla` is the shared module. `Hall.tla` is
the answer. `HallUnbound.tla` is row three and `HallUnguarded.tla` is
row four.

Every number from `harness/verdict.sh` on TLC2 Version
2026.07.31.184830.

## Question 1: the doorway and the hall

```
---- MODULE Doorway ----
EXTENDS Naturals
CONSTANT Width
Admits(w) == w <= Width
====
```

```
---- MODULE Hall ----
EXTENDS Naturals
CONSTANT Widths
VARIABLE pallet

D(w) == INSTANCE Doorway WITH Width <- w

Fits(p) == \A w \in Widths : D(w)!Admits(p)

Init == pallet = 1
Widen == Fits(pallet + 1) /\ pallet' = pallet + 1
Unload == pallet' = 1
Next == Widen \/ Unload
Spec == Init /\ [][Next]_pallet

FitsAll == Fits(pallet)
====
```

`Narrow.cfg` sets `Widths = {2, 3}` and names `FitsAll`.

## Question 2: the instance as an operator

`D == INSTANCE Doorway WITH Width <- w` at the top of the hall fails
because `w` means nothing there:

```
line 10, col 37 to line 10, col 37 of module HallUnbound
Unknown operator: `w'.
```

A `WITH` clause is evaluated where the instance is written, and the only
names it can use are the ones in scope there: the hall's constants,
variables and definitions. The width is bound by `\A w \in Widths`,
which is inside `Fits`, so the instance has to be something that can be
handed `w` at that point. `D(w) == INSTANCE Doorway WITH Width <- w`
makes the instance an operator of one argument, and `D(w)!Admits(p)` is
how it's called. The cheat sheet calls this partial parameterization:
some of the module's constants are fixed in the `WITH`, the rest arrive
as arguments.

Here nothing is fixed and everything arrives, which is the degenerate
case. With a two-constant doorway you'd fix one and pass the other.

## Question 3: the counts

Doorways of 2 and 3: the pallet goes from 1 to 2 and stops, since 3
wouldn't get through the 2. Two states. Doorways of 3 and 4: 1, 2, 3.
Three states. Unloading returns to 1 and adds nothing new. Without the
check, the pallet reaches 3 under the narrow doorways and `FitsAll`
fails at the third state.

## Variants worth running

Write the test in the hall as `pallet <= w` and drop the doorway module.
Same counts, and it's what most people would do. The prompt forbids it
by saying the doorway is shared, and that's the only thing holding the
item up.

Give the doorway a second constant, say a height, fix it in the `WITH`
and pass only the width. That's the shape the construct exists for.

## The whole table

| config | module run | rc | distinct | depth |
|---|---|---|---|---|
| `Narrow.cfg` | the answer | 0 | 2 | 2 |
| `Wide.cfg` | the answer, wider doorways | 0 | 3 | 3 |
| `Narrow.cfg` | the instance at the top | 150 | | |
| `Narrow.cfg` | stacking without the check | 12 | 3 | 3 |

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | stands for |
|---|---|---|
| `G08Hall.tla` | rc 0 | `Narrow.cfg`, the answer, 2 states |
| `G08Wide.tla` | rc 0 | `Wide.cfg`, 3 states |
| `G08Unbound.tla` | rc 150 | the instance at the top, unknown operator |
| `G08Unguarded.tla` | rc 12 | stacking without the check |

## why-not-in-prompt

The prompt says "brings the doorway module in once per width", "the
width is only known when a quantifier binds it", and "what does the
instance have to become".

What the prompt withholds: that an instance can take arguments like an
operator, the syntax for that, and how such an instance is called.

The honest caveat: this is the thinnest item in the family. Partial
parameterization is rated low in the inventory, the forcing case is
narrow, and the only thing stopping a reader from inlining the test is a
sentence saying the doorway is shared. I'd cut this one first. It's here
because it's the one row of this family nothing else reaches.
