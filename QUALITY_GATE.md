# Puzzle Quality Gate

Every puzzle must pass ALL seven checks before inclusion. No exceptions.

## 1. Concept Uniqueness
What ONE new thing does this puzzle teach that no previous puzzle taught?
If you can't name it in one sentence, the puzzle is redundant. Cut it.

## 2. Minimal Novelty
Does the puzzle introduce ONLY that one concept, or does it sneak in two?
If a learner who solved all previous puzzles needs to learn exactly one new thing, it's right.
If they need two new things, split the puzzle.

Exception: T01 (the "hello world" puzzle) may introduce multiple basics simultaneously.

## 3. The Strip Test
Strip the new concept from the puzzle's task. What remains must contain at least one *non-trivial prior concept* the learner must compose — not just "assign a variable" or "increment a counter." If the residual task is trivial, the puzzle is demo-with-renames: revise it by composing the new concept with one or more prior concepts as scaffolding.

When picking scaffolding for a new puzzle, consult [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md); avoid concepts already heavily used in the recent stretch. The map's per-puzzle table records what each puzzle composes; the histogram surfaces concept overuse.

See [Exemptions](#exemptions) for puzzles where this gate doesn't apply.

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

## 7. Demonstration–Puzzle Domain Disjoint
The lesson at the top of the puzzle must include a WORKED EXAMPLE that:
- (a) shows the FULL technique — syntax, mechanics, the thing the learner needs in their hands; and
- (b) uses a domain fundamentally different from the puzzle's setting.

If a learner could solve the puzzle by copying the lesson-example with variables renamed, the lesson gives it away and fails. Description alone does not count as demonstration — the example must be runnable PlusCal in a different domain, so the learner has to ABSTRACT the technique from the example and APPLY it to the puzzle.

**Demo bareness.** The worked demo must teach **only** the new concept, with the minimum state variables, processes, and labels needed to demonstrate it. The demo carries no scaffolding from prior concepts. The asymmetry is deliberate: **bare demo, composed puzzle** — the demo isolates the new technique so the learner can see it pure; the puzzle composes it with scaffolding so the learner can't shortcut by renaming.

Exception: capstone puzzles that introduce no new concept (T08) replace the worked demo with a recap of prior techniques shown in a fresh composition.

This rule pairs with the Strip Test. Together they enforce the same meta-principle: the learner must GENERALIZE. No shortcut from prior puzzles (strip test), no shortcut from the intro (domain-disjoint demo).

See [Exemptions](#exemptions) for puzzles where the prior-load expectation doesn't apply.

---

## Exemptions

Gate 3 (Strip Test) and Gate 7's prior-load expectation both assume the puzzle has prior concepts available to compose with. Three classes of puzzle are exempt:

- **T01** — already exempt from Gate 2 (Minimal Novelty); no prior concept exists to scaffold against.
- **Capstones that introduce no new concept** — pass by construction. Their job is to compose existing concepts, and they replace Gate 7's worked demo with a fresh composition of prior techniques. Cross-tier capstones (C01, C02) are in this class.
- **Tier 0 prelude (T0a–T0e)** — workflow puzzles, not concept puzzles. Each prelude puzzle presents a single pre-written spec and walks the learner through running it; there is no demo + puzzle dual structure for Gate 3 (Strip Test) or Gate 7 (Demo Bareness, Demo–Puzzle Domain Disjoint) to apply against. Confirmed by the Tier 0 audit (2026-05-05); per-puzzle exemption tags recorded in [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md).

Reviews (R-puzzles) and judgments (J-puzzles) introduce no new concept by definition; their treatment under the gates is part of the audit and not yet final.

---

## Process

1. Name the ONE concept
2. Write the puzzle description (README.md)
3. Write the lesson section at the TOP with a worked example in a different domain
4. Write the PlusCal solution
5. Run `pcal` to translate
6. Run TLC — verify passes and violations
7. Record state count and trace lengths
8. Apply all seven checks
9. If any check fails, revise or cut
