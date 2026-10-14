# Troughs: answer

## The answer

```tla
---- MODULE Troughs ----
EXTENDS Naturals
CONSTANTS N, Cap, Supply

Troughs == 1..N

VARIABLES bowser, trough, drunk
vars == <<bowser, trough, drunk>>

Total[n \in 0..N] == IF n = 0 THEN 0 ELSE Total[n - 1] + trough[n]

TypeOK == /\ bowser \in 0..Supply
          /\ trough \in [Troughs -> 0..Cap]
          /\ drunk \in 0..Supply

Init == /\ bowser = Supply
        /\ trough = [t \in Troughs |-> 0]
        /\ drunk = 0

Pour(t) == /\ bowser > 0
           /\ trough[t] < Cap
           /\ bowser' = bowser - 1
           /\ trough' = [trough EXCEPT ![t] = @ + 1]
           /\ UNCHANGED drunk

Drink(t) == /\ trough[t] > 0
            /\ trough' = [trough EXCEPT ![t] = @ - 1]
            /\ drunk' = drunk + 1
            /\ UNCHANGED bowser

Next == \E t \in Troughs : Pour(t) \/ Drink(t)

Spec == Init /\ [][Next]_vars

Conserved == bowser + Total[N] + drunk = Supply
====
```

```
SPECIFICATION Spec
INVARIANTS TypeOK Conserved
CHECK_DEADLOCK FALSE
CONSTANTS
  N = 3
  Cap = 2
  Supply = 5
```

The number of troughs is a parameter, so "the water in the troughs" is a
sum over `1..N`, and a sum over a parameter is a function defined by
recursion on its own index. `Total[n]` is the water in the first `n`
troughs. No declaration is needed. A function can refer to itself inside
its own definition, and an operator can't without one.

Hand count at three troughs. The three troughs hold 0 to 2 each, 27
vectors, less the one at 2, 2, 2 which needs 6 units. For a vector holding
`s` units the bowser and the cattle split the other `5 - s`, which is
`6 - s` ways. Sum that over the 26 vectors and it comes to 81. TLC found
81. At four troughs TLC found 168, and I didn't count that one by hand.

## A function, or an operator with a declaration

`TroughsNoRecursive` writes the sum as an operator:
`Total(n) == IF n = 0 THEN 0 ELSE Total(n - 1) + trough[n]`. rc 150,
"Unknown operator: `Total'". An operator's name isn't in scope inside its
own body unless it was declared first.

`TroughsRecursiveOp` adds the line `RECURSIVE Total(_)` above it. rc 0 at
81. Both spellings are right. The function form needs one line fewer and
reads as what it is, a value indexed by `n`.

## The sum you wrote by hand

`TroughsHardcoded` writes `Conserved` as
`bowser + trough[1] + trough[2] + trough[3] + drunk = Supply`.

At three troughs it's right: `TroughsHardcodedThree`, rc 0 at 81, the same
81 as the reference. At four troughs, rc 12 at the second state. `Pour(4)`
puts a unit in a trough the sum can't see, and the rule goes red on a
model that has no bug in it. The property has the bug. That's what the
"then again at four" in the prompt is for: the hand-written sum passes at
the size it was written for, and a passing run is where it hides.

## Acceptable variants

- The declared recursive operator, as measured.
- `Total` as a fold over the set of troughs with a `CHOOSE` to pick an element each round. Same answer, longer, not measured.
- `Conserved` with `drunk` folded into a lower bound instead of a count. That's a different rule, and the prompt's "a unit drunk is gone" wants it counted.

## Elimination table

| neighbour answer | what kills it |
|---|---|
| the sum written out for three troughs | the four-trough run. rc 12, measured |
| operator recursion with no declaration | rc 150, measured |
| conservation stated without `drunk` | the first drink. rc 12 I'd expect. Not measured |
| troughs as three named constants | the four-trough run can't be set up. Not measured |

## Why not in prompt

"With the number of troughs as a parameter" and "then again at four" are
the whole foreclosure. A sum that works at three and fails at four is the
item, and the second count in the prompt is what makes the hand-written
sum visible.

The honest caveat is that a reader who has written a recursive sum before
reaches for it by smell, and the prompt adds only the second run. I think
the second run is worth having anyway. The hand-written sum passes at
three, with the same 81 as the reference, and nothing short of a second
size says otherwise.

## Measured runs

Each row is a line of `bash drill/functions-records/verify-all.sh 08`. No
config here asks for deadlock checking, so no `-d` is passed.

| module | config | rc | distinct states |
|---|---|---|---|
| `Troughs.tla` | `Troughs.cfg` | rc 0 | 81 |
| `TroughsFour.tla` | `TroughsFour.cfg` | rc 0 | 168 |
| `TroughsRecursiveOp.tla` | `TroughsRecursiveOp.cfg` | rc 0 | 81 |
| `TroughsHardcodedThree.tla` | `TroughsHardcodedThree.cfg` | rc 0 | 81 |
| `TroughsHardcoded.tla` | `TroughsHardcoded.cfg` | rc 12 | 5 |
| `TroughsNoRecursive.tla` | `TroughsNoRecursive.cfg` | rc 150 | none |
