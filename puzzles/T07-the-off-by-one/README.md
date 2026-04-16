# T07: The Off-By-One ⭐⭐

## Lesson: TLC as a Debugger

Most of TLA+ is about verifying that your spec matches your intentions. But TLC is just as useful in the REVERSE direction — write a spec with a deliberate mistake, write an invariant that expresses what SHOULD be true, and let TLC find the gap. The gap is the bug. The counterexample trace shows EXACTLY where the code and the intent diverge.

**Worked example — a recipe scaler with a broken loop condition.**

A cook wants to scale a recipe: one cup of flour per serving. The code adds cups until the count reaches the serving target, then marks the work as done. But a bug in the loop condition makes it stop one cup short.

```
(*--algorithm RecipeScaler {
  variables servings = 4, cups = 0, done = FALSE;

  fair process (cook = "Cook") {
    scale:
      while (cups < servings - 1) {   \* BUG: should be cups < servings
        cups := cups + 1;
      };
    finish:
      done := TRUE;
  }
}*)
```

Sample invariants:

- `TypeOK == servings \in 1..10 /\ cups \in 0..10 /\ done \in BOOLEAN`
- `DoneImpliesFull == done = TRUE => cups = servings` — TLC WILL violate this

TLC reports the violation with a short trace:

1. Initial state: `servings = 4, cups = 0, done = FALSE`
2. Three iterations raise `cups` to 3
3. Loop condition `cups < servings - 1` = `3 < 3` fails — exit the loop
4. `done := TRUE` fires with `cups = 3` and `servings = 4`
5. Invariant `DoneImpliesFull` checks: `TRUE => 3 = 4`, which is FALSE. Violation.

The trace SHOWS the bug — not just that something's wrong, but WHERE. The assignment of `done` happened while `cups` was still less than `servings`. The condition `< servings - 1` instead of `< servings` is the off-by-one.

This is the formal-methods workflow in miniature:

1. State your intention as an invariant (`done => cups = servings`)
2. Write the code you think does the thing
3. Let the model checker point at the disagreement

If you only wrote correct code, you'd never practice this workflow. Writing deliberately-broken code and catching the bug with TLC is how you build the muscle.

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
