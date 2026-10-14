# Convoys: answer

## The answer

```tla
---- MODULE ConvoyAnswer ----
EXTENDS Naturals, FiniteSets

CONSTANTS Trucks, MaxConvoy

VARIABLES atDepot, convoys

vars == <<atDepot, convoys>>

OnRoad == UNION convoys

TypeOK ==
  /\ atDepot \subseteq Trucks
  /\ convoys \subseteq SUBSET Trucks

Init ==
  /\ atDepot = Trucks
  /\ convoys = {}

Leave ==
  \E t \in atDepot :
    /\ atDepot' = atDepot \ {t}
    /\ convoys' = convoys \cup {{t}}

Merge ==
  \E c, d \in convoys :
    /\ c /= d
    /\ Cardinality(c \cup d) <= MaxConvoy
    /\ convoys' = (convoys \ {c, d}) \cup {c \cup d}
    /\ UNCHANGED atDepot

Arrive ==
  \E c \in convoys :
    /\ convoys' = convoys \ {c}
    /\ UNCHANGED atDepot

Next == Leave \/ Merge \/ Arrive

Spec == Init /\ [][Next]_vars

NowhereTwice ==
  /\ atDepot \cap OnRoad = {}
  /\ \A c, d \in convoys : c /= d => c \cap d = {}

NeverOversized == \A c \in convoys : Cardinality(c) <= MaxConvoy

NoEmptyConvoy == {} \notin convoys
====
```

```
SPECIFICATION Spec
CONSTANTS
  Trucks = {t1, t2, t3, t4}
  MaxConvoy = 3
CHECK_DEADLOCK FALSE
INVARIANTS
  TypeOK
  NowhereTwice
  NeverOversized
  NoEmptyConvoy
```

A convoy is the set of trucks in it, so the convoys on the road are a set whose
members are themselves sets. That one sentence is the whole item. Every operator
below it follows from it, and every wrong neighbor is a reader who held a set of
sets and then handled it like a set of trucks.

Two unions do two jobs here and they're easy to swap. `c \cup d` joins two
convoys into one. `UNION convoys` flattens the whole collection down into the
trucks in it, and that's the only way to ask "which trucks are on the road" when
the state doesn't hold that set. The type line needs the powerset for the same
reason: `convoys` is drawn from the sets of trucks, not from the trucks.

`CHECK_DEADLOCK FALSE` is in the config because an empty road with an empty depot
is a terminal state and it's meant to be one. Every truck has arrived.

## The trap, and why the item exists

`Merge` has to put one new convoy into the collection, and the braces around it
are the whole difference:

```tla
convoys' = (convoys \ {c, d}) \cup c \cup d       \* wrong
convoys' = (convoys \ {c, d}) \cup {c \cup d}     \* right
```

The wrong line reads well out loud. Take the two convoys out, then add the trucks
of both back in. What it adds back is the trucks themselves, as members of a set
whose members are supposed to be sets. So after one merge `convoys` holds two
trucks and one or two convoys at the same time, and the state is no longer the
shape the type line describes.

That one fails at rc 76 rather than rc 12, which I think is the interesting part.
TLC can't finish evaluating `TypeOK`, because `convoys \subseteq SUBSET Trucks`
asks whether a truck is one of the sixteen sets of trucks and a model value isn't
enumerable. The report names the value and the set it was held against:

```
Error: Evaluating invariant TypeOK failed.
Attempted to check if the non-enumerable value
t1
is element of
{ {}, {t1}, {t2}, ... }
```

So the diagnosis is handed over, as long as the reader knows an evaluation failure
isn't a violation. It arrives 20 states in, after two trucks have left and merged.

## The other three

Each of the other wrong neighbors fails in a different channel, which is why all
four are kept.

The binary union used where the flattening was meant doesn't parse. It takes two
operands and there's only one, so the message comes from the parser rather than
from the model checker, and it names the line and the token:

```
Was expecting "==== or more Module body"
Encountered "convoys" at line 13, column 16 and token "\cup"
```

Rule 3 written with the subset relation instead of membership is false in every
state, starting with the first. The empty set is a subset of every set, including
the empty collection the depot starts with, so negating it can never hold. TLC
reports it against the initial state and never takes a step.

`Merge` that adds the joined convoy and forgets to take its two sources out is
the ordinary mutant, and rule 1 catches it on the first merge. A truck is then in
the joined convoy and in the convoy it came from, which is the second half of
rule 1 rather than the first.

## Variants

- `NoEmptyConvoy` as `\A c \in convoys : c /= {}`. Same thing
- the first half of rule 1 as `\A t \in atDepot : \A c \in convoys : t \notin c`
- `Arrive` restricted to a convoy at its size cap. Narrower, still checks clean
- `Leave` and `Merge` folded into one action, a truck joining a convoy directly

The fourth changes the state count, so it fails the prompt's 150 even though the
three rules hold. I'd accept it in review and I wouldn't accept it from the
prompt as written, since the prompt says a truck leaves alone.

## Measured

Every run from `bash drill/sets/verify-item.sh drill/sets/04-convoys` on
TLC2 Version 2026.07.31.184830, `-workers 1`. Each module has a config of its
own name. The rc is what `harness/verdict.sh` returned.

| module | rc | distinct | what it is |
|---|---|---|---|
| `ConvoyAnswer` | rc 0 | 150 | the answer, three rules |
| `ConvoyMergeFlat` | rc 76 | 20 | the merge unions the trucks in, not the convoy |
| `ConvoyCupSpelling` | rc 150 | parse | the binary union where the flattening was meant |
| `ConvoyEmptySubseteq` | rc 12 | initial | rule 3 by the subset relation, false everywhere |
| `ConvoyMergeKeeps` | rc 12 | 18 | the merge keeps its two sources. Rule 1 names it |

Two of the five log no distinct count. The parse error means TLC never started,
and the subset spelling fails during the initial-state computation, which is
before the line that reports a count.

The two numbers next to each other are worth a look. 150 is a parse failure and
150 is also the answer's state count, which is a coincidence of this item and
not a pattern. The columns tell them apart and nothing else does.

## Elimination table

| wrong neighbor | what kills it | rc |
|---|---|---|
| the merge unions the trucks into the collection | type line can't evaluate, 20 states | 76 |
| the binary union used to flatten a collection | the parser, before TLC runs | 150 |
| rule 3 by the subset relation | false in the initial state | 12 |
| the merge keeps the two convoys it joined | rule 1, second half, first merge | 12 |
| the type line without the powerset (not measured) | rule 1 stays green, the shape is wrong | 0 |

## Why not in prompt

The prompt says a convoy is a group of trucks and that two groups can join into
one. It never says the road holds a collection whose members are groups, which is
the step the reader has to take. Nor does it name either union, and the two of
them are what the item is for.

The caveat I'd flag is the state count. 150 pins the transition structure fairly
hard: a truck leaves alone, any two convoys may join under the cap, a convoy
arrives whole. A reader who merges on the way out of the depot writes a defensible
system that comes in at a different count, and the prompt forecloses him by
arithmetic rather than by saying so. That's the cost of putting a number in, and
on this item I'd still pay it, because without it the merge-flattening error at
rc 76 reads like a harness problem rather than a modeling one.
