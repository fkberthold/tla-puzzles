# Answer: the helper that leaked

Files in `verify/`. `Clockface.tla` is the shared face. `Gearing.tla` is
the helper as first written and `GearingLocal.tla` is the helper with
its private parts marked. `Belt.tla` is the conveyor over the fixed
helper. `BeltClash.tla` is the same conveyor over the leaky one,
`BeltLeak.tla` is the conveyor that silently used what leaked, and
`BeltNamed.tla` is the fix from the conveyor's side.

Every number from `harness/verdict.sh` on TLC2 Version
2026.07.31.184830.

## Question 1: the three files

```
---- MODULE Clockface ----
EXTENDS Naturals
Wrap(n) == n % 12
====
```

```
---- MODULE GearingLocal ----
EXTENDS Naturals

LOCAL INSTANCE Clockface

LOCAL Teeth == 4

Turn(n) == Wrap(n + Teeth)
====
```

```
---- MODULE Belt ----
EXTENDS Naturals, GearingLocal
VARIABLES gear, belt

Teeth == 24
Wrap(n) == n % Teeth

Init == gear = 0 /\ belt = 0
Advance ==
    /\ gear' = Turn(gear)
    /\ belt' = Wrap(belt + 4)
Spec == Init /\ [][Advance]_<<gear, belt>>

InStep == belt % 12 = gear
Stations == belt \in 0..23
====
```

Six states: the belt visits 0, 4, 8, 12, 16, 20 and the gear 0, 4, 8, 0,
4, 8.

## Question 2: the two leaks

Extension brings in everything the helper defines and everything the
helper brought in. So the helper as first written hands the conveyor
`Teeth`, its own scratch definition, and `Wrap`, which it got from the
clock face by instantiating it. The conveyor defines both, and the
parser refuses:

```
line 8, col 1 to line 8, col 11 of module BeltClash
Multiple declarations or definitions for symbol Teeth.
This duplicates the one at line 8, col 1 to line 8, col 10 of module Gearing.
line 10, col 1 to line 10, col 20 of module BeltClash
Multiple declarations or definitions for symbol Wrap.
This duplicates the one at line 6, col 1 to line 6, col 17 of module Clockface.
Semantic errors:
*** Errors: 2
line 8, col 1 to line 8, col 11 of module BeltClash
Operator Teeth already defined or declared.
```

The second message is the useful one. The duplicate of `Wrap` is
attributed to `Clockface`, a module the conveyor never mentions. That's
what a leaked import looks like from the outside.

The two marks are the same word in two places. `LOCAL Teeth == 4` keeps
the definition from travelling. `LOCAL INSTANCE Clockface` keeps the
whole import from travelling. The helper still sees both. Nothing that
extends the helper does. `Sequences.tla` in the standard library does the
second one to `Naturals` for the same reason.

## Question 3: the silent one

`BeltLeak.tla` writes neither `Wrap` nor `Teeth` and uses both. It gets
the helper's: wrap round twelve, four teeth. The belt goes 0, 4, 8, 0.
Three states. Both invariants hold, because the belt modulo twelve still
equals the gear and 0, 4 and 8 are real stations. The belt never reaches
station 12 and nothing in the spec says it should.

So the only thing that caught it was the count. Row one says 6 and this
says 3, and that difference is the whole evidence. I think this is the
case to remember rather than the refusal: a leaked name that happens to
have the right shape is a wrong module that checks.

## Question 4: the fix from the other side

```
G == INSTANCE Gearing
...
gear' = G!Turn(gear)
```

A named instance puts everything from the helper behind `G!`. The
conveyor's own `Wrap` and `Teeth` don't collide with `G!Wrap` and
`G!Teeth`, and the conveyor reaches `G!Turn` by name. Same 6 states.
This fix is the conveyor's to make. The `LOCAL` fix is the helper's, and
it protects every future user rather than this one.

## Variants worth running

Rename the conveyor's operators instead. That also parses, and it's what
most people do first. It means the next module that extends the helper
gets the same surprise.

An anonymous instance of a standard module inside the helper, with the
conveyor also extending that standard module, did not clash in a scratch
run I made outside this tree. I suspect the standard modules are
special-cased, and I haven't confirmed why. User modules clash, as
above.

## The whole table

Every run uses `Linked.cfg`, which names `InStep` and `Stations`.

| module run | rc | distinct | depth |
|---|---|---|---|
| the conveyor over the fixed helper | 0 | 6 | 6 |
| the conveyor over the leaky helper | 150 | | |
| the conveyor using what leaked | **0** | 3 | 3 |
| the conveyor naming the leaky helper | 0 | 6 | 6 |

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G05Belt.tla` | rc 0 | 6 | the answer, 6 states |
| `G05Clash.tla` | rc 150 | - | two names already defined |
| `G05Leak.tla` | rc 0 | 3 | the silent leak, 3 states and green |
| `G05Named.tla` | rc 0 | 6 | the named-instance fix, 6 states |

## why-not-in-prompt

The prompt says "private", "brings the clock face in", "under a name",
and "two marks, on two different lines". It names the two colliding
operators and says one of them the helper didn't write.

What the prompt withholds: the keyword, that the same keyword goes on a
definition and on an import, that an import without it travels through
extension, and the named-instance syntax.

The honest caveat: "two marks on two lines" tells the reader the fix is
one word in two places, so the retrieval is the word and not the shape.
The `Stations` invariant is a type check in disguise, which bends the
rule that every item carries a real property. `InStep` is the real one,
and it's the one the silent leak passes, which is the point.
