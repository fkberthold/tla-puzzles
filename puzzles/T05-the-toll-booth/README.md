# T05: The Toll Booth ⭐

## Lesson: `assert` — Runtime Checks Inside the Algorithm

INVARIANTS check properties from OUTSIDE the algorithm — they apply to every reachable state, all the time. `assert` checks from INSIDE the algorithm, at a specific point in the code. If an assert fails, TLC reports it at that line and shows the trace that led there.

Use invariants for global properties ("this is true in every state"). Use asserts for local sanity checks ("at THIS point, this had better be true").

**Worked example — a pressure cooker.**

A cooker heats water, pressure rising each tick. The design intent is to vent at 15 psi and cap at 20 as a safety limit. We `assert` the safety limit inside the heating loop to catch any design error.

```
(*--algorithm PressureCooker {
  variables pressure = 0;

  fair process (cooker = "Cooker") {
    heat:
      while (pressure < 15) {
        pressure := pressure + 2;
        assert pressure <= 20;  \* sanity check inside the loop
      }
  }
}*)
```

Sample invariants:

- `TypeOK == pressure \in 0..20`

Trace the assert's behavior:

- Starting at 0, pressure goes 2, 4, 6, 8, 10, 12, 14, 16 — loop exits when pressure >= 15, so the last increment produces 16. The assert `pressure <= 20` holds throughout. No firing. Safe design.
- If you changed the increment from 2 to 11, pressure goes 0, 11, 22. The assert fires at the line `assert pressure <= 20` with pressure = 22. TLC reports the error at the assert's exact line and stops exploring that branch.

Asserts are checked EVERY time execution passes through them — unlike invariants (checked against every state), asserts are checked against execution flow. They catch "impossible" internal states that may become possible under unexpected inputs.

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

- TLC explores multiple coin-insertion orderings (quarters and dimes in different sequences)
- The assert never fires (because 50 cents is reachable well before 100)
- GateEventuallyOpens passes with weak fairness
- Explore: what's the maximum `paid` value TLC discovers? (Hint: all dimes = 50, but what if the last insert is a quarter on top of 40?)
