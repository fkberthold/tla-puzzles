# T05: The Toll Booth ⭐

## Lesson: `assert` — Runtime Checks Inside the Algorithm

INVARIANTS check properties from OUTSIDE the algorithm — they apply to every reachable state, all the time. `assert` checks from INSIDE the algorithm, at a specific point in the code. If an assert fails, TLC reports it at that line and shows the trace that led there.

Use invariants for global properties ("this is true in every state"). Use asserts for local sanity checks ("at THIS point, this had better be true").

**Worked example — a doorman checking ID.**

A doorman checks one customer's age. The line `assert age >= 21` fires only at that line, only when execution reaches it. No loop, no invariant, no broader machinery — `assert` alone, used in the smallest possible spec.

```
(*--algorithm Doorman {
  variables age = 22;

  fair process (door = "Doorman") {
    check:
      assert age >= 21;
  }
}*)
```

With `age = 22` the assert holds and TLC reports `No error has been found`. Change `age = 18` and re-run: TLC reports the assert failure at the exact line `assert age >= 21`, with a one-state trace, and stops exploring that branch.

Asserts are checked EVERY time execution passes through them — unlike invariants (checked against every state), asserts are checked against execution flow. They catch "impossible" internal states that may become possible under unexpected inputs. The doorman demo isolates that mechanism: one variable, one process, one label, one assert. Everything else (loops, choices, multiple labels) is the *puzzle's* job to compose.

**When to reach for which:**
- "This value should always be in [0, 20]" → invariant
- "After I compute this, it should be divisible by 2" → assert (only at that point)
- "My two counters should always sum to the total" → invariant
- "Before I divide, the denominator can't be zero" → assert

## Setup

A toll booth takes coins. It accepts quarters (25 cents) and dimes (10 cents). The toll costs 50 cents. A driver inserts coins one at a time until they've paid at least 50 cents, then the gate opens.

## Task

Write a PlusCal spec with:

- A variable `paid` starting at 0
- A variable `gate` starting at `"closed"`
- A single process that loops:
  1. Uses `either/or` to insert a quarter (add 25) or a dime (add 10)
  2. After inserting, checks: if `paid >= 50`, set `gate := "open"` and stop
- Add `assert paid <= 100` inside the loop — a runtime sanity check that the driver never overpays by too much

## Check

1. **TypeOK**: `paid` is a natural number, `gate` is in `{"open", "closed"}`
2. **GateEventuallyOpens**: `<>(gate = "open")` — temporal property

## Expected Result

- TLC should report `No error has been found`
- TLC explores multiple coin-insertion orderings (quarters and dimes in different sequences)
- The assert never fires (because 50 cents is reachable well before 100)
- GateEventuallyOpens passes with weak fairness
- The state count varies by label choice, but the key outcomes (no assert fire, gate opens eventually) are invariant. Explore: what's the maximum `paid` value TLC discovers? (Hint: all dimes = 50, but what if the last insert is a quarter on top of 40?)

## Hints

??? hint "💡 Hint 1 — Nondeterminism in the loop"
    Inside the loop, `either/or` picks whether to insert a quarter or a dime. TLC explores both branches at each iteration. The loop runs until paid >= 50. How many different orderings of coins can reach exactly 50 (or exceed it)?

??? hint "💡 Hint 2 — Asserts are line-specific checks"
    `assert paid <= 100` fires ONLY at that line, only when execution passes through. It's a sanity check: "if we ever get here, this must be true." It's not an invariant (checked in every state). The assert only cares about THIS moment in the computation.

??? hint "💡 Hint 3 — Weak fairness ensures liveness"
    With `fair process`, weak fairness means TLC doesn't deadlock — the process eventually takes a step if it can. Without `fair`, TLC might get stuck and falsely report a deadlock. The temporal property `<>(gate = "open")` relies on fairness to guarantee eventually someone inserts a coin.
