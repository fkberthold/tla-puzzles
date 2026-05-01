# R09: Review — Either/Or with Liveness ⭐

## Lesson: Why `fair process` Matters for `<>`

T03 used `either/or` plus a `<>` property and it just worked. This review names the reason: the keyword `fair` before `process` is what makes the liveness check pass. Behind the scenes pcal turns `fair process P { ... }` into the formula `WF_vars(P)` — "weak fairness" — which TLC adds to the spec.

Without that fairness clause, TLC is allowed to pick a behavior in which the process never takes a step. Such a behavior never reaches the eventual state, so any `<>` property on it fails.

**No new TLA+ syntax** — `either/or`, `fair process`, and `<>` were all introduced in T03. The new awareness is the cause-and-effect: `fair` is what TURNS ON the liveness machinery. Drop it, and `<>` properties become checkable but unprovable.

**Worked example — a runner choosing to walk or jog.**

Each step the runner chooses either to walk or to jog, then halts. The waiter at the park wants `<>(arrived = TRUE)`.

```
(*--algorithm Runner {
  variables arrived = FALSE;

  define {
    EventuallyArrives == <>(arrived = TRUE)
  }

  fair process (athlete = "Athlete") {
    move:
      either {
        \* walk to the park
        arrived := TRUE;
      } or {
        \* jog to the park
        arrived := TRUE;
      };
  }
}*)
```

With `fair process`: the property `EventuallyArrives` passes. TLC explores both branches; in either, `arrived` becomes TRUE.

If you change `fair process (athlete = "Athlete")` to `process (athlete = "Athlete")` (drop `fair`), TLC reports a temporal-property violation. The counterexample is a behavior that stutters at the initial state forever — no `move` step is ever taken, so `arrived` stays FALSE, so `<>` fails.

The takeaway: `fair process` is not just decoration. It is what licenses TLC to assume the process will eventually take an enabled step, which is exactly what `<>` properties need.

## Setup

A bathroom faucet has been left slightly turned. It may drip slowly or run for a moment. Either way, eventually a drop hits the basin. Track this with a variable `dropFell`.

The plumber's claim: "no matter how the water actually exits, eventually a drop hits the basin." That's a `<>` property, and it relies on weak fairness.

## Task

Write a PlusCal spec with:

- A variable `dropFell` initially `FALSE`
- A `define` block with `EventuallyDrips == <>(dropFell = TRUE)`
- A `fair process` named `faucet` that uses `either/or`:
  - `either` branch: drip slowly — set `dropFell := TRUE`
  - `or` branch: run for a moment — set `dropFell := TRUE`

In `Faucet.cfg`: `INVARIANT TypeOK` (define `TypeOK == dropFell \in BOOLEAN`) and `PROPERTY EventuallyDrips`.

## Check

1. **TypeOK** holds.
2. **EventuallyDrips** passes with `fair process`.

## Expected Result

- TLC should report `No error has been found`. The canonical solution reports 2 distinct states: the initial `dropFell = FALSE` and the post-step `dropFell = TRUE`. The two `either` branches collapse to the same state because both assign the same value; your spec's label choices may affect the state count — that's fine, the behavior is what matters.
- `EventuallyDrips` passes with `fair process`.
- **Experiment**: change `fair process` to `process` (no fairness) and re-run with `tlc -pcal Faucet.tla && tlc Faucet`. TLC reports a temporal violation: a 1-state stuttering trace where the faucet never takes any step. The violation shape is what matters — fairness is what makes liveness work.

## Hints

??? hint "💡 Hint 1 — The role of `fair` in the cfg"
    The cfg asks for `PROPERTY EventuallyDrips`. Without `fair process`, what does TLC think is allowed to happen to the faucet? Why would that break `<>`?

??? hint "💡 Hint 2 — Two branches, one outcome"
    Both `either` branches do the same thing: `dropFell := TRUE`. Why would TLC collapse these into a single state even though there are two code paths?

??? hint "💡 Hint 3 — The minimal process"
    For this puzzle, your process needs exactly one labeled block. Inside that block, use `either` with two branches. Both branches set the same variable to the same value.
