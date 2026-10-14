# The dive: answer

## The answer

```tla
---- MODULE DiveAnswer ----
CONSTANT Divers

VARIABLES checkedIn, descended, calledOff

vars == <<checkedIn, descended, calledOff>>

TypeOK ==
  /\ checkedIn \subseteq Divers
  /\ descended \subseteq Divers
  /\ calledOff \subseteq Divers

Init ==
  /\ checkedIn = {}
  /\ descended = {}
  /\ calledOff = {}

CheckIn ==
  /\ \E d \in Divers \ checkedIn : checkedIn' = checkedIn \cup {d}
  /\ UNCHANGED <<descended, calledOff>>

Descend ==
  /\ checkedIn = Divers
  /\ calledOff = {}
  /\ \E d \in Divers \ descended : descended' = descended \cup {d}
  /\ UNCHANGED <<checkedIn, calledOff>>

CallOff ==
  /\ \E d \in Divers \ (descended \cup calledOff) :
       calledOff' = calledOff \cup {d}
  /\ UNCHANGED <<checkedIn, descended>>

Next == CheckIn \/ Descend \/ CallOff

Spec == Init /\ [][Next]_vars

AllInBeforeAnyDown == descended /= {} => checkedIn = Divers

NoCallerDown == descended \cap calledOff = {}
====
```

```
SPECIFICATION Spec
CONSTANT Divers = {d1, d2, d3, d4}
CHECK_DEADLOCK FALSE
INVARIANTS
  TypeOK
  AllInBeforeAnyDown
  NoCallerDown
```

Three sets of divers and nothing else. No module is extended, since
nothing is counted or added. Every guard is a set relation: equal to the
whole group, equal to empty, a difference to draw from, an intersection
that stays empty. The config turns off the deadlock check because a group
that's all down has nothing left to do, and that's the intended end.

## What TLC should report after the break

`Invariant AllInBeforeAnyDown is violated.` with a trace of three states:
one check-in, then that diver down. Measured at 13 distinct states.

## The trap

Rule 1 has a tempting spelling that mentions both sets and reads right:

```tla
AllInBeforeAnyDown == descended \subseteq checkedIn
```

Whoever is down had checked in. True, and too weak. It says nothing about
the divers who haven't checked in yet, and the broken model keeps it,
since the early diver did check in before going down. The run is clean at
625 distinct states. The rule the prompt asks for is a different claim: if
anyone at all is down, everyone has checked in. The subset relation is
implied by it and doesn't imply it back.

The count is what catches the weak spelling. 625 isn't 321.

## Measured

Every run from `bash drill/sets/verify-item.sh drill/sets/08-the-dive` on
TLC2 Version 2026.07.31.184830, `-workers 1`. Each module has a config of
its own name. The rc is what `harness/verdict.sh` returned.

| module | rc | distinct | what it is |
|---|---|---|---|
| `DiveAnswer` | rc 0 | 321 | the answer |
| `DiveEarlyDescent` | rc 12 | 13 | the break-it step. Rule 1 names it |
| `DiveWeakRule` | rc 0 | 625 | the break-it step with the subset spelling of rule 1 |
| `DiveDescendAfterCall` | rc 12 | 242 | `Descend` ignores a call-off. Rule 2 names it |
| `DiveCallFromBelow` | rc 12 | 227 | `CallOff` open to divers underwater. Rule 2 names it |

The 321 is 256 states with nobody down, any check-in set against any
call-off set, plus 65 with somebody down, where everyone has checked in
and the callers are drawn from the divers on the surface.

## Elimination table

| wrong neighbour | what kills it | rc |
|---|---|---|
| `Descend` without the all-in guard | rule 1, first diver down | 12 |
| rule 1 as `descended \subseteq checkedIn` | nothing in TLC. 625 states against 321 | 0 |
| `Descend` without the no-call-off guard | rule 2, a caller goes down | 12 |
| `CallOff` drawn from everyone | rule 2, a diver calls off from below | 12 |
| `CHECK_DEADLOCK` left on | deadlock when the group is all down, and it's the intended end | 11 |

The last row I didn't give a module, since the state-space family owns
the deadlock lesson. It's the plain run with the config line removed, and
the rc follows from the `verdict.sh` table.

## Variants

- rule 1 as `descended = {} \/ checkedIn = Divers`
- rule 1 as `\A d \in descended : checkedIn = Divers`, which quantifies to say the same thing
- rule 2 as `\A d \in Divers : ~(d \in descended /\ d \in calledOff)`
- `CallOff` guarded by `d \notin descended` as a separate conjunct rather than in the draw

## Why not in prompt

"Every diver has checked in" is equality with the whole group in prose,
and "nobody is down before" is the implication. The reader has to retrieve
both from the English, and the prompt withholds the word "subset" so the
weak spelling can't be read off the page either. The break-it step is
where the weak spelling gets caught, since it reports nothing on the
broken model.

The honest caveat: without the count, the weak spelling passes every run
in this item, and a reader who skips the break-it step never meets it. I
think the count is enough, and it's the only thing standing between the
subset relation and a clean submission. The item is also the lightest in
the family, three sets and no arithmetic, and I'd put it first on a cold
day rather than last.
