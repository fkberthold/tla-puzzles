# Answer: the berth and the phantom ship

Files in `verify/`. `Dock.tla` is the system. `MCDock.tla` is the model
wrapper. `DockNoAssume.tla` is the dock with the one line deleted, for
row four.

Every number from `harness/verdict.sh` on TLC2 Version
2026.07.31.184830.

## Question 1: the dock, the wrapper, the config

```
---- MODULE Dock ----
CONSTANTS Ships, Empty

ASSUME Empty \notin Ships

VARIABLES berth, last

TypeOK ==
    /\ berth \in Ships \cup {Empty}
    /\ last \in Ships \cup {Empty}

Init == berth = Empty /\ last = Empty

Moor(s) ==
    /\ berth = Empty
    /\ s /= last
    /\ berth' = s
    /\ UNCHANGED last

Leave ==
    /\ berth \in Ships
    /\ berth' = Empty
    /\ last' = berth

Next == (\E s \in Ships : Moor(s)) \/ Leave
Spec == Init /\ [][Next]_<<berth, last>>

SomeoneCanMoor == berth = Empty => \E s \in Ships : s /= last
====
```

```
---- MODULE MCDock ----
EXTENDS Dock, TLC

Perms == Permutations(Ships)
====
```

`ThreeSym.cfg`, run against `MCDock`:

```
SPECIFICATION Spec
CONSTANTS
    Ships = {kestrel, osprey, petrel}
    Empty = Empty
SYMMETRY Perms
INVARIANT TypeOK
INVARIANT SomeoneCanMoor
```

`Permutations` lives in the `TLC` module. The dock isn't allowed to
import it, so the permutation set goes in a wrapper that extends the
dock and `TLC` both. Extension brings in every declaration and
definition, so the wrapper can name `Spec`, `TypeOK` and the rest in its
config without redefining anything. That's the whole job of an `MC`
module, and it's why 81 of 666 published modules are one.

Symmetry takes 13 states to 4. It needs model values, which the sibling
item `state-space/07` measures: strings in the symmetry set exit 255.

## Question 2: the phantom

```
ASSUME Empty \notin Ships
```

Row three: `Ships = {kestrel, Empty}` with the line in place.

```
Error: Assumption line 6, col 8 to line 6, col 25 of module Dock is false.
```

Row four, with the line deleted, runs clean at 3 states. `Empty` is a
model value. So is `kestrel`. A model value equals itself and nothing
else, which protects you from `Empty` colliding with `"empty"` or with
`0`. It does nothing to stop a config listing `Empty` as a member of
`Ships`, because that's not a collision, it's a membership. The set has
two elements and one of them is the sentinel.

What happens then: `kestrel` moors and leaves, `last = kestrel`, berth
empty. The requirement asks whether some ship may moor. `Empty` is a
ship, `Empty /= kestrel`, so yes. `Moor(Empty)` sets `berth' = Empty`,
which is the state it was in. The phantom ship moors by doing nothing,
and the one-ship harbour that fails in row two passes in row four with
the same three states.

The sibling item `state-space/07` says in its answer that a config can't
put the sentinel in the set without the assumption seeing it. That's
true while the assumption is there. Row four is what happens when it
isn't, with model values and nothing else changed, and it's green.

## Question 3: one ship

Row two fails at three states: `kestrel` moors, leaves, and nobody may
moor. The model is right about a one-ship harbour and the requirement is
false on it. So the requirement is about harbours with at least two
ships, and that size lives in the config, not the module. Carry it as
`ASSUME Cardinality(Ships) >= 2`, which needs `FiniteSets`, or write it
next to the config that checks it. Leaving it implicit is how a true
model gets called a bug.

## Variants worth running

Spell the sentinel as a string, `Empty = "empty"`, with model-value
ships. Clean at 7, same as row one, because nothing compares them. The
sibling item has the full table for that.

Put `Empty = kestrel` in the config. The assumption fires, exit 10. Same
line, same message, different way of landing on it.

## The whole table

Every config runs against `Dock`, except `ThreeSym.cfg` against `MCDock`
and `PhantomNoAssume.cfg` against the copy without the assumption.

| config | rc | distinct | depth |
|---|---|---|---|
| `Two.cfg` | 0 | 7 | 4 |
| `One.cfg` | 12 | 3 | 3 |
| `Phantom.cfg` | 10 | | |
| `PhantomNoAssume.cfg` | **0** | 3 | 3 |
| `Three.cfg` | 0 | 13 | 4 |
| `ThreeSym.cfg` | 0 | 4 | 4 |

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | stands for |
|---|---|---|
| `G04Two.tla` | rc 0 | `Two.cfg`, the answer, 7 states |
| `G04One.tla` | rc 12 | `One.cfg`, the requirement false on a one-ship harbour |
| `G04Phantom.tla` | rc 10 | `Phantom.cfg`, the sentinel listed as a ship, refused |
| `G04PhantomNoAssume.tla` | rc 0 | `PhantomNoAssume.cfg`, the same with the line deleted, green and wrong |
| `G04Three.tla` | rc 0 | `Three.cfg`, 13 states |
| `G04ThreeSym.tla` | rc 0 | `ThreeSym.cfg`, the wrapper with symmetry, 4 states |

## why-not-in-prompt

The prompt says "refused before the first state, exit 10" and "a line in
the dock", so the reader knows there's a guard and where it lives. It
says "brings the dock in whole" for the wrapper and "told they're
interchangeable" for symmetry.

What the prompt withholds: the keyword for the guard, that it has to say
the sentinel is not a member, that bare names in a config are model
values and that model values don't stop a membership, which keyword
brings a module in whole, and that permutations come from the `TLC`
module.

The honest caveat: this is `state-space/07` in different clothing. That
item measured the string collision with the assumption deleted. This one
measures the model-value version, which the sibling's answer said
couldn't happen, and adds the wrapper file. A reader who did the sibling
recently will recall the shape from the table alone. I kept it because
the model-value result is the one that surprised me, and because the
learner's own example of what he can't retrieve is this keyword.
