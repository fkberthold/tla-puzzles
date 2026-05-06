# T07: The Off-By-One ⭐⭐

## Lesson: TLC as a Debugger

Most of TLA+ is about verifying that your spec matches your intentions. But TLC is just as useful in the REVERSE direction — write a spec with a deliberate mistake, write an invariant that expresses what SHOULD be true, and let TLC find the gap. The gap is the bug. The counterexample trace shows EXACTLY where the code and the intent diverge.

**Worked example — claiming `done` while still pending.**

A worker has one task to finish (`pending = TRUE`) and a `done` flag that should only be `TRUE` when the task is finished. The deliberately-buggy spec sets `done := TRUE` without ever clearing `pending`. The invariant `DoneImpliesFinished == done = TRUE => pending = FALSE` names the intent. TLC catches the gap.

```
(*--algorithm Claim {
  variables pending = TRUE, done = FALSE;

  fair process (worker = "Worker") {
    step:
      done := TRUE;   \* BUG: claiming done while pending is still TRUE
  }
}*)
```

Sample invariants:

- `TypeOK == pending \in BOOLEAN /\ done \in BOOLEAN`
- `DoneImpliesFinished == done = TRUE => pending = FALSE` — TLC WILL violate this

TLC reports the violation in two states:

1. Initial state: `pending = TRUE, done = FALSE` — invariant holds (the antecedent is false)
2. After `step:` — `done = TRUE, pending = TRUE`. The implication `TRUE => FALSE` evaluates to `FALSE`. Violation, one step deep.

The trace SHOWS the bug — not just that something's wrong, but WHERE. The assignment of `done` happened while `pending` was still TRUE. The bug is the *missing* assignment to `pending`.

This is the formal-methods workflow in miniature:

1. State your intention as an invariant (`done => pending = FALSE`)
2. Write the code you think does the thing
3. Let the model checker point at the disagreement

If you only wrote correct code, you'd never practice this workflow. Writing deliberately-broken code and catching the bug with TLC is how you build the muscle. The puzzle below is the same trick at a slightly larger scale — a counter that claims it's reached zero before it actually has.

## Setup

A simple counter counts down from 3 to 0. When it reaches 0, it sets a flag `done` to TRUE. But the programmer made a mistake: the counter checks `count > 0` instead of `count >= 0`, or decrements before checking, or has some other subtle error.

Your job: write a spec with a DELIBERATE BUG, then write an invariant that CATCHES it.

## Task

Write a PlusCal spec with:

- A variable `count` starting at 3
- A variable `done` starting at FALSE
- A single process that loops, decrementing `count` by 1 each time
- When `count` reaches 0, set `done := TRUE`
- **Introduce a bug**: for example, use `count > 0` as the loop condition (which exits at 1 instead of 0) and set `done := TRUE` after the loop. This means `done` becomes TRUE while `count` is still 1.

## Check

1. **TypeOK**: `count` in `0..3`, `done` in `{TRUE, FALSE}`
2. **DoneImpliesZero**: `done = TRUE => count = 0` — done should ONLY be true when count is actually zero

## Expected Result

- TLC should find **DoneImpliesZero violated** — the trace shows the counter stopping at 1 and claiming it's done
- The trace should be SHORT (4-5 states) and clearly show the bug

## Hints

??? hint "💡 Hint 1 — Intentional bugs are a feature, not a bug"
    Write a deliberate mistake in your loop. Make the condition just SLIGHTLY wrong — off by one, or the wrong relational operator. Then write an invariant that SHOULD be true if the code were correct. TLC will show you exactly where they diverge.

??? hint "💡 Hint 2 — The invariant names your intent"
    `DoneImpliesZero == done = TRUE => count = 0` says: "if done is true, count must be zero." Your buggy code violates this because done becomes true BEFORE count reaches zero. The implication fails. That's the bug captured as a formula.

??? hint "💡 Hint 3 — Read the trace bottom-up"
    The violating state (where the invariant breaks) is the LAST state in the trace. Walk backwards: what was count at that step? At the previous step? The trace shows the countdown and where it stalled. That's the off-by-one, visible.
