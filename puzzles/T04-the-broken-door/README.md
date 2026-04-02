# T04: The Broken Door ⭐⭐

## Setup

A room has a door that can be locked or unlocked. Two people — Alice and Bob — each try to do the same thing: check if the door is unlocked, then walk through it and lock it behind them.

The problem: checking the door and walking through are TWO SEPARATE STEPS. Between Alice checking and Alice walking through, Bob might check too — and both think the door is open.

## Task

Write a PlusCal spec with:
- A variable `door` starting at `"unlocked"`
- A variable `through` — a set of who has walked through, starting at `{}`
- Two processes (Alice and Bob) that each:
  1. **check**: `await door = "unlocked"` (wait until the door is unlocked)
  2. **walk**: set `door := "locked"` and add themselves to `through`

Note: `check` and `walk` are TWO LABELS — two separate atomic steps. This is the key.

Use `if` (not `await`) for the check — if the door is locked, the process just finishes without walking through.

## Check

1. **TypeOK**: `door` in `{"locked", "unlocked"}`, `through` subset of `{"Alice", "Bob"}`
2. **MutualExclusion**: `Cardinality(through) <= 1` — at most one person walks through

## Expected Result

- **MutualExclusion WILL BE VIOLATED.** TLC finds a trace where both Alice and Bob walk through.
- The trace shows the interleaving: Alice checks (unlocked), Bob checks (still unlocked — Alice hasn't walked yet!), Alice walks through, Bob walks through.
- This is the classic TOCTOU (time-of-check-to-time-of-use) race condition.

## Concept

**Labels create interleaving points.** When `check` and `walk` are separate labels, another process can execute between them. This is where concurrent bugs live — in the GAP between checking a condition and acting on it. If you put both operations in ONE label (one atomic step), the bug disappears. Try it both ways and see.

## Hint

Process sets:
```
fair process (person \in {"Alice", "Bob"}) {
  check:
    await door = "unlocked";
  walk:
    door := "locked";
    through := through \union {self};
}
```

The `self` keyword gives you the process identity ("Alice" or "Bob").
