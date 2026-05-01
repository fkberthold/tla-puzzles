# A04: Apalache — `:=` for Explicit Assignment ⭐

## Lesson: Apalache Wants Every Variable Assigned, Every Step

In TLA+, an action is just a logical formula relating unprimed and primed variables. TLC reads `x' = x + 1` as either an *assignment* (we are giving `x'` a new value) or a *constraint* (we're claiming `x'` happens to equal `x + 1`). TLC doesn't really distinguish these — it figures out the new state by unification.

Apalache *does* distinguish, because of how the SMT encoding works. Apalache requires that:

1. **Every variable is assigned exactly once per action**, and
2. **The assignment is unambiguous** — Apalache must be able to tell which `=` is the one defining `x'`.

For (1), if you forget to mention a variable, Apalache complains. For (2), Apalache uses a heuristic: the first `x' = ...` it sees in the action becomes the assignment. That heuristic occasionally guesses wrong on complex specs.

The fix is `:=`, the explicit-assignment operator from the `Apalache.tla` standard library:

```tla
EXTENDS Apalache

\* unambiguous: ":=" says THIS is the assignment
SomeAction == foo' := foo + 1
```

`foo' := bar` means *exactly the same thing as* `foo' = bar` to TLC (the `Apalache.tla` module defines `:=` as `=`). But Apalache's static analyzer treats `:=` as a syntactic marker for "yes, this line assigns the primed variable." It removes the guesswork.

You also use `:=` to make the **assigned-once** rule visible. If an action talks about `foo'` in two places (one assignment, one constraint), `:=` flags which is which.

**Worked example — a stopwatch.**

A stopwatch tracks elapsed seconds and a running flag. We want to write the spec so Apalache can tell which `=` lines are assignments without guessing.

```tla
---- MODULE Stopwatch ----
EXTENDS Integers, Apalache

\* @type: Int;
VARIABLE elapsed

\* @type: Bool;
VARIABLE running

vars == << elapsed, running >>

Init ==
  /\ elapsed := 0
  /\ running := FALSE

Start ==
  /\ ~running
  /\ running' := TRUE
  /\ elapsed' := elapsed

Tick ==
  /\ running
  /\ elapsed' := elapsed + 1
  /\ running' := running

Stop ==
  /\ running
  /\ running' := FALSE
  /\ elapsed' := elapsed

Next == Start \/ Tick \/ Stop

Spec == Init /\ [][Next]_vars
====
```

Three things to notice:

1. **`EXTENDS Apalache`** — required to bring `:=` into scope.
2. **Both variables in every action.** Even `Start`, which only changes `running`, has `elapsed' := elapsed`. Apalache wants the assignment in writing, not via `UNCHANGED`. (`UNCHANGED` works too, but `:=` is the more explicit habit when teaching.)
3. **Init uses `:=` too.** Init is a special action defining the *first* state, and Apalache treats it the same: every variable must be assigned.

**The key idea.** Read `:=` as "this variable, here, gets this value." It's `=` to TLC and a directive to Apalache. Use it for every primed-variable line, and for every conjunct in `Init`. Your specs become more readable AND Apalache's errors become more precise.

## Setup

A door has three states: `"closed"`, `"open"`, and `"locked"`. The door also has a counter `passes` for how many people have walked through. Three actions:

- `Open`: from `"closed"` to `"open"`. Increments `passes` because someone walks through.
- `Close`: from `"open"` to `"closed"`. Leaves `passes` alone.
- `Lock`: from `"closed"` to `"locked"`. Leaves `passes` alone.

The puzzle: **rewrite this with `:=` everywhere — both variables in every action, and in `Init`.**

## Task

Write `Door.tla`:

- `EXTENDS Integers, Apalache`
- Two variables, type-annotated:
  - `\* @type: Str;` `VARIABLE state`
  - `\* @type: Int;` `VARIABLE passes`
- `Init`: `state := "closed"` and `passes := 0`. Both with `:=`.
- Three actions `Open`, `Close`, `Lock`. **In each action, use `:=` for both `state'` and `passes'`** — even when the value is unchanged. (So `Close` will have `state' := "closed"` and `passes' := passes`.)
- `Spec == Init /\ [][Next]_vars`
- `TypeOK == state \in {"closed", "open", "locked"} /\ passes \in 0..5`

Limit `passes` so the state space stays small: `Open` should only fire when `passes < 3`.

## Check

```bash
cd solution
tlc Door
```

If you have Apalache:

```bash
apalache-mc check --inv=TypeOK --length=10 Door.tla
```

## Expected Result

- TLC: 11 distinct states, no error. The `:=` operator is just `=` to TLC, so the spec checks normally.

> **Note about `EXTENDS Apalache`.** The full `Apalache.tla` ships with a real Apalache install. If you don't have Apalache installed yet, the `solution/` directory includes a tiny TLC-only shim of the same module (just enough to define `:=` as `=` and let TLC parse the spec). Once you install Apalache for real, the shim is unused — Apalache resolves `EXTENDS Apalache` to its own library copy, which has the proper `:=` semantics for the symbolic checker.
- Apalache: invariant holds, no errors about unassigned variables.

**Mistake to try.** Drop the `passes' := passes` line from `Close`. Run TLC: it errors with "the next state is not completely specified" — TLC sees that `passes` has no defined behavior in `Close`. Run Apalache (if you have it): `assignment error: variable passes is not assigned a value`. Both tools require the assignment; `:=` makes it harder to forget.

## What you learned

- `:=` is defined in the `Apalache.tla` library (you must `EXTENDS Apalache`).
- It is `=` to TLC; to Apalache, it's a syntactic marker that "this line is THE assignment for this primed variable."
- Apalache requires every variable to be assigned in every action and in `Init`. Use `:=` for *all* primed-variable conjuncts, even unchanged ones, to make the contract visible.
- This is style discipline that pays off as specs grow: ambiguity at scale is the enemy.
