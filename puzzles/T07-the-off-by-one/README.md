# T07: The Off-By-One ⭐⭐

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

## Concept

**Using TLC as a DEBUGGER.** You don't just verify correct specs — you deliberately write broken ones and let TLC find the break. This is how formal methods work in practice: write what you THINK the system does, write what you WANT to be true, and let the model checker find the gap. The gap is the bug.
