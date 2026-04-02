# T02: The Guessing Game ⭐

## Setup

A number between 1 and 5 is chosen at random. A player guesses, also at random. If the guess matches, the game ends with "won". If not, the game ends with "lost".

This is the simplest possible game — one random choice, one random guess, one comparison. No loops. No retries.

## Task

Write a PlusCal spec with:
- A variable `secret` chosen nondeterministically from `1..5` at initialization
- A variable `guess` starting at 0
- A variable `result` starting at `"playing"`
- A single process that:
  1. Chooses a `guess` nondeterministically from `1..5` using `with`
  2. Sets `result` to `"won"` if guess = secret, `"lost"` otherwise

## Check

Add these invariants:
1. **TypeOK**: `secret` and `guess` are in the right ranges, `result` is in `{"playing", "won", "lost"}`
2. **NeverWins**: `result /= "won"` — this SHOULD be violated (TLC finds a path where the player wins)

## Expected Result

- TLC should find **55 distinct states** (5 secrets × 5 guesses × 3 phases, minus sharing — explore and count!)
- NeverWins should be violated with a SHORT trace — TLC finds the lucky guess
- TypeOK should pass

## Concept

**Nondeterminism with `with`.** This is the first spec where TLC explores MULTIPLE paths. The `secret` is chosen nondeterministically at init (`\in`), and the `guess` is chosen nondeterministically at runtime (`with`). TLC checks ALL combinations. You write one spec; TLC runs twenty-five games.

## Hint

Nondeterministic initialization:
```
variables secret \in 1..5, guess = 0, result = "playing";
```

Nondeterministic runtime choice:
```
with (g \in 1..5) {
  guess := g;
};
```
