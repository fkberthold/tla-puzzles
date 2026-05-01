# T50: CONSTANTS and ASSUME ⭐

## Lesson: Parameterizing a Spec

Until now, every value in your specs has been a literal — `cups = 0`, `tickets = 3`, ranges like `0..3`. Real specs need parameters: the same logic should work for a 10-element queue or a 1000-element queue without rewriting.

`CONSTANT` declares an unspecified value at the top of a module. The .cfg file binds it before TLC runs. `ASSUME` adds a STATIC PRECONDITION — an assertion that must hold of the constants. TLC checks every `ASSUME` once at startup and aborts if any is false.

```
CONSTANT N
ASSUME N \in Nat /\ N > 0
```

Two things happen:

1. `N` becomes available everywhere in the module as if it were a defined value.
2. TLC verifies your assumption before model-checking starts. If the cfg gave `N = -3`, TLC stops with "Assumption ... is false" and never tries to explore states.

`ASSUME` is NOT an invariant. Invariants are checked on every reachable state during exploration; assumptions are checked ONCE at startup, on the constants themselves. Use `ASSUME` for "this only makes sense if N is a positive natural number" — facts about the parameters, not the running system.

**Worked example — a tournament bracket.**

A tournament has `Rounds` rounds. Each round eliminates half the players. So we need `Rounds \in Nat` and the starting player count is `2^Rounds`. Here, both `Rounds` and `Players` are constants, but they're related, so `ASSUME` enforces the relation:

```
---- MODULE Tournament ----
EXTENDS Integers, TLC

CONSTANTS Rounds, Players

ASSUME Rounds \in Nat
ASSUME Rounds >= 1
ASSUME Players \in Nat
ASSUME Players = 2^Rounds   \* Players must equal 2 to the Rounds-th power

(*--algorithm Tournament {
  variables remaining = Players, round = 0;

  fair process (referee = "Referee") {
    play:
      while (round < Rounds) {
        remaining := remaining \div 2;
        round := round + 1;
      }
  }
}*)
====
```

Cfg:

```
SPECIFICATION Spec
CONSTANT Rounds = 3
CONSTANT Players = 8
INVARIANT TypeOK
```

If you change the cfg to `Rounds = 3, Players = 7`, TLC dies with `Assumption ... is false` BEFORE running. Try `Rounds = 4, Players = 16` and the spec runs with a deeper bracket.

Note: `CONSTANTS` (with the S) lets you list multiple. `CONSTANT` (no S) is the same — both are accepted. Each `ASSUME` is a separate top-level declaration; you can have many.

## Setup

A library has `Capacity` books. Patrons borrow and return them one at a time. The library should never go below 0 books or above `Capacity`.

You're going to write a parameterized spec — the same code must work for a library of 5 books or 500.

## Task

Create `solution/Library.tla` and `solution/Library.cfg`.

In the .tla file:

- `EXTENDS Integers`
- `CONSTANT Capacity`
- `ASSUME Capacity \in Nat /\ Capacity >= 1`
- A PlusCal algorithm with one variable `books` (count of books currently in the library)
- One `fair process (clerk = "Clerk")` that loops 5 times. On each iteration it nondeterministically borrows (decrements `books`, only if `books > 0`) or returns (increments `books`, only if `books < Capacity`). Use `either/or` and the `await`-like guards.

Add invariants:

- `TypeOK == books \in 0..Capacity`
- `Bounded == books >= 0 /\ books <= Capacity`

In the .cfg file:

- `SPECIFICATION Spec`
- `CONSTANT Capacity = 3`
- `INVARIANT TypeOK`
- `INVARIANT Bounded`

## Check

```bash
cd solution
tlc -pcal Library.tla
tlc Library
```

Then experiment:

1. Change the cfg to `CONSTANT Capacity = 5` and re-run. State count should grow.
2. Change to `CONSTANT Capacity = 0`. TLC should ABORT with "Assumption ... is false" before exploring any state.

## Expected Result

- With `Capacity = 3`: a small reachable state space (under 100 distinct states).
- All invariants pass.
- Setting `Capacity = 0` triggers the assumption failure — TLC reports "Assumption line ... is false."

## Hints

??? hint "💡 Hint 1 — CONSTANT declares a parameter; ASSUME checks it"
    CONSTANT makes a name available like a defined value. ASSUME is a STATIC precondition — TLC verifies it at startup on the constants alone, not on every reachable state. Use ASSUME for "N must be a positive integer."

??? hint "💡 Hint 2 — Bind constants in the .cfg, not the .tla"
    Your .tla file declares CONSTANT Capacity. The .cfg file says CONSTANT Capacity = 3. TLC reads the cfg, binds the constant, then explores. If you want to change the Capacity for a new run, edit the cfg (don't touch the .tla).

??? hint "💡 Hint 3 — Your guards implicitly use the constant"
    The clerk loops 5 times, borrowing if books > 0 and returning if books < Capacity. The second condition depends on the CONSTANT Capacity. TLC will respect the parameterization.

