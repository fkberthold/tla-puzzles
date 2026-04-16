# T04: The Broken Door ⭐⭐

## Lesson: Multiple Labels — Atomicity and Interleaving

Everything between two labels happens as one INDIVISIBLE step. When you split code across multiple labels, you create an INTERLEAVING POINT — a moment where another process can run before your process continues. This is where concurrent bugs live: in the gap between one atomic step and the next.

**Worked example — an ATM withdrawal race.**

Two ATMs share one bank account with $60. Each ATM independently checks whether there's enough money, then debits $50. Because "check" and "debit" sit in different labels, both ATMs can see $60 before either debits — and both can debit.

```
(*--algorithm ATM {
  variables balance = 60;

  fair process (atm \in {"ATM1", "ATM2"}) {
    check:
      if (balance >= 50) {
        goto debit;
      } else {
        goto done;
      };
    debit:
      balance := balance - 50;
      goto done;
    done:
      skip;
  }
}*)
```

**`goto LABEL` in PlusCal.** The example uses `goto debit` and `goto done` to jump to specific labels. `goto LABEL` ends the current atomic step and schedules the named label as the next one to execute. Think of it as `break` or `continue` but by name — useful when you want to skip past the next sequential label or jump to an explicit endpoint instead of falling through. Without `goto`, execution falls through to whichever label appears next in the code. You only need `goto` when you want to divert that flow.

Sample invariants:

- `TypeOK == balance \in -40..60`
- `NoOverdraft == balance >= 0` — TLC WILL violate this

TLC finds the interleaving in 5 steps:

1. ATM1 at `check`: sees balance = 60, goes to `debit`
2. ATM2 at `check`, **before ATM1 debits**: sees balance = 60, goes to `debit`
3. ATM1 debits: balance = 10
4. ATM2 debits: balance = -40
5. Both reach `done`; `NoOverdraft` violated

Three labels, two processes, race exposed.

**The fix** is to collapse `check` and `debit` into a SINGLE label — then the interleaving point disappears. Either both operations happen together for ATM1, then both for ATM2, or vice versa. Overdraft becomes impossible.

```
lockAndDebit:
  if (balance >= 50) {
    balance := balance - 50;
  };
```

In real systems, you'd use a database transaction or a lock to collapse the race. The spec models this as "one label."

**The `self` keyword** inside a process body gives the identity of the currently running process — `"ATM1"` or `"ATM2"` in this example. You'll need it in the puzzle.

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

## Hint

```
fair process (person \in {"Alice", "Bob"}) {
  ...
}
```

Use `self` inside the process body for the person's identity.
