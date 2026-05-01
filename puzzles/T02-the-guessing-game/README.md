# T02: The Guessing Game ⭐

## Lesson: Nondeterminism with `with`

Until now, your specs had one initial state and one execution path. NONDETERMINISM lets TLC explore MULTIPLE paths from the same spec. Two ways to introduce it:

- **At initialization:** `variables x \in S` — TLC tries every value in `S` as the starting value of `x`
- **At runtime:** `with (y \in S) { ... }` — TLC tries every value in `S` as `y` at that step, exploring all branches

Combined, they multiply: 5 initial values × 5 runtime values = 25 possible executions, and TLC checks every one.

**Worked example — a vending machine and a button.**

A vending machine is stocked with one candy of an unknown type. A customer approaches and pushes one of three buttons. We want TLC to explore every combination of stocked candy and pressed button.

```
(*--algorithm Vending {
  variables candy \in {"chocolate", "mint", "lemon"},
            pushed = "none";

  fair process (customer = "Customer") {
    push:
      with (b \in {"A", "B", "C"}) {
        pushed := b;
      };
  }
}*)
```

Sample invariants:

- `TypeOK == candy \in {"chocolate", "mint", "lemon"} /\ pushed \in {"A", "B", "C", "none"}`
- `NeverMint == candy /= "mint"` — TLC WILL violate this and show the mint-candy branch as the counterexample

TLC explores 3 candy values × 3 button values = 9 executions. When you ask it to check `NeverMint`, the initial state itself is the counterexample — no runtime steps needed, TLC just shows that the spec allows `candy = "mint"` from the start.

Note the two syntaxes side by side:
- `\in` at declaration picks an initial value
- `with (b \in S) { ... }` picks a value INSIDE a label and binds it to a local name for the scope of the block

Both expand the state space. Both are exhaustively checked by TLC.

## Setup

A number between 1 and 5 is chosen at random. A player guesses, also at random. If the guess matches, the game ends with "won". If not, the game ends with "lost".

This is the simplest possible game — one random choice, one random guess, one comparison. No loops. No retries.

## Task

Write a PlusCal spec with:

- A variable `secret` chosen nondeterministically at initialization
- A variable `guess` starting at 0
- A variable `result` starting at `"playing"`
- A single process that:
  1. Chooses a `guess` nondeterministically at runtime
  2. Sets `result` to `"won"` if guess = secret, `"lost"` otherwise

## Check

Add these invariants:

1. **TypeOK**: `secret` and `guess` are in the right ranges, `result` is in `{"playing", "won", "lost"}`
2. **NeverWins**: `result /= "won"` — this SHOULD be violated

## Expected Result

- TLC should report `No error has been found`
- NeverWins should be violated with a short trace — TLC finds the lucky guess
- TypeOK should pass
- The canonical solution reports **30 distinct states** (5 initial + 25 outcomes); your label choices may produce more or fewer. TLC reports both "states generated" and "distinct states found." Different label boundaries (e.g., a separate `choose:` and `check:` step vs. one combined label) produce different state counts. Both answers are correct — they reflect different modeling choices about atomicity. What matters is that NeverWins violation is found.

## Hints

??? hint "💡 Hint 1 — Nondeterminism multiplies the state space"
    5 possible secrets × 5 possible guesses = 25 branching paths. Plus the initial state, plus a final "done" state. Not 10 states — many more. TLC explores all combinations. Does the state count match?

??? hint "💡 Hint 2 — Use `with` at runtime, not initialization"
    The secret is chosen ONCE at the start (use `\in` at initialization). The guess is chosen ONCE during the game (use `with` in a label). Both introduce nondeterminism — in different places. Which one picks the initial value?

??? hint "💡 Hint 3 — The 'NeverWins' violation should fire immediately"
    If you claim `result /= "won"` as an invariant, TLC checks that in the initial state BEFORE any step. But `result` starts as `"playing"`, not `"won"`, so the initial state is fine. After the guess label, some paths lead to `"won"`. THAT state violates the invariant.
