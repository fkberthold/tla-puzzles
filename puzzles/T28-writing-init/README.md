# T28: Writing Init Predicates ⭐

## Lesson: Init Is a Predicate, Not an Assignment

`Init` is a **predicate on the unprimed state** — a state-level formula. It is true of exactly the states that are valid as starting points. The crucial mental flip from PlusCal:

- PlusCal: `variables x = 0, y = "off"` looks like an assignment. It says: "set `x` to 0."
- Pure TLA+: `Init == /\ x = 0 /\ y = "off"` looks the same but is a *predicate*. It says: "the initial states are those where `x = 0` and `y = "off"`."

For a single fixed value, the two read identically. The difference shows up when you want **multiple initial states**.

Two operators do all the work in `Init`:

- `=` constrains a variable to one specific value: `x = 0`.
- `\in` constrains a variable to *any* value from a set: `x \in 0..5`.

Using `\in` makes `Init` admit multiple initial states. TLC then runs the spec **starting from every one of them** in parallel — every initial state is the root of its own state-space exploration.

**Worked example — a chess board with two starting positions.**

A small spec models a king on a chess board. The board is `1..3` × `1..3`. The puzzle setup picks one of two openings: corner `<<1,1>>` or center `<<2,2>>`. Each step the king moves to an adjacent square (any of the 8 directions, bounded by the board).

```
---- MODULE King ----
EXTENDS Integers

VARIABLES x, y

TypeOK == x \in 1..3 /\ y \in 1..3

Init ==
  /\ x \in {1, 2}
  /\ y \in {1, 2}
  /\ ~(x = 1 /\ y = 2)
  /\ ~(x = 2 /\ y = 1)

\* (the conjunction above admits exactly 2 initial states: <<1,1>> and <<2,2>>)

Move ==
  /\ \E dx \in {-1, 0, 1}, dy \in {-1, 0, 1} :
       /\ ~(dx = 0 /\ dy = 0)
       /\ x + dx \in 1..3
       /\ y + dy \in 1..3
       /\ x' = x + dx
       /\ y' = y + dy

Next == Move

Spec == Init /\ [][Next]_<<x, y>>
====
```

Things to notice in `Init`:

- `x \in {1, 2}` allows two values for `x`. By itself it would give 2 initial states.
- `x \in {1, 2} /\ y \in {1, 2}` would give 4 (Cartesian product). The added conjuncts cut it down to 2.
- All conjuncts must be true simultaneously — `Init` is a *predicate*, not a sequence of statements. Order does not matter.

If you instead wrote `Init == x \in 1..3 /\ y \in 1..3` (no further constraints), TLC would start from all 9 squares and explore the king's reachable states from each. That is sometimes what you want — exhaustive coverage of every possible starting condition. Other times you want exactly one start. Both are written the same way; the constraints just differ.

A common bug: using `=` where you meant `\in`. `x = {1,2}` says "x is the set `{1,2}`," which is a singleton initial state where `x` has the value `{1,2}` — almost certainly not what you intended.

## Setup

A **dice game** uses two six-sided dice. The two dice can start in any combination of values from `1..6`. Each step rerolls one die (chosen nondeterministically — left or right).

You will write the `Init` predicate that admits **all 36 starting positions**, plus a `Reroll` action.

## Task

Author `solution/Dice.tla` as pure TLA+:

- `EXTENDS Integers`
- `VARIABLES left, right`
- `Faces == 1..6`
- `TypeOK == left \in Faces /\ right \in Faces`
- `Init` admitting **every combination** of `(left, right)` from `Faces × Faces` — use `\in`.
- A `RerollLeft` action: `left' \in Faces /\ right' = right`. (Yes, `left' \in Faces` — primed variables can be constrained nondeterministically too.)
- A `RerollRight` action: `right' \in Faces /\ left' = left`.
- `Next == RerollLeft \/ RerollRight`
- `Spec == Init /\ [][Next]_<<left, right>>`

Author `solution/Dice.cfg` with `SPECIFICATION Spec` and `INVARIANT TypeOK`.

## Check

Run from `solution/`:

```bash
tlc Dice
```

## Expected Result

- TLC reports **36 distinct states** — every (left, right) pair in `Faces × Faces`.
- TLC reports something like "36 distinct initial states" (because `Init` admits all 36 from the start; `Next` does not reach anything new).
- `TypeOK` passes.

Now experiment: change `Init` to `left = 1 /\ right = 1`. Re-run. State count is still 36, but TLC reports **1 distinct initial state** — the same 36 reachable states, just discovered from one root via `Reroll` actions instead of being enumerated as initial. The reachable set is the same; the *initial set* differs.

If you wrote `left = Faces` instead of `left \in Faces`, TLC would either reject the spec or treat `left` as the value `1..6` (a set), which `TypeOK` would catch — `1..6` is not in `1..6`.

## Hints

??? hint "💡 Hint 1 — Init is a predicate, not an assignment"
    You learned in PlusCal: `variables x = 0` sets x to 0. In pure TLA+, `Init == x = 0` is a predicate that constrains initial states to those where x is 0. If you want multiple initial states, use `\in` instead of `=`. E.g., `Init == x \in 0..5` means "initially x can be any value from 0 to 5."

??? hint "💡 Hint 2 — Multiple initial states via Cartesian product"
    If you write `left \in Faces /\ right \in Faces`, TLC computes the Cartesian product: every combination. How many combinations are there? If `Faces = 1..6`, then left has 6 choices and right has 6 choices — that is 6 × 6 = 36 initial states. TLC will explore the state space starting from each.

??? hint "💡 Hint 3 — Nondeterministically assign primed variables"
    In `RerollLeft`, you assign `left' \in Faces` — notice the prime. This means "in the next state, left can be any value in Faces." This is how you model nondeterministic choice in actions. The pattern is the same as in `Init`: use `\in` to allow multiple values, `=` to fix one.
