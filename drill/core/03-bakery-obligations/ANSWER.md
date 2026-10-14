# Bakery: answer

## The answer

```tla
---- MODULE Bakery ----
EXTENDS Naturals

CONSTANTS Batch, Shelf, Price, Day

VARIABLES oven, tray, loaves, sold, till

vars == <<oven, tray, loaves, sold, till>>

TypeOK ==
  /\ oven \in {"cold", "hot"}
  /\ tray \in {"empty", "baking", "done"}
  /\ loaves \in Nat
  /\ sold \in 0..Day
  /\ till \in Nat

Init ==
  /\ oven = "cold"
  /\ tray = "empty"
  /\ loaves = 0
  /\ sold = 0
  /\ till = 0

Light ==
  /\ oven = "cold"
  /\ oven' = "hot"
  /\ UNCHANGED <<tray, loaves, sold, till>>

Douse ==
  /\ oven = "hot"
  /\ tray = "empty"
  /\ oven' = "cold"
  /\ UNCHANGED <<tray, loaves, sold, till>>

Load ==
  /\ oven = "hot"
  /\ tray = "empty"
  /\ tray' = "baking"
  /\ UNCHANGED <<oven, loaves, sold, till>>

Bake ==
  /\ tray = "baking"
  /\ tray' = "done"
  /\ UNCHANGED <<oven, loaves, sold, till>>

Unload ==
  /\ tray = "done"
  /\ loaves + Batch <= Shelf
  /\ tray' = "empty"
  /\ loaves' = loaves + Batch
  /\ UNCHANGED <<oven, sold, till>>

Sell ==
  /\ loaves > 0
  /\ sold < Day
  /\ loaves' = loaves - 1
  /\ sold' = sold + 1
  /\ till' = till + Price
  /\ UNCHANGED <<oven, tray>>

Bank ==
  /\ sold = Day
  /\ sold' = 0
  /\ till' = 0
  /\ UNCHANGED <<oven, tray, loaves>>

Next == Light \/ Douse \/ Load \/ Bake \/ Unload \/ Sell \/ Bank

Spec == Init /\ [][Next]_vars

NothingInAColdOven == tray /= "empty" => oven = "hot"

ShelfNeverOverfull == loaves <= Shelf

TillMatchesSales == till = sold * Price
====
```

```
SPECIFICATION Spec
CONSTANTS
  Batch = 2
  Shelf = 3
  Price = 5
  Day = 4
INVARIANTS
  TypeOK
  NothingInAColdOven
  ShelfNeverOverfull
  TillMatchesSales
```

Three worries, three names, four lines under `INVARIANTS` counting `TypeOK`.
`loaves` is typed over `Nat` rather than `0..Shelf`, so the shelf's capacity
lives in `ShelfNeverOverfull` and nowhere else.

## What the second run should say

`Invariant NothingInAColdOven is violated.` and a two-state trace: the initial
state, then a batch loaded into a cold oven. The report names the worry.

If the three worries went in as one definition, `Safe == NothingInAColdOven /\
ShelfNeverOverfull /\ TillMatchesSales`, with one `INVARIANT` line, the report
says `Invariant Safe is violated.` over the same two-state trace. The trace is
identical and the label isn't. That is the whole difference, and the cost of
the bundle appears only now, when something broke. Lamport says why in
*Specifying Systems* §14.5.3: give the conjuncts separate names and list them
separately, and TLC will tell you which one is false. Over 666 published
modules, of 179 resolvable conjunctions only 69 are pairwise disjoint in the
variables they touch, and 65 of those 69 are type invariants by name
(`.claude/rules/tla-practice.md`, section 1). Bundling is for `TypeOK` and
almost nothing else.

## Measurements

From `verify/`, each run was `tlc -workers 1 -noGenerateSpecTE -metadir
states/<name> <Module>.tla -config <config>`. Each module has a config of its
own name carrying the three names. `Bundled.cfg` names `TypeOK` and `Safe`,
and `TwoNames.cfg` drops the oven name. The five mutant modules define `Safe`
at the bottom so the bundled config can run against them.

| module | what changed | under `Bundled.cfg` | under `TwoNames.cfg` | under its own config |
|---|---|---|---|---|
| `Bakery` | reference | passes | passes, 40 states | rc 0, 78 generated, 40 distinct |
| `DouseWithTray` | `Douse` without the empty-tray check | `Safe` violated | green, 60 states | rc 12, `NothingInAColdOven`, 4 states |
| `UnloadNoRoom` | `Unload` without the room check | `Safe` violated | `ShelfNeverOverfull` violated | rc 12, `ShelfNeverOverfull`, 14 states |
| `SellOverpriced` | `Sell` rings up `Price + 1` | `Safe` violated | `TillMatchesSales` violated | rc 12, `TillMatchesSales`, 8 states |
| `LoadColdOven` | `Load` without the hot-oven check | `Safe` violated | green, 60 states | rc 12, `NothingInAColdOven`, 3 states |
| `SellUnrung` | `Sell` doesn't ring up at all | `Safe` violated | `TillMatchesSales` violated | rc 12, `TillMatchesSales`, 8 states |

Five of five caught and named under three names. Five of five caught under the
bundle, all labeled `Safe`. Three of five under two names, with the two oven
mutants passing green at 60 states. The oven name was worth two mutants.

Two more things came out of the runs. The first draft had no `Bank` and
stopped at a deadlock with 40 states: the day ends with a full shelf and a done
tray, and nothing is enabled. `Bank` or `CHECK_DEADLOCK FALSE` both fix it. I
took `Bank` because the config keyword is another family's lesson. And with
`loaves \in Nat` and the shelf name dropped from the config, the no-room mutant
never terminates. I killed it after 120 seconds. Dropping a name over an
unbounded variable doesn't just lose the label, it loses the run.

## Acceptable variants

- `loaves \in 0..Shelf` inside `TypeOK` and no `ShelfNeverOverfull`. Two names plus `TypeOK`.
- `CHECK_DEADLOCK FALSE` in the config in place of `Bank`. 79 of 337 published configs do it.
- `Load` and `Bake` merged into one step. Fewer states, same three worries.
- Worry 1 as `oven = "cold" => tray = "empty"`. The contrapositive.

The first variant is the one bundle the corpus does make, since the shelf
bound is a type bound on `loaves`. The no-room mutant then reports as `TypeOK`,
which is a label, just a worse one. I'd still keep the shelf as its own name,
because the owner asked about the shelf and not about types.

## Wrong neighbors

| neighbor | what kills it |
|---|---|
| `Safe == A /\ B /\ C`, one `INVARIANT` line | nothing in TLC. Every mutant says `Safe`. |
| the three worries folded into `TypeOK` | same, and the type failures lose their label too |
| worries 2 and 3 named, worry 1 dropped | the two oven mutants go green at 60 states |
| no `Bank` and deadlock checking on | deadlock at 40 states, rc 11 |
| `till` and `sold` left unbounded with no `Day` | TLC never finishes (not measured, by analogy with the no-room mutant) |

## Why not in prompt

The numbered list is the nudge. Three numbered worries suggest three names,
and a reader who already names things will do it without noticing. The honest
caveat is that the lesson doesn't land in the writing. It lands in the "break
it" step, when the reader who bundled sees `Safe` and has to open the module to
find which of three rules broke. I'd keep that step in the prompt for exactly
that reason.

The count of 40 is in the prompt because the first reference deadlocked at 40.
A reader whose spec stops at a deadlock with 40 states has the right spec and
no `Bank`, and the count tells him so.
