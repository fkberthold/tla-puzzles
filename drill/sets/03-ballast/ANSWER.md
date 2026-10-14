# Ballast: answer

## The answer

```tla
---- MODULE BallastAnswer ----
EXTENDS Naturals, FiniteSets

CONSTANTS Tanks, Port

ASSUME Port \subseteq Tanks

Starboard == Tanks \ Port

VARIABLE full

vars == <<full>>

TypeOK == full \subseteq Tanks

Lean(side) == Cardinality(full \cap side)

Balanced ==
  /\ Lean(Port) <= Lean(Starboard) + 1
  /\ Lean(Starboard) <= Lean(Port) + 1

Init ==
  /\ full \in SUBSET Tanks
  /\ Balanced

Fill ==
  \E t \in Tanks \ full :
    /\ full' = full \cup {t}
    /\ Balanced'

Pump ==
  \E t \in full :
    /\ full' = full \ {t}
    /\ Balanced'

Next == Fill \/ Pump

Spec == Init /\ [][Next]_vars

NeverLists == Balanced
====
```

```
SPECIFICATION Spec
CONSTANTS
  Tanks = {p1, p2, p3, s1, s2, s3}
  Port = {p1, p2, p3}
INVARIANTS
  TypeOK
  NeverLists
```

One variable, the set of full tanks. "Any arrangement that obeys the rule"
is a draw from the powerset, filtered by the rule, and that's the line the
item is built around. `SUBSET Tanks` is the set of all 64 arrangements.
The rule keeps 50 of them, and every fill or pump stays inside the 50.

The name misleads. `SUBSET S` is the powerset of `S`, a set of sets. The
subset test is `\subseteq`, and the two are related by
`x \in SUBSET S` being the same as `x \subseteq S`.

## What TLC should report after the break

`Invariant NeverLists is violated.` with a trace of one state and no step.
`Init` now draws all 64 arrangements, and TLC checks the invariant on
initial states before it takes a step, so the first unbalanced draw is the
report.

## Measured

Every run from `bash drill/sets/verify-item.sh drill/sets/03-ballast` on
TLC2 Version 2026.07.31.184830, `-workers 1`. Each module has a config of
its own name. The rc is what `harness/verdict.sh` returned.

| module | rc | distinct | what it is |
|---|---|---|---|
| `BallastAnswer` | rc 0 | 50 | the answer |
| `BallastAnyStart` | rc 12 | 1 | the break-it step, rule dropped from `Init` |
| `BallastNoGuard` | rc 12 | 51 | `Fill` without the rule on the new arrangement |
| `BallastOneLevelUp` | rc 75 | 2 | type line one level up, `full \subseteq SUBSET Tanks` |
| `BallastBinary` | rc 150 | parse | the keyword used between two sets |
| `BallastSubseteq` | rc 0 | 50 | `full \subseteq Tanks` in `Init`. Accepted, see below |

`BallastAnyStart` reports before any step, so the log carries no distinct
count. I've written 1 for the one state in the trace.

## Elimination table

| wrong neighbor | what kills it | rc |
|---|---|---|
| rule only in the actions, not in `Init` | the first unbalanced draw | 12 |
| `Fill` without the rule on the result | two fills down one side | 12 |
| `full \subseteq SUBSET Tanks` as the type | TLC can't ask whether a tank is a set of tanks | 75 |
| `full SUBSET Tanks` as a test | the parser, it's a prefix operator | 150 |
| `Balanced'` written as `Balanced` in `Fill` | passes, 50 states, and I'd flag it in review |

The last row is the one that costs nothing in TLC. Guarding on the old
arrangement lets a fill through that breaks the rule, and then the rule
catches it. Measured at rc 12 with the guard gone entirely, so the
unprimed guard is the same defect with extra typing. I didn't give it its
own module.

## Variants

- the draw in `Init` as `full \subseteq Tanks`, which TLC accepts
- `Lean(Starboard)` as `Cardinality(full \ Port)`
- `Balanced` on the primed state as a guard computed from `full'` by hand
- the rule as one line, `Lean(Port) - Lean(Starboard) \in -1..1`, with `Integers`

The first one I expected to fail. A subset relation in `Init` reads as a
sentence about a value TLC doesn't have yet, and I predicted a refusal.
TLC takes it as a draw from the powerset and finds the same 50 states. So
a reader who misremembers the keyword as a subset test, and writes the
relation instead, gets the right answer here and never learns the
difference. The difference turns up the day he needs the powerset as a
value, to quantify over arrangements, and the relation has nothing to
offer.

## Why not in prompt

"Any arrangement that obeys the rule" is the powerset in prose. The reader
has to retrieve the keyword for it, and the prompt withholds the word
"subset" so the keyword's name can't be read off the page. The break-it
step is there so the reader sees where the draw lives: a rule that's only
in the actions is a rule about steps, and the first state isn't a step.

The honest caveat: TLC accepts the subset relation as a draw, measured
above, so the misreading this item was built to catch passes the item. The
count doesn't catch it and the rule doesn't. What's left is the type line
one level up and the binary misuse, and both are loud. I suspect the
reader who learns most here is the one who writes the relation, reads the
answer, and finds out it worked by accident of the tool.
