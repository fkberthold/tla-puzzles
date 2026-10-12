# Vending machine: answer

## The answer

```tla
---- MODULE Vending ----
EXTENDS Naturals

CONSTANTS Price, MaxCredit, Cap

VARIABLES credit, stock, sold

vars == <<credit, stock, sold>>

TypeOK ==
  /\ credit \in 0..MaxCredit
  /\ stock \in 0..Cap
  /\ sold \in 0..Cap

Init ==
  /\ credit = 0
  /\ stock = Cap
  /\ sold = 0

Insert ==
  /\ credit < MaxCredit
  /\ credit' \in (credit + 1)..MaxCredit
  /\ UNCHANGED <<stock, sold>>

Vend ==
  /\ credit >= Price
  /\ stock > 0
  /\ credit' = credit - Price
  /\ stock' = stock - 1
  /\ sold' = sold + 1

Refund ==
  /\ credit > 0
  /\ credit' = 0
  /\ UNCHANGED <<stock, sold>>

Next == Insert \/ Vend \/ Refund

Spec == Init /\ [][Next]_vars

EveryCanAccountedFor == stock + sold = Cap
====
```

```
SPECIFICATION Spec
CONSTANTS
  Price = 2
  MaxCredit = 3
  Cap = 2
INVARIANTS
  TypeOK
  EveryCanAccountedFor
```

Each action says what happens to all three variables. `Insert` and `Refund`
move `credit` and hold the other two with the tuple form,
`UNCHANGED <<stock, sold>>`. `Vend` moves all three, so it has no `UNCHANGED`.

## What a forgotten variable does

The imperative instinct is that a variable you don't mention keeps its value.
In an action it doesn't. An action is a predicate on two states, and a variable
it doesn't mention is a variable it says nothing about. What TLC does with the
silence depends on its shape, and the shapes below behave differently.

From `verify/`, each run was
`tlc -workers 1 -noGenerateSpecTE -metadir states/<name> <Module>.tla -config <Module>.cfg`.
Every config names both invariants except the one marked.

| module | what | rc | generated | distinct | TLC says |
|---|---|---|---|---|---|
| `Vending` | reference | rc 0 | 32 | 12 | no error |
| `ForgotUnchanged` | `Insert` says nothing about `stock`, `sold` | rc 75 | 2 | 1 | `Successor state is not completely specified by action Insert of the next-state relation. The following variables are not defined: sold, stock.` |
| `TypedInPlace` | `Insert` pins `stock'`, `sold'` to their types | rc 12 | 2 | 2 | `Invariant EveryCanAccountedFor is violated.` |
| `TypedNextSilent` | `Next` opens with the types of every primed variable, `Insert` forgets both, config checks `TypeOK` alone | rc 0 | 522 | 36 | no error |
| `TypedNextCaught` | the same module, config also checks the conservation rule | rc 12 | 2 | 2 | `Invariant EveryCanAccountedFor is violated.` |

Row 2 is the loud case. Forget a variable outright and TLC refuses on the first
step, naming the action and the variables. It's the common outcome and the easy
one.

Row 4 is the silent case the item exists for. Put the types of the primed
variables at the top of `Next`, the way a declaration would go, and a variable
an action forgets is free to take any value in its type on every step. `TypeOK`
can never go red, because `Next` enforces it. Nothing is reported. The state
count went from 12 to 36, which is every combination the types allow, and that
number is the only tell.

Row 3 is the row that teaches the most about localisation. Run that module
with `TypeOK` alone in the config and it still goes red, on `TypeOK` itself, 37
states in. The variable that breaks is `sold`, which `Insert` never mentions.
`Vend` pushed it past `Cap` after the free restocks. The report names a
variable two actions away from the bug.

Row 5 is the fix for the silent case that isn't `UNCHANGED`. Name a rule that
relates the forgotten variable to the rest, and `stock + sold = Cap` goes red on
the second state.

One more measurement. Row 4 spelled as `Next == TypeOK' /\ (...)` doesn't run.
TLC can't enumerate successors through a primed definition, and stops at rc 75
with "In evaluation, the identifier credit is either undefined or not an
operator". The types have to be inline for the silent version to exist at all.

## Acceptable variants

- `UNCHANGED stock /\ UNCHANGED sold` instead of the tuple. Same meaning, twice the lines.
- `stock' = stock /\ sold' = sold`. That is what `UNCHANGED` abbreviates.
- `credit' = credit + 1` in `Insert`, one coin per step. The prompt says any number in one go.
- `EveryCanAccountedFor` as `sold = Cap - stock`. Same thing.

The one-coin form should reach the same 12 states here, since every credit is
reachable in single steps, but I didn't measure it.

## Wrong neighbours

| neighbour | what kills it |
|---|---|
| no `UNCHANGED` at all in `Insert` | rc 75 on the first step, naming `sold, stock` |
| types in place of `UNCHANGED` | rc 12, on a variable the action never mentions |
| types at the top of `Next` | nothing. 36 states instead of 12. |
| `UNCHANGED <<stock, sold>>` added to `Vend` as well | contradicts `stock' = stock - 1`, so `Vend` never fires. I'd expect rc 0 at 4 states (not measured). That's the box office item's trap. |

## Why not in prompt

The prompt gives the expected count. That's what makes the silent shape visible
at all. Everything else is the domain.

The honest caveat: the silent shape needs the reader to put types at the top of
`Next`, and most readers will instead forget `UNCHANGED` outright and get the
loud rc 75. For them the item teaches the loud case in the doing and the silent
case in the reading. I think that's the right split. The loud case is what
they'll hit on Tuesday and the silent case is what they'll hit in month three.
