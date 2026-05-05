# Scaffolding Map

Per-puzzle scaffolding ledger and concept-coverage histogram. Pairs with [QUALITY_GATE.md](QUALITY_GATE.md)'s sharpened [Strip Test](QUALITY_GATE.md#3-the-strip-test) — every non-exempt puzzle must compose its new concept with at least one *non-trivial* prior concept. This file is where that composition is recorded.

Style: **hand-maintained.** Unlike [CURRICULUM_MAP.md](CURRICULUM_MAP.md), which is regenerated from `bd list` by `scripts/gen-curriculum-map.sh`, no script reads or writes this file. It is updated by the same audit pass that visits each puzzle (the tla-3vt epic).

Two views:

1. **Per-puzzle table** (below) — one row per puzzle: ID, title, new concept, scaffolding concept(s) used.
2. **[Coverage histogram](#coverage-histogram)** (bottom) — for each prior concept, the later puzzles that reuse it as scaffolding. Empty until audits land.

When picking scaffolding for a new puzzle, consult the histogram and avoid concepts already heavily used in the recent stretch. Variety is the goal: every prior concept should reappear in later puzzles, but no concept should dominate a tier.

> **Note on column values.** `New concept` is filled best-effort from the puzzle's labels and title; the audit confirms or revises. `Scaffolding` legend:
>
> - `concept:foo, concept:bar` — confirmed by audit. Comma-separated tags from the project's concept taxonomy (the `concept:*`, `apa:*`, and `workflow:*` label families used in `bd list`).
> - `TBD` — not yet audited.
> - `exempt (no priors)` — T01, the curriculum's first concept puzzle.
> - `exempt (capstone)` — capstone whose job is to compose prior concepts; passes Gate 3 by construction.
> - `exempt-pending (Tier 0 audit)` — T0a–T0e; whether the prior-load expectation applies is part of tla-3vt.1.
> - `(review)` — R-puzzles introduce no new concept; treatment under the gates is part of the audit.
> - `(judgment)` — J-puzzles teach a meta-skill (when to use which technique); treatment under the gates is part of the audit.

---

## Tier 0 — Prelude (Workflow Basics)

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| T0a | First Run — Hello, TLC | workflow:tlc-run | exempt-pending (Tier 0 audit) |
| T0b | Reading a Counterexample | workflow:read-trace | exempt-pending (Tier 0 audit) |
| T0c | The .cfg File — Anatomy and Editing | workflow:cfg-anatomy | exempt-pending (Tier 0 audit) |
| T0d | pcal — The Translator | workflow:pcal-translate | exempt-pending (Tier 0 audit) |
| T0e | Anatomy of a TLA+ Module | workflow:module-anatomy | exempt-pending (Tier 0 audit) |

## Tier 1 — PlusCal Basics

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| T01 | The Light Switch | first-spec (variables, label, while, invariant) | exempt (no priors) |
| T02 | The Guessing Game | concept:with | TBD |
| T03 | The Fork in the Road | concept:either-or | TBD |
| T04 | The Broken Door | concept:multi-label-race | TBD |
| T05 | The Toll Booth | concept:assert | TBD |
| T06 | The Scoreboard | concept:define-block | TBD |
| T07 | The Off-By-One | concept:deliberate-violation | TBD |
| T08 | The Ticket Machine (capstone) | (capstone — composes prior) | exempt (capstone) |

## Tier 2 — PlusCal Data Structures

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| R01 | Review — Either/Or in a New Skin | (review) | (review) |
| R02 | Review — Define Block in a New Skin | (review) | (review) |
| R03 | Review — Process Set with self | (review) | (review) |
| T09 | Records — Constructor, Dot, EXCEPT | concept:record-constructor | TBD |
| T10 | Sequences — Literal, Append, 1-Indexed Access | concept:sequence-literal | TBD |
| T11 | Sequences — Concat and SubSeq | concept:sequence-concat | TBD |
| T12 | Functions — Constructor | concept:function-constructor | TBD |
| T13 | Functions — Application and DOMAIN | concept:function-application | TBD |
| T14 | Functions — EXCEPT Update | concept:function-except | TBD |
| T15 | Functions — EXCEPT with @ | concept:function-except-at | TBD |
| T16 | Function Sets — [S -> T] | concept:function-set | TBD |
| T17 | Set Comprehension — Filter | concept:set-comprehension-filter | TBD |
| T18 | Set Comprehension — Map | concept:set-comprehension-map | TBD |
| T19 | \\subseteq and SUBSET | concept:subseteq | TBD |
| T20 | Cardinality and FiniteSets | concept:cardinality | TBD |
| T21 | CHOOSE — Picking a Witness | concept:choose | TBD |
| T22 | IF/THEN/ELSE Expressions and CASE | concept:case-expression | TBD |
| T23 | LET-IN | concept:let-in | TBD |
| T24 | Quantifiers in Invariants | concept:forall | TBD |
| T25 | Tier 2 Capstone | (capstone — composes prior) | exempt (capstone) |

## Tier 3 — Pure TLA+ Pivot

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| R04 | Review — Records via TLA+ EXCEPT | (review) | (review) |
| R05 | Review — Sequences in Pure TLA+ | (review) | (review) |
| T26 | Reading a Pure TLA+ Spec | concept:plain-tla-translation | TBD |
| T27 | The Level System — Recognize Each | concept:level-action | TBD |
| T28 | Writing Init Predicates | concept:init-predicate | TBD |
| T29 | UNCHANGED for Stability | concept:unchanged | TBD |
| T30 | Writing Next as a Single Action | concept:next-relation | TBD |
| T31 | Disjunction in Next — Multiple Actions | concept:action-disjunction | TBD |
| T32 | Spec Form and [A]_v | concept:square-bracket-action | TBD |
| T33 | Counter in Pure TLA+ | concept:spec-form | TBD |
| T34 | Tier 3 Capstone — Pure TLA+ from Scratch | (capstone — composes prior) | exempt (capstone) |

## Tier 4 — Multi-Process & Synchronization

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| C01 | Cross-Tier Capstone (Tiers 2-4) | (cross-capstone — composes prior) | exempt (capstone) |
| R06 | Review — Function-as-State | (review) | (review) |
| R07 | Review — Nondeterministic Init in Pure TLA+ | (review) | (review) |
| T35 | Distinct Processes (Asymmetric) | concept:distinct-processes | TBD |
| T36 | await for Synchronization | concept:await | TBD |
| T37 | ENABLED — When Can An Action Fire? | concept:enabled | TBD |
| T38 | Producer/Consumer with a Queue | concept:producer-consumer | TBD |
| T39 | Mini-Mutex (Two-Process) | concept:mutex | TBD |
| T40 | Procedures and call/return | concept:procedure-call | TBD |
| T41 | Tier 4 Capstone — Bounded Buffer | (capstone — composes prior) | exempt (capstone) |

## Tier 5 — Temporal Logic & Fairness

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| R08 | Review — Quantifiers in Properties | (review) | (review) |
| R09 | Review — Either/Or with Liveness | (review) | (review) |
| T42 | <> Eventually — Deeper | concept:eventually | TBD |
| T43 | [] Always — As Property | concept:always | TBD |
| T44 | ~> Leads-To | concept:leads-to | TBD |
| T44b | Leads-To Failure — When ~> Doesn't Hold | concept:liveness-debug (leads-to failure mode) | TBD |
| T45 | []<> Infinitely Often | concept:infinitely-often | TBD |
| T46 | <>[] Eventually Always | concept:eventually-always | TBD |
| T47 | Strong Fairness | concept:strong-fairness | TBD |
| T47b | Reading Lasso Traces — Stem and Cycle Anatomy | concept:lasso-trace | TBD |
| T48 | Liveness Debugging | concept:liveness-debug | TBD |
| T49 | Tier 5 Capstone — Request/Response System | (capstone — composes prior) | exempt (capstone) |

## Tier 6 — Specification Structure & Refinement

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| C02 | Cross-Tier Capstone (Tiers 4-6) | (cross-capstone — composes prior) | exempt (capstone) |
| R10 | Review — Pure TLA+ Init Refresh | (review) | (review) |
| R11 | Review — Multi-Process Refresh | (review) | (review) |
| T50 | CONSTANTS and ASSUME | concept:constants | TBD |
| T51 | Multi-Module Specs | concept:multi-module | TBD |
| T52 | INSTANCE for Parameterization | concept:instance | TBD |
| T53 | Refinement — The Abstract Spec | concept:refinement-abstract | TBD |
| T54 | Refinement — The Concrete Spec | concept:refinement-concrete | TBD |
| T55 | Refinement — Variable Mapping | concept:refinement-mapping | TBD |
| T56 | Refinement — Auxiliary Variables | concept:refinement-auxiliary | TBD |
| T57 | Refinement — Stuttering Steps | concept:refinement-stutter | TBD |
| T58 | Refinement — Debugging a Failed Refinement | concept:refinement-debug | TBD |
| T59 | Tier 6 Capstone — Two-Level Refinement | (capstone — composes prior) | exempt (capstone) |

## Tier 7 — Production Craft

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| R12 | Review — Refinement Quick Refresh | (review) | (review) |
| R13 | Review — Boundary Values | (review) | (review) |
| T60 | SYMMETRY for State-Space Reduction | concept:symmetry | TBD |
| T61 | VIEW for Equivalence Classes | concept:view | TBD |
| T62 | Model Values vs Concrete Values | concept:model-value | TBD |
| T63 | -coverage for Spec Hygiene | concept:coverage | TBD |
| T64 | -simulate Mode | concept:simulate | TBD |
| T65 | -difftrace and Debugging Workflow | concept:difftrace | TBD |
| T66 | Tier 7 Capstone — Production-Ready Spec | (capstone — composes prior) | exempt (capstone) |

## Apalache Track

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| A01 | Apalache — Hello, Snowcat | apa:type-base | TBD |
| A02 | Apalache — Composite Types | apa:type-composite | TBD |
| A03 | Apalache — Type Aliases | apa:type-alias | TBD |
| A04 | Apalache — := for Explicit Assignment | apa:assign | TBD |
| A05 | Apalache — Folds (ApaFoldSet) | apa:fold | TBD |
| A06 | Apalache — Terminal Stutter | apa:terminal-stutter | TBD |
| A07 | Apalache — --cinit for Constants | apa:cinit | TBD |
| A08 | Apalache — TLC vs Apalache Comparison | apa:vs-tlc | TBD |
| A09 | Apalache Capstone — Full Type-Annotated Spec | (capstone — composes prior) | exempt (capstone) |
| A10 | TLC + Apalache Joint Capstone | (capstone — composes prior) | exempt (capstone) |

## Judgment Intersticials

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| J01 | Judgment — When records vs separate variables? | (judgment) | (judgment) |
| J02 | Judgment — PlusCal vs Pure TLA+ for X? | (judgment) | (judgment) |
| J03 | Judgment — TLC vs Apalache for X? | (judgment) | (judgment) |
| J04 | Judgment — When to Use Refinement? | (judgment) | (judgment) |
| J05 | Judgment — Choosing Fairness Type | (judgment) | (judgment) |
| J06 | Judgment — Safety vs Liveness | (judgment) | (judgment) |
| J07 | Judgment — When to split a label vs combine actions? | (judgment) | (judgment) |

## Final Capstone

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| T67 | Final Capstone — Distributed Counter | (capstone — composes prior) | exempt (capstone) |

---

## Coverage Histogram

For each prior concept, the later puzzles that reuse it as scaffolding. Populated as audits land — empty until the tla-4ln Tier 1 pilot fills its share.

| Prior concept | Reused as scaffolding in |
|---|---|
| (empty — populated by tla-4ln + tla-3vt audits) | |

When this histogram is non-trivial, watch for:

- **Concepts with zero reuse** — taught once, never reinforced. Either fold a review puzzle in, or move the concept later so it reappears.
- **Concepts with heavy reuse in a short stretch** — e.g., `concept:either-or` scaffolding three consecutive puzzles. Choose a different prior concept for the next puzzle in that stretch.
- **Concepts whose reuse all clusters in one tier** — same problem, longer wavelength. Spread them across tiers when possible.
