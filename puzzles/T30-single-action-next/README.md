# T30: Writing Next as a Single Action ⭐⭐

## Lesson: Synthesize a Spec from a Description

You have read pure-TLA+ specs (T26), classified levels (T27), written `Init` predicates (T28), and seen what `UNCHANGED` does (T29). T30 is where you put it together: given a prose description of a system, **write the whole spec yourself**. No template to fill in.

The discipline:

1. List the variables. One line of TLA+ per piece of state.
2. Write `TypeOK` — what's the type of each variable?
3. Write `Init` — what is true when the system starts?
4. Write `Next` as one action that captures every transition. Every variable must appear primed (or in `UNCHANGED`).
5. Write `Spec == Init /\ [][Next]_<<vars>>`.

For T30 the action is **single** — `Next == OneAction`. T31 generalizes to multiple actions.

A useful heuristic for "what should the action say":

- **Guards** go first: under what conditions can the system take any step at all?
- **Updates** go next: what is the new value of each variable?
- **Held-steady** go last: which variables don't change, and `UNCHANGED` them.

**Worked example — a packet sender with retry counter.**

System: a packet sender owns a `packet` (one of `1..5`, picks one at start) and a `retries` counter starting at 0. On each step, if `retries < 3`, the sender retransmits — `retries` increments by 1, `packet` stays the same. There is no "send succeeded" or "give up" action; this is a one-action spec.

Building the spec:

```
---- MODULE Sender ----
EXTENDS Integers

VARIABLES packet, retries

TypeOK == packet \in 1..5 /\ retries \in 0..3

Init ==
  /\ packet \in 1..5
  /\ retries = 0

Retry ==
  /\ retries < 3
  /\ retries' = retries + 1
  /\ UNCHANGED packet

Next == Retry

Spec == Init /\ [][Next]_<<packet, retries>>
====
```

Walk through how I built it:

- **Variables**: the description names two pieces of state — `packet`, `retries`.
- **`TypeOK`**: `packet` ranges over `1..5`, `retries` over `0..3` (the upper bound is the cap from "retries < 3" — after 3 retries the variable is 3, no further increment).
- **`Init`**: `packet` is "any value in `1..5`" → `\in`. `retries` is "starts at 0" → `=`.
- **`Retry`**: guard is the `retries < 3` from the description. Update is `retries' = retries + 1`. `packet` does not change → `UNCHANGED packet`.
- **`Next == Retry`** because there is exactly one action.
- **`Spec`** is the standard shape. Listing both variables in `<<packet, retries>>` for the stuttering term.

Sanity check: TLC on this spec finds **5 × 4 = 20 reachable states**. After 3 retries the system stutters forever (no enabled action). `TypeOK` holds throughout.

## Setup

A **simple latch** has two variables:

- `value` — an integer in `0..9`. At start, `value` is any of `0..9` (nondeterministic).
- `latched` — a boolean. Starts `FALSE`.

There is exactly one action: **`Latch`**. It can fire only when `latched = FALSE`. When it fires, it sets `latched` to `TRUE` and *also* sets `value` to `0`. After that, no action is enabled.

## Task

Author `solution/Latch.tla` from scratch. The spec must contain:

- Module declaration and `EXTENDS` (figure out which standard modules you need)
- `VARIABLES value, latched`
- `TypeOK` (state-level)
- `Init` (10 initial states because `value` is nondeterministic)
- A single action `Latch` with the right guard, the right updates, and no missing primed mentions
- `Next == Latch`
- `Spec == Init /\ [][Next]_<<value, latched>>`

Author `solution/Latch.cfg` with `SPECIFICATION Spec` and `INVARIANT TypeOK`. Add a third line: `CHECK_DEADLOCK FALSE`. (After `Latch` fires, no action is enabled — the spec stutters forever, which is fine semantically. But TLC's default deadlock check would still complain. `CHECK_DEADLOCK FALSE` tells TLC to allow terminal states. T32 explores the stuttering question directly.)

## Check

```bash
cd solution
tlc Latch
```

## Expected Result

- TLC reports **10 distinct initial states** (one per `value` in `0..9`, all with `latched = FALSE`).
- TLC reports **11 distinct reachable states**: the 10 initial states, plus the single post-latch state `<<0, TRUE>>` (every initial state can take one `Latch` step to the same `<<0, TRUE>>`, which then has no enabled successor).
- `TypeOK` passes.
- After `Latch` fires once from any initial state, `Latch` is no longer enabled. The system stutters forever — no error, because `[][Next]_vars` allows stuttering.

If you wrote `Latch` without the `latched = FALSE` guard, TLC would still find 11 states — but `latched` could be set to `TRUE` repeatedly, costing nothing in state count (the post-latch state is the same), and the spec would be sloppy. If you wrote `Latch` without `value' = 0` and forgot to `UNCHANGED value`, you'd get the same "Successor state is not completely specified" error you saw in T29.

## Hints

??? hint "💡 Hint 1 — Build the spec in order: variables, type, init, action"
    Start with `VARIABLES`. Then write `TypeOK` (what values can each variable take?). Then write `Init` (what are the starting values?). Then write the action(s). Finally, wrap it in `Spec`. This order forces you to ask the right questions at each step.

??? hint "💡 Hint 2 — Guards before updates"
    In the action, write the guard first (the condition that must be true to take a step). The guard is a conjunct that doesn't mention primes. Then write the updates (primed assignments). For `Latch`, the guard is `latched = FALSE`. The updates are `latched' = TRUE` and `value' = 0`.

??? hint "💡 Hint 3 — Every variable in primed form"
    After writing the updates, check: does the action mention both variables in primed form? If one variable doesn't change, use `UNCHANGED`. The `Latch` action changes both `latched` and `value`, so both appear primed. After `Latch` fires, no action is enabled, so `CHECK_DEADLOCK FALSE` in the `.cfg` tells TLC not to complain about terminal states.
