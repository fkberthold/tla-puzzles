# T36: `await` for Synchronization ⭐

## Lesson: Blocking Until a Condition Holds

In T35 you saw two distinct processes interleave and the server outpace the chef. The fix is `await` — a one-line PlusCal statement that DISABLES its enclosing label until the given condition is true.

**Syntax:** `await cond;`

**Semantics:** if `cond` is false in the current state, the action containing this `await` is NOT enabled — TLC will not take it. As soon as another process changes state so `cond` becomes true, the action becomes enabled and (under fairness) eventually fires.

In the translation, `await cond` becomes a conjunct of the action: `pc[self] = "L" /\ cond /\ ...`. So the action's enabling condition includes `cond`. No `cond`, no step.

**Worked example — a traffic light and a car.**

A traffic light cycles `"red"` → `"green"`. A car arrives and waits at the intersection until the light is `"green"`, then drives through.

```
(*--algorithm Intersection {
  variables light = "red", through = FALSE;

  fair process (signal = "Light") {
    turnGreen:
      light := "green";
  }

  fair process (car = "Car") {
    arrive:
      await light = "green";
    drive:
      through := TRUE;
  }
}*)
```

The car's `arrive` label CANNOT take a step while `light = "red"`. TLC enumerates these states:

1. Initial: `light = "red", through = FALSE`, both at start labels
2. Signal turns light green: `light = "green"`
3. Car passes the await, advances to `drive`
4. Car drives: `through = TRUE`

Without the `await`, the car could `drive` while the light was still `"red"` — the bug. With it, the car physically cannot proceed until the light flips. That's synchronization.

**Two important notes:**

- `await` is NOT `if`. `if` checks the condition AT THIS MOMENT and either branches or not — control flow always advances. `await` BLOCKS the action entirely if the condition is false; nothing happens, the process sits there until the world changes.
- An `await` is part of an atomic step. If you write `await cond; x := 5;` in one label, BOTH the check and the assignment are part of the same step. The step doesn't fire at all unless `cond` holds.

## Setup

A relay race has two runners. Runner A starts at the line, sprints, and crosses the handoff zone — at which point we set `handoffReady := TRUE`. Runner B is waiting at the handoff. Runner B must NOT start until Runner A has reached the handoff. Once `handoffReady`, Runner B sprints to the finish.

We expect that `runnerBFinished` only becomes true AFTER `handoffReady` is true.

## Task

Write a PlusCal spec with:

- Variables `handoffReady = FALSE, runnerBFinished = FALSE`
- A process `runnerA = "RunnerA"` that does ONE step: `handoffReady := TRUE`
- A process `runnerB = "RunnerB"` that:
  1. **wait**: `await handoffReady;`
  2. **finish**: `runnerBFinished := TRUE;`

## Check

1. **TypeOK**: `handoffReady \in BOOLEAN /\ runnerBFinished \in BOOLEAN`
2. **NoEarlyFinish**: `runnerBFinished => handoffReady` — if Runner B has finished, the handoff must have happened.

## Expected Result

- All invariants PASS — `await` enforces the ordering.
- Around 5 distinct states.
- A liveness property (optional bonus): `<>(runnerBFinished = TRUE)` — eventually B finishes. Should hold under weak fairness.

## Hint

Compare what happens if you replace `await handoffReady;` with `if (handoffReady) { runnerBFinished := TRUE; };`. Without `await`, Runner B's `wait` step can FIRE before A has acted — the `if` evaluates to false and B falls through without finishing. With `await`, B's step doesn't fire at all until the condition holds. The liveness property catches the difference: under `if`, eventually finishing requires that B's step happens AFTER A's, which fairness alone doesn't enforce.
