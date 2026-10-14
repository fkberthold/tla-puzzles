# Ballast tanks: answer

## The answer

```tla
---- MODULE Ballast ----
EXTENDS Naturals
CONSTANTS Fore, Port, Stbd, Cap

Tanks == {Fore, Port, Stbd}

VARIABLE level
vars == <<level>>

TypeOK == level \in [Tanks -> 0..Cap]

Aboard == level[Fore] + level[Port] + level[Stbd]

Init == level = [t \in Tanks |-> 2]

Pump(a, b) == /\ a /= b
              /\ level[a] > 0
              /\ level[b] < Cap
              /\ level' = [level EXCEPT ![a] = @ - 1, ![b] = @ + 1]

Next == \E a, b \in Tanks : Pump(a, b)

Spec == Init /\ [][Next]_vars

Conserved == Aboard = 6
====
```

```
SPECIFICATION Spec
INVARIANTS TypeOK Conserved
CHECK_DEADLOCK TRUE
CONSTANTS
  Fore = Fore
  Port = Port
  Stbd = Stbd
  Cap = 4
```

The rule the last two rows break is `Conserved`: the three gauges always add
to 6. Row three breaks `TypeOK` instead, which is the capacity.

Hand count. Ways to split 6 across three tanks with no cap: 28. Splits with
a tank at 5 or more: 3 per tank, so 9. That leaves 19, and every one of
them is reachable from 2, 2, 2 by single-unit moves. TLC found 19.

## One step, two cells

`[level EXCEPT ![a] = @ - 1, ![b] = @ + 1]` is one function. Each `@` is
the old value at that clause's own key: `level[a]` in the first clause and
`level[b]` in the second. It is not "the function", and it is not the same
number in both places.

Two clauses in one update is how two cells change in one step. The fourth
row of the table, 2, 2, 1 never seen, is what demands one step: a pump that
draws on one step and fills on the next shows a reading of 5 in between.

Three ways to write the same step, all measured at 19:

| spelling | module | states |
|---|---|---|
| two clauses in one update | `Ballast` | 19 |
| two updates nested, inner first | `BallastNested` | 19 |
| the function rebuilt with a conditional per tank | `BallastRebuild` | 19 |

The nested form is what the two-clause form abbreviates. The rebuild is
longest and says the same thing.

## The neighbors

`BallastTwoStep` is the programmer's pump. `Draw(a)` takes a unit into a
hose variable, `Fill(b)` puts it in. rc 12 on `Conserved` at the second
state, the first draw. The table's fourth row, in the checker's words.

`BallastTwoExcepts` is the one worth a minute. It writes the two cells as
two single-clause updates and conjoins them:

```tla
/\ level' = [level EXCEPT ![a] = @ - 1]
/\ level' = [level EXCEPT ![b] = @ + 1]
```

Each line is a complete statement of what the whole new function is, and
the two disagree on both tanks, so no next state satisfies `Pump`. The
parser has nothing to say about it. With deadlock checking on, rc 11 at one
state: the barge never pumps. The same module with the keyword off
(`BallastTwoExceptsQuiet`) is rc 0 at one state, and both invariants hold
on it. That's the silent shape. A clean verdict on a barge that never
moved a unit, and the count of 1 is the only tell.

`BallastAtApplied` reads `@` as the function and writes `![b] = @[b] + 1`.
In that clause `@` is `level[b]`, a number, and rc 75: "A non-function (an
integer) was applied as a function."

## Acceptable variants

- Nested or rebuilt, as in the table above. Same 19.
- `Pump` without `a /= b`. A self-pump nets to zero, since the second
  clause's `@` is the already-lowered value. I'd expect the same 19 and I
  didn't measure it.
- `Conserved` written as `Aboard = Cap + 2`. Same thing at this model size
  and worse at any other. The 6 is the launch load, not a function of the
  cap.

## Elimination table

| neighbor answer | what kills it |
|---|---|
| draw on one step, fill on the next | row four, 2, 2, 1. rc 12, measured |
| no capacity guard on the destination | row three, 5, 1, 0. `TypeOK` would go red. Not measured |
| a pump that adds a unit to both tanks | row five, 3, 3, 1. `Conserved`. Not measured |
| two single-clause updates conjoined | nothing in the table. Only the count, or deadlock checking. Measured |

## Why not in prompt

Rows four and five state the conservation rule in numbers rather than in
words, and "one unit at a time" with "the gauges are read together" is the
atomicity in prose. The prompt gives the 19 and nothing else.

The honest caveat is that a reader who has met a bank-transfer example
reaches for the two-clause form by smell, and no table row can stop that.
I don't think it should. The point is writing it from nothing, and what the
item adds over the memory is the three measured mis-spellings, in
particular the conjoined pair, which looks right, parses, and checks clean
with deadlock checking off.

## Measured runs

Each row is a line of `bash drill/functions-records/verify-all.sh 03`. `-d`
is passed where the config says `CHECK_DEADLOCK TRUE`, which is every config
but the quiet one.

| module | config | rc | distinct states |
|---|---|---|---|
| `Ballast.tla` | `Ballast.cfg` | rc 0 | 19 |
| `BallastNested.tla` | `BallastNested.cfg` | rc 0 | 19 |
| `BallastRebuild.tla` | `BallastRebuild.cfg` | rc 0 | 19 |
| `BallastTwoStep.tla` | `BallastTwoStep.cfg` | rc 12 | 2 |
| `BallastTwoExcepts.tla` | `BallastTwoExcepts.cfg` | rc 11 | 1 |
| `BallastTwoExceptsQuiet.tla` | `BallastTwoExceptsQuiet.cfg` | rc 0 | 1 |
| `BallastAtApplied.tla` | `BallastAtApplied.cfg` | rc 75 | 1 |
