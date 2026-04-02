# Puzzle Quality Gate

Every puzzle must pass ALL six checks before inclusion. No exceptions.

## 1. Concept Uniqueness
What ONE new thing does this puzzle teach that no previous puzzle taught?
If you can't name it in one sentence, the puzzle is redundant. Cut it.

## 2. Minimal Novelty
Does the puzzle introduce ONLY that one concept, or does it sneak in two?
If a learner who solved all previous puzzles needs to learn exactly one new thing, it's right.
If they need two new things, split the puzzle.

Exception: T01 (the "hello world" puzzle) may introduce multiple basics simultaneously.

## 3. The Strip Test
Remove the new concept. Does the puzzle collapse into a previous puzzle?
- If yes: the new concept is load-bearing. The puzzle is justified. Pass.
- If no: the puzzle is decoration around something already covered. Cut it.

## 4. The 15-Minute Test
Could someone who JUST solved the previous puzzle write this one in 15 minutes?
Calibration: if the author solves it in 2 minutes, it's a 15-minute `*` puzzle for a learner.
If the author takes 10 minutes, it's a 30-minute `**` puzzle.
If the author takes 30 minutes, it's either `***` or needs splitting.

## 5. TLC Verification
- PlusCal source only — run `pcal` to translate, NEVER hand-write TLA+
- TLC passes intended properties
- TLC VIOLATES intended violations
- State count and depth recorded in solution notes

## 6. Trace Quality
When TLC finds a violation, the counterexample trace must be:
- SHORT: under 10 states (ideally under 5)
- READABLE: a learner can follow the trace and understand WHY the invariant failed
- INSTRUCTIVE: the trace teaches the concept, not just demonstrates the tool

A 3-state violation trace teaches. A 15-state trace confuses. If the trace is too long,
simplify the puzzle (fewer variables, smaller domains, fewer processes).

---

## Process

1. Name the ONE concept
2. Write the puzzle description (README.md)
3. Write the PlusCal solution
4. Run `pcal` to translate
5. Run TLC — verify passes and violations
6. Record state count and trace lengths
7. Apply all six checks
8. If any check fails, revise or cut
