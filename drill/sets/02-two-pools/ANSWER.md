# Two pools: answer

## The answer

```tla
---- MODULE PoolsSets ----
EXTENDS Naturals, FiniteSets

CONSTANTS Guards, Trainee

ASSUME Trainee \in Guards

VARIABLES lanes, leisure

vars == <<lanes, leisure>>

TypeOK ==
  /\ lanes \subseteq Guards
  /\ leisure \subseteq Guards

Init == lanes = {} /\ leisure = {}

MayLeave(pool, g) == g \in pool => pool \ {g} /= {Trainee}

MayJoin(pool, g) ==
  /\ g \notin pool
  /\ Cardinality(pool) < 2
  /\ g = Trainee => pool /= {}

ToLanes ==
  \E g \in Guards :
    /\ MayJoin(lanes, g)
    /\ MayLeave(leisure, g)
    /\ lanes' = lanes \cup {g}
    /\ leisure' = leisure \ {g}

ToLeisure ==
  \E g \in Guards :
    /\ MayJoin(leisure, g)
    /\ MayLeave(lanes, g)
    /\ leisure' = leisure \cup {g}
    /\ lanes' = lanes \ {g}

ToBreak ==
  \E g \in lanes \cup leisure :
    /\ MayLeave(lanes, g)
    /\ MayLeave(leisure, g)
    /\ lanes' = lanes \ {g}
    /\ leisure' = leisure \ {g}

Next == ToLanes \/ ToLeisure \/ ToBreak

Spec == Init /\ [][Next]_vars

NobodyAtBoth == lanes \cap leisure = {}

AtMostTwo == Cardinality(lanes) <= 2 /\ Cardinality(leisure) <= 2

TraineeNeverAlone == lanes /= {Trainee} /\ leisure /= {Trainee}
====
```

```
SPECIFICATION Spec
CONSTANTS
  Guards = {a, b, c, d}
  Trainee = d
INVARIANTS
  TypeOK
  NobodyAtBoth
  AtMostTwo
  TraineeNeverAlone
```

One set per pool, holding the guards at it. A guard on a break is in neither
set, and that third place is what makes `ToBreak` a separate action. Rule 1 is
an intersection, rule 2 a pair of counts, rule 3 a pair of inequalities against
a one-member set.

The two guard operators are where the work is. `MayJoin` asks for room and for
company when the trainee is the one arriving. `MayLeave` is the same rule read
backwards: a guard may go only when going doesn't strand the trainee behind
him. Rule 3 needs both halves, and I'd expect most readers to write the first
and miss the second.

## The trap, and why the item exists

The prompt says three guards may never be at one pool, and that reads like a
number. So the obvious state is two numbers, how many guards are in the lanes
and how many are in the leisure pool:

```tla
VARIABLES nLanes, nLeisure

OnBreak == N - nLanes - nLeisure

AtMostTwo == nLanes <= 2 /\ nLeisure <= 2
```

Rule 2 goes straight in. The other two can't be written at all. "No guard is at
both pools" is a sentence about a guard, and this state has no guards in it.
Neither does "the trainee is never the only one at a pool", because the state
can't say which guard the one is.

So the config carries two of the three names, TLC reports no error, and the run
finds 9 distinct states against the answer's 49. A reader who has stopped at
rule 2 has a green model of a system he hasn't described. I think the count is
the only signal available here, since a model with two rules missing is quiet in
every other way.

The lesson I'd take out of it: a count answers how many and a set answers who,
and a rule that names an individual needs the second. The arithmetic encoding
isn't wrong, it's thinner than the rules are.

## Variants

Three other encodings record identity, and all three check clean at the same 49
distinct states. That the counts agree is the useful part: the four states are
the same state wearing different clothes.

- a set of pairs, guard and pool, with a guard on a break in no pair
- one function from pool to the set of guards at it
- one function from guard to place, where a break is a third place

The pairs form says rule 1 as "no guard appears in two pairs", which the two-set
form said with an intersection. The function-from-guard form gets rule 1 for
free, since a function gives one value per guard, and I'd still state it so the
config carries all three names. The function-from-pool form is the only one that
covers both pools in a single action, because the pool it moves to is a bound
variable rather than a variable name.

## Measured

Every run from `bash drill/sets/verify-item.sh drill/sets/02-two-pools` on
TLC2 Version 2026.07.31.184830, `-workers 1`. Each module has a config of its
own name. The rc is what `harness/verdict.sh` returned.

| module | rc | distinct | what it is |
|---|---|---|---|
| `PoolsSets` | rc 0 | 49 | the answer, one set per pool |
| `PoolsPairs` | rc 0 | 49 | a set of pairs. Accepted |
| `PoolsCrew` | rc 0 | 49 | a function from pool to crew. Accepted |
| `PoolsWhere` | rc 0 | 49 | a function from guard to place. Accepted |
| `PoolsCounts` | rc 0 | 9 | two numbers. Two rules unstatable, and it passes |
| `PoolsNoCap` | rc 12 | 26 | joining checks no room. `AtMostTwo` names it |
| `PoolsStayPut` | rc 12 | 11 | the move keeps the old pair. `NobodyAtBoth` names it |
| `PoolsTraineeAlone` | rc 12 | 5 | no company rule. `TraineeNeverAlone` names it |

The five rows at rc 0 split three to two. Four of them hold who is where and
agree on the count. The fifth holds how many and comes in 40 states short.

## Elimination table

| wrong neighbor | what kills it | rc |
|---|---|---|
| two numbers for the two pools | rules 1 and 3 can't be stated, 9 states | 0 |
| joining without the room check | a third guard walks in, rule 2 | 12 |
| the move adds the new place and keeps the old | rule 1 on the first move | 12 |
| the company rule dropped from both operators | rule 3, the trainee alone | 12 |
| the company rule on joining only | rule 3, the last senior leaves (not measured) | 12 |

The last row is the half of rule 3 I expect to go missing. Guarding the arrival
and not the departure leaves the trainee alone by subtraction, and the trace is
one state longer than the trace for dropping both.

## Why not in prompt

The prompt names three rules and a state count and no structure. Rule 1 and rule
3 are the ones that do the foreclosing, because each is a sentence about a named
guard and neither survives translation into arithmetic. So the reader who
reaches for two numbers finds out from the rules, not from me.

The honest caveat is that the foreclosing is soft. Nothing in the prompt says
the state has to hold identities, and a reader can write rule 2 alone, get a
clean exit, and stop. The 49 is in the prompt as the backstop for exactly that
reader, and 9 against 49 is a wide enough gap to notice. It's still a number he
has to bother comparing.

The trainee is in the prompt as a named individual rather than as "one guard",
which I think is the strongest nudge available without naming a construct. A
rule about a particular member of a set is hard to hold in a count, and the
reader meets that resistance while he's writing rule 3 rather than after.
