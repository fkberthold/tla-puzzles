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

Gate 3 (Strip Test) and Gate 7's prior-load expectation both assume the puzzle has prior concepts available to compose with. The following classes of puzzle are exempt:

- **T01** — already exempt from Gate 2 (Minimal Novelty); no prior concept exists to scaffold against.
- **Capstones that introduce no new concept** — pass by construction. Their job is to compose existing concepts, and they replace Gate 7's worked demo with a fresh composition of prior techniques. Cross-tier capstones (C01, C02) and the Final Capstone (T67) are in this class.
- **Tier 0 prelude (T0a–T0e) and intra-tier preludes (T47b)** — workflow puzzles, not concept puzzles. Each prelude puzzle presents a single pre-written spec and walks the learner through running it (Tier 0 covers TLC/PCal toolchain basics; T47b is the Tier 5 prelude on reading lasso traces). There is no demo + puzzle dual structure for Gate 3 (Strip Test) or Gate 7 (Demo Bareness, Demo–Puzzle Domain Disjoint) to apply against. Confirmed by the Tier 0 audit (tla-3vt.1, 2026-05-05) and the Tier 5 audit (tla-3vt.5, 2026-05-05); per-puzzle exemption tags recorded in [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md).
- **T26 (Tier 3 entry — Reading a Pure TLA+ Spec)** — Tier 3's pivot puzzle from PlusCal to pure TLA+. T26 teaches reading the Init/Next/Spec triple via worked questions about a pre-written spec; there is no demo + puzzle dual structure of the Tier-1+ shape (worked example + learner-task in different domains), and no prior pure-TLA+ concept exists yet for the strip test to remove. The exemption mirrors T01's no-priors clause within the new medium. Confirmed by the Tier 3 audit (tla-3vt.3, 2026-05-05); per-puzzle exemption tag recorded in [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md).
- **Tier 7 production craft (T60–T65)** — workflow puzzles, not concept puzzles. Each Tier 7 concept-bearing puzzle teaches a `workflow:*` operation — a TLC cfg directive (`SYMMETRY`, `VIEW`, model values) or CLI flag (`-coverage`, `-simulate`, `-difftrace`) — by giving the learner a pre-written abstract spec, a toggle (cfg edit or flag), and an observation task (count states, read the coverage report, contrast traces). The lesson DOES include a worked example in a different domain, but the puzzle's task is not authoring; it is running and observing. Gate 3's strip test has nothing to strip from a "run TLC with this flag" task, and Gate 7's demo-bareness expectation pairs the demo with an authoring puzzle that doesn't exist here. Confirmed by the Tier 7 audit (tla-3vt.7, 2026-05-05); per-puzzle exemption tags recorded in [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md). T66 (Tier 7 capstone) is exempt under the standard capstone clause above.
- **Apalache Track (A01–A10)** — toolchain puzzles that teach symbolic-checker features (`apa:*` taxonomy: type-base, type-composite, type-alias, assign, fold, terminal-stutter, cinit, vs-tlc), not curriculum concepts (`concept:*`). The track is a parallel thread, not a sequel to Tier 1+: each Apalache puzzle teaches one Apalache feature on a small pure-TLA+ spec. Gate 3's prior-load expectation has no `concept:*` targets to compose against, and Gate 7's demo-bareness clause is satisfied by construction (each demo isolates its `apa:*` feature on the minimum spec needed to exhibit it). Within-track composition (later A-puzzles building on earlier `apa:*` priors) is recorded in [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md) via `apa:*` scaffolding tags rather than enforced by Gate 3. Gate 7's domain-disjoint demo clause still applies and holds by inspection (each puzzle's demo and task live in different domains). Confirmed by the Apalache Track audit (tla-3vt.8, 2026-05-05); per-puzzle exemption tags recorded in [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md).
- **Judgment intersticials (J01–J07)** — meta-skill puzzles, not concept puzzles. Each judgment presents two (or more) pre-written specs side by side ("Side A vs Side B") plus a rubric for choosing between them; the lesson teaches *when to use which technique*, not a new `concept:*` from the taxonomy. There is no demo + puzzle dual structure for Gate 3 (Strip Test) or Gate 7 (Demo Bareness, Demo–Puzzle Domain Disjoint) to apply against, and the strip test has no new concept to remove. Confirmed by the Judgment audit (tla-3vt.9, 2026-05-05); per-puzzle exemption tags recorded in [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md).
- **Review puzzles (R01–R13)** — refresh-only puzzles that re-drill a prior concept in a fresh domain. There is no "new concept" to strip (Gate 3) and no demo bareness expectation (Gate 7's bareness clause), because the demo's job is precisely to recap a prior technique. The Demo–Puzzle Domain Disjoint half of Gate 7 still applies and is the active gate for R-puzzles: the demo's domain must differ from the puzzle's. Confirmed by the cross-tier audit (tla-3vt.10, 2026-05-05); per-puzzle exemption tags recorded in [SCAFFOLDING_MAP.md](SCAFFOLDING_MAP.md).

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
