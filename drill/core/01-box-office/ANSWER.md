# Box office: answer

## The answer

```tla
---- MODULE BoxOffice ----
EXTENDS Naturals

CONSTANTS Seats, Fare

VARIABLES free, takings

vars == <<free, takings>>

TypeOK ==
  /\ free \in 0..Seats
  /\ takings \in Nat

Init ==
  /\ free = Seats
  /\ takings = 0

TakeSeat ==
  /\ free > 0
  /\ free' = free - 1

RecordFare ==
  takings' = takings + Fare

ReleaseSeat ==
  /\ free < Seats
  /\ free' = free + 1

ReturnFare ==
  /\ takings >= Fare
  /\ takings' = takings - Fare

Book == TakeSeat /\ RecordFare

Refund == ReleaseSeat /\ ReturnFare

Next == Book \/ Refund

Spec == Init /\ [][Next]_vars

TakingsMatchSeats == takings = (Seats - free) * Fare
====
```

```
SPECIFICATION Spec
CONSTANTS
  Seats = 3
  Fare = 10
INVARIANTS
  TypeOK
  TakingsMatchSeats
```

The two halves are partial actions. `TakeSeat` says what happens to `free` and
nothing about `takings`. `RecordFare` says what happens to `takings` and nothing
about `free`. `Book` is their conjunction, and only the conjunction is a complete
step. Neither half appears in `Next` on its own.

## The trap

`x' = e` is an equation, not an assignment. A reader from imperative code writes
each half as a complete action, because every other item says an action must
constrain every variable. So `TakeSeat` ends with `UNCHANGED takings` and
`RecordFare` ends with `UNCHANGED free`. The conjunction then asks for
`takings' = takings` and `takings' = takings + Fare` in the same step. No state
satisfies both, so `Book` has no successor. Same for `Refund`. TLC reports a
deadlock in the initial state.

Nothing points at a line. The invariants are green, because they were checked
on one state. Every guard reads right. The only number that moved is the state
count, and it moved to 1.

## Measurements

From `verify/`, each run was
`tlc -workers 1 -noGenerateSpecTE -metadir states/<name> <Module>.tla -config <Module>.cfg`.
Every module has its own config. The two trapped configs end with
`CHECK_DEADLOCK TRUE` and the other three are identical.

| module | what | rc | generated | distinct | TLC says |
|---|---|---|---|---|---|
| `BoxOffice` | reference | rc 0 | 7 | 4 | no error |
| `HalvesComplete` | `UNCHANGED` inside each half | rc 11 | 1 | 1 | `Deadlock reached.` |
| `HalfAlone` | `Book == TakeSeat` alone | rc 75 | 2 | 1 | `Successor state is not completely specified by action TakeSeat of the next-state relation. The following variable is not defined: takings.` |
| `DoubleFare` | fare recorded twice, correct shape | rc 12 | 2 | 2 | `Invariant TakingsMatchSeats is violated.` |
| `HiddenDefect` | fare recorded twice, trapped shape | rc 11 | 1 | 1 | `Deadlock reached.` |

The last row is the point of the item. A real defect in the fare rule is
invisible in the trapped spec, because no step is ever taken. 11 against 12 is
the diagnosis. 12 says a step broke a rule. 11 says there were no steps.

The third row is the other way to get the halves wrong. A partial action placed
in `Next` by itself leaves a variable with no value, and TLC refuses rather than
guessing. That one is loud, and it names the action and the variable.

A word on the keyword. `tlc` on the command line checks for deadlock by
default, so the reader sees the 11 without it. `harness/verdict.sh` passes
`-deadlock`, which turns the check off, unless it's asked for it, and the drill
gate asks only when the config says `CHECK_DEADLOCK TRUE`. Without the keyword
the two one-state rows exit 0 on the same single state: no deadlock, no error,
every invariant green. The flag beats the keyword in the other direction too.
I tried the keyword against a run with `-deadlock` on the command line and it
stayed a clean exit on one state. So under a channel that has deadlock checking
off, the trap is quieter still, and the state count is the whole diagnosis.

## Acceptable variants

- `Book` written out inline, both primed equations in one action, no halves. Passes identically.
- `TakingsMatchSeats` as `takings = Fare * (Seats - free)`. Same thing.
- `takings \in 0..(Seats * Fare)` in `TypeOK` instead of `Nat`. Tighter, also fine.
- `Refund` guarded on `free < Seats` alone. The fare guard is implied by the invariant.

The inline form ignores the house's request for two rules, and TLC can't tell.
A reader who writes it has sidestepped the trap rather than learned it, which is
fine for the check and not for the drill.

## Wrong neighbours

| neighbour | what kills it |
|---|---|
| `UNCHANGED` inside each half | 1 state. Deadlock with the check on, a clean exit with it off. |
| a half placed in `Next` by itself | rc 75, "not completely specified", naming the variable |
| `TakeSeat` without `free > 0` | `TypeOK` red at `free = -1`, rc 12 (not measured) |
| `[][Next]_free`, subscript missing `takings` | passes here. Wrong at 96.2% of published sites, and it changes what a stuttering step means (`.claude/rules/tla-practice.md`, section 2). Not measured. |

## Why not in prompt

The prompt says the house wants two rules written separately. That's the whole
nudge, and it's a design requirement rather than code. Without it most readers
write `Book` inline and never meet the trap. With it, my guess is about half
write the halves as complete actions, which is what the item is for.

The honest caveat: a reader who has been bitten by this before will read "two
rules, one step" and know to leave the halves partial. That reader doesn't need
this item. The expected state count is in the prompt on purpose. It's the
foreclosing row, and under a channel with deadlock checking off it's the only
row. Without it, "Deadlock reached" on one state reads like a modelling quirk
rather than a wrong spec.
