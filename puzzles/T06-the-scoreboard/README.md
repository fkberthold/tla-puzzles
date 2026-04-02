# T06: The Scoreboard ⭐

## Setup

Two teams — Home and Away — play a game. Each round, one team scores a point (chosen nondeterministically). The game ends after 5 rounds.

Instead of writing complex invariant expressions inline, define OPERATORS in the `define` block that give names to useful concepts.

## Task

Write a PlusCal spec with:
- Variables `home` and `away` starting at 0
- A variable `round` starting at 0
- A single process that loops 5 times, each time awarding a point to either home or away

In the `define` block, create these operators:
- `TotalPoints == home + away`
- `HomeLeads == home > away`
- `Tied == home = away`
- `GameOver == round = 5`
- `ValidScore(s) == s \in 0..5`

## Check

1. **TypeOK**: use your operators! `ValidScore(home) /\ ValidScore(away) /\ round \in 0..5`
2. **PointsConserved**: `TotalPoints = round` — total points always equals rounds played
3. **HomeAlwaysLeads**: `HomeLeads` — this SHOULD be violated (TLC finds a path where Away scores first)

## Expected Result

- TLC should find **27 distinct states**
- PointsConserved should PASS (it's a real invariant of the system)
- HomeAlwaysLeads should be violated by the INITIAL STATE — TLC catches it immediately because 0-0 is a tie, not a lead. Invariants check the initial state too!

## Concept

**The `define` block — operators as vocabulary.** Operators make specs READABLE. `TotalPoints = round` is clearer than `home + away = round`. Operators also make specs MAINTAINABLE — if the scoring changes, you update one definition instead of every invariant. This is the TLA+ equivalent of naming your functions.
