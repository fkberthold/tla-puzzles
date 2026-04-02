# T05: The Toll Booth ⭐

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

## Concept

**`assert` — runtime checks inside the algorithm.** Invariants check every state from the OUTSIDE. Asserts check from INSIDE the algorithm, at a specific point. If an assert fails, TLC reports it as an error at that line. Asserts are useful for sanity checks ("this should never happen at THIS point in the code") as opposed to invariants ("this should never be true in ANY state").
