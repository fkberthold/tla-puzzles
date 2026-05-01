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

> **Note about `EXTENDS Apalache`.** The official `Apalache.tla` is shipped in the `solution/` directory (extracted from the apalache jar). Both TLC and Apalache resolve `EXTENDS Apalache` to the same file. TLC uses the erasure-style operator bodies (`__x := __e == __x = __e`); Apalache replaces them with native symbolic semantics.
- Apalache: invariant holds, no errors about unassigned variables.

**Mistake to try.** Drop the `passes' := passes` line from `Close`. Run TLC: it errors with "the next state is not completely specified" — TLC sees that `passes` has no defined behavior in `Close`. Run Apalache (if you have it): `assignment error: variable passes is not assigned a value`. Both tools require the assignment; `:=` makes it harder to forget.

## What you learned

- `:=` is defined in the `Apalache.tla` library (you must `EXTENDS Apalache`).
- It is `=` to TLC; to Apalache, it's a syntactic marker that "this line is THE assignment for this primed variable."
- Apalache requires every variable to be assigned in every action and in `Init`. Use `:=` for *all* primed-variable conjuncts, even unchanged ones, to make the contract visible.
- This is style discipline that pays off as specs grow: ambiguity at scale is the enemy.

## Hints

??? hint "💡 Hint 1 — Where does := come from?"
    The lesson mentions that `:=` is defined in a standard library. Look at the `EXTENDS` line in the lesson's worked example — which module do you need to include to use `:=`?

??? hint "💡 Hint 2 — Both variables, every action"
    The key rule: every variable must be assigned in every action. If an action doesn't change a variable, you don't use `UNCHANGED` — you write `var' := var` with `:=`. That's the "explicit assignment" in the puzzle name.

??? hint "💡 Hint 3 — Init also needs :="
    Init is a special action that defines the starting state. In Apalache, it's subject to the same rule: every variable gets `:=` with its initial value. The worked example shows `elapsed := 0` and `running := FALSE` in `Init`.
