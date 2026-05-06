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
> - `exempt (prelude — workflow, not concept)` — T0a–T0e; toolchain puzzles with no demo/puzzle dual structure for Gate 3 or Gate 7 to apply against. Confirmed by tla-3vt.1.
> - `exempt (review — refresh, not new concept)` — R01–R13; refresh-only puzzles. Gate 3 doesn't apply (nothing to strip) and Gate 7's Demo Bareness doesn't apply (the demo's job is to recap a prior technique). Demo–Puzzle Domain Disjoint still applies. Confirmed by tla-3vt.10.
> - `exempt (production-craft — workflow, not concept)` — T60–T65; Tier 7 puzzles teach `workflow:*` operations (SYMMETRY, VIEW, model values, `-coverage`, `-simulate`, `-difftrace`) through pre-written specs the learner runs and toggles, not composes. Confirmed by tla-3vt.7.
> - `exempt (apalache track — tool feature, not concept)` — A01–A08; Apalache Track puzzles teach `apa:*` toolchain features (type system, `:=` explicit assignment, folds, terminal stutter, `--cinit`, TLC↔Apalache comparison), parallel to Tier 1+ rather than composing it. Confirmed by tla-3vt.8.
> - `exempt (judgment — meta-skill, not concept)` — J01–J07; judgment puzzles teach a meta-skill (when to use which prior technique) by presenting two pre-written specs side by side plus a rubric, with no demo + puzzle dual structure. Confirmed by tla-3vt.9.
> - `(judgment)` — J-puzzles teach a meta-skill (when to use which technique); treatment under the gates is owned by the Judgments audit (tla-3vt.9).

---

## Tier 0 — Prelude (Workflow Basics)

Audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.1 (2026-05-05). All five prelude puzzles are exempt from Gate 3 and Gate 7's prior-load and demo-bareness expectations: each prelude puzzle presents a single pre-written spec and walks through running it (no demo + puzzle dual structure), and each teaches a `workflow:*` operation rather than a `concept:*` from the curriculum's concept taxonomy. The remaining gates (Concept Uniqueness, 15-Minute, TLC Verification, Trace Quality) apply and hold by inspection.

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| T0a | First Run — Hello, TLC | workflow:tlc-run | exempt (prelude — workflow, not concept) |
| T0b | Reading a Counterexample | workflow:read-trace | exempt (prelude — workflow, not concept) |
| T0c | The .cfg File — Anatomy and Editing | workflow:cfg-anatomy | exempt (prelude — workflow, not concept) |
| T0d | pcal — The Translator | workflow:pcal-translate | exempt (prelude — workflow, not concept) |
| T0e | Anatomy of a TLA+ Module | workflow:module-anatomy | exempt (prelude — workflow, not concept) |

## Tier 1 — PlusCal Basics

Audited against sharpened Gate 3 + extended Gate 7 by the tla-4ln pilot (2026-05-05).

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| T01 | The Light Switch | first-spec (variables, label, while, invariant) | exempt (no priors) |
| T02 | The Guessing Game | concept:with, concept:nondet-init | concept:if-pluscal (residue: comparison drives result) |
| T03 | The Fork in the Road | concept:either-or | concept:with (residue: snack-picking nondeterminism) |
| T04 | The Broken Door | concept:multi-label-race | concept:label, concept:variables (Gate 2 note: bundles new process-set + self) |
| T05 | The Toll Booth | concept:assert | concept:while, concept:either-or, concept:eventually |
| T06 | The Scoreboard | concept:define-block | concept:while, concept:either-or, concept:variables |
| T07 | The Off-By-One | concept:deliberate-violation | concept:while, concept:if-pluscal |
| T08 | The Ticket Machine (capstone) | (capstone — composes prior) | exempt (capstone) |

**Pilot revisions shipped (tla-4ln, branch tla-4ln):**

- **T03** — full puzzle revision. Original puzzle's strip-test residue was two trivial assignments; revised puzzle composes `either/or` (new) with `with` (T02 prior) — hiker chooses lake/summit, then `with` picks a snack. State count: 9 distinct (was 5).
- **T05** — demo replaced. Original pressure-cooker demo used `while` loop (T01 scaffolding); revised demo (`Doorman` checking ID) shows `assert` in 1 var / 1 process / 1 label, no scaffolding. Puzzle unchanged.
- **T06** — demo replaced. Original weather-station demo used `while` + `with` + multiple operators; revised demo (`TempName`) shows `define` with one operator assigned in one label, no prior-concept scaffolding. Puzzle unchanged.
- **T07** — demo replaced. Original recipe-scaler demo used `while` + 2 labels; revised demo (`Claim`) shows the deliberate-violation pattern with `done := TRUE` while `pending` is still `TRUE`, no loop. Puzzle unchanged.

**T02 and T04 are borderline** — both passed Gate 3 by reading the strip-test residue charitably (T02: if/else comparison composition; T04: multi-process structure beyond the new race concept). T04 also surfaces a Gate 2 concern (the puzzle introduces process-set + `self` alongside multi-label-race); that's outside this pilot's scope and is parked for a future Gate 2 sweep.

## Tier 2 — PlusCal Data Structures

T09–T24 audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.2 (2026-05-05). Two demo-bareness revisions shipped (T10, T17). The remaining non-exempt rows pass Gate 3 by reading the strip-test residue charitably: the dominant Tier 2 puzzle shape is "compose the new data-structure concept with `define`-block-named invariants over a sequence of phase-incrementing labels," and the residue counts as `concept:define-block` composition rather than the trivial "increment a counter" the rule warns against. Most Tier 2 demos also use a `define` block to name an operator that uses the new concept; that is the natural carrier when the new concept is an EXPRESSION rather than a STATEMENT and is treated here as the concept's vehicle, not as Gate 7 scaffolding. Demos that additionally carry `while`, `with`, or other prior STATEMENTS (T10, T17 in their pre-revision form) failed Gate 7's bareness clause and were replaced. Cross-tier and R-row scope (R01–R03) is owned by tla-3vt.10. T25 (capstone) is exempt by construction.

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| R01 | Review — Either/Or in a New Skin | refresh: concept:either-or (T03) | exempt (review — refresh, not new concept) |
| R02 | Review — Define Block in a New Skin | refresh: concept:define-block (T06) | exempt (review — refresh, not new concept) |
| R03 | Review — Process Set with self | refresh: concept:multi-label-race + self (T04) | exempt (review — refresh, not new concept) |
| T09 | Records — Constructor, Dot, EXCEPT | concept:record-constructor | concept:define-block (residue: define names invariants over the record state across 4 sequenced labels) |
| T10 | Sequences — Literal, Append, 1-Indexed Access | concept:sequence-literal | concept:while, concept:with, concept:define-block (residue: while-loop over with-chosen orders, plus serve label) |
| T11 | Sequences — Concat and SubSeq | concept:sequence-concat | concept:define-block (residue: 3-label sequence with named operators) |
| T12 | Functions — Constructor | concept:function-constructor | concept:define-block (residue: define names DOMAIN/AllSame invariants) |
| T13 | Functions — Application and DOMAIN | concept:function-application | concept:define-block (residue: Count/Titles operators over 3 sequenced labels) |
| T14 | Functions — EXCEPT Update | concept:function-except | concept:define-block (residue: Teams/EndsCorrect operators over 4 sequenced labels) |
| T15 | Functions — EXCEPT with @ | concept:function-except-at | concept:function-except, concept:define-block (residue: stripping `@` leaves T14's full EXCEPT update over 4 labels) |
| T16 | Function Sets — [S -> T] | concept:function-set | concept:with, concept:function-constructor, concept:define-block (residue: with picks from a named set; constructor initializes the variable) |
| T17 | Set Comprehension — Filter | concept:set-comprehension-filter | concept:function-application, concept:define-block (residue: 3-label scan reading `loaned[b]` against equality/non-equality) |
| T18 | Set Comprehension — Map | concept:set-comprehension-map | concept:function-application, concept:define-block (residue: derive label reads `level[s]` over the function's DOMAIN) |
| T19 | \\subseteq and SUBSET | concept:subseteq | concept:with, concept:define-block (residue: with picks team and captain across two labels) |
| T20 | Cardinality and FiniteSets | concept:cardinality | concept:with, concept:subseteq, concept:define-block (residue: with-driven SUBSET pick + cardinality readout) |
| T21 | CHOOSE — Picking a Witness | concept:choose | concept:define-block (residue: AnyTicket/SmallestAtLeast2 named operators applied across 2 sequenced labels) |
| T22 | IF/THEN/ELSE Expressions and CASE | concept:case-expression | concept:while, concept:define-block (residue: while-loop ticking 0..5 with parameterized operators) |
| T23 | LET-IN | concept:let-in | concept:define-block, concept:function-application (residue: Final operator carrying LET, applied across 2 sequenced labels) |
| T24 | Quantifiers in Invariants | concept:forall | concept:with, concept:function-set, concept:function-constructor, concept:define-block (residue: nested with over [Drones -> ...] driving the violation traces) |
| T25 | Tier 2 Capstone | (capstone — composes prior) | exempt (capstone) |

**Revisions shipped (tla-3vt.2, branch worktree-agent-a2a46be5):**

- **T10** — demo replaced (README only). Original recipe-log demo carried `while` + `with` + `define` (three priors, mirroring the T05/T06 pattern the Tier 1 pilot rejected). Revised demo (`Stamps`) shows the literal `<<"penny", "dime">>`, one `Append`, and 1-indexed access in 1 var, 1 process, 1 label, no while/with/define. Indexing/Head/Tail/Len mechanics moved into prose. Puzzle solution unchanged.
- **T17** — demo replaced (README only). Original wedding-RSVP demo carried `define` + `with` + function-set `[Guests -> {"yes","no"}]` (three priors, T16 forward-leaning even though T17 follows T16). Revised demo (`EvenFilter`) shows `{n \in nums : n % 2 = 0}` in 2 vars, 1 process, 1 label, no define/with. Puzzle solution unchanged.

**Borderline notes.** Every non-exempt T-row in Tier 2 sits at PASS-borderline rather than clean PASS, for one or both of two reasons: (a) the Strip-Test residue is a `define`-block-named invariant set over a phase-counter loop — which is "non-trivial composition" per the Tier 1 pilot's reading of Gate 3, but only just; and (b) the demo block uses a `define` block to name an operator that uses the new concept (e.g., `AllSeatings == [S -> T]` in T16, `NumOccupied == Cardinality(occupied)` in T20). The `define` block is treated as the concept's carrier rather than as Gate 7 scaffolding when the new concept is an EXPRESSION; if a future Gate 7 sweep wants to harden bareness for expression-shaped concepts, T09/T11–T16/T18–T24 demos are the candidates to revisit. T11 also bundles two new sub-concepts (`\o` and `SubSeq`) into one puzzle, which is a Gate 1/Gate 2 minimal-novelty concern parked for the same future sweep that the Tier 1 pilot deferred for T04.

## Tier 3 — Pure TLA+ Pivot

Audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.3 (2026-05-05). Tier 3 is the pivot from PlusCal to pure TLA+: the *medium itself* is what changes. Priors for the strip test are read within this tier (the Init/Next/Spec triple from T26 onward), not from Tier 1 PlusCal — composing PlusCal `while` into a pure-TLA+ Init predicate is structurally meaningless. T26 is the tier's "first pure-TLA+ puzzle" and gets a dedicated entry-puzzle exemption analogous to T01's no-priors exemption: it teaches reading the Init/Next/Spec triple via worked questions (no synthesis), so the strip test has nothing to strip and the demo + puzzle pair is reading-only rather than worked-example + learner-task. R04 / R05 untouched (R-series resolution parked for tla-3vt.10).

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| R04 | Review — Records via TLA+ EXCEPT | refresh: concept:record-constructor + concept:function-except (T09, T14, T15) in pure TLA+ | exempt (review — refresh, not new concept) |
| R05 | Review — Sequences in Pure TLA+ | refresh: concept:sequence-literal + Append/Tail (T10, T11) in pure TLA+ | exempt (review — refresh, not new concept) |
| T26 | Reading a Pure TLA+ Spec | concept:plain-tla-translation | exempt (Tier 3 entry — first pure-TLA+ puzzle, reading-only) |
| T27 | The Level System — Recognize Each | concept:level-action | concept:plain-tla-translation (residue: classify named formulas in a Lock spec) |
| T28 | Writing Init Predicates | concept:init-predicate | concept:plain-tla-translation (residue: assemble Init/Next/Spec around the new `\in` Init) |
| T29 | UNCHANGED for Stability | concept:unchanged | concept:plain-tla-translation, concept:init-predicate (residue: multi-variable spec with IF-THEN-ELSE branches) |
| T30 | Writing Next as a Single Action | concept:next-relation | concept:init-predicate, concept:unchanged (residue: synthesize a whole spec from prose) |
| T31 | Disjunction in Next — Multiple Actions | concept:action-disjunction | concept:next-relation, concept:unchanged (residue: 3-action smart bulb composition) |
| T32 | Spec Form and [A]_v | concept:square-bracket-action | concept:action-disjunction, concept:eventually (residue: liveness flip on a 2-action counter) |
| T33 | Counter in Pure TLA+ | concept:spec-form (synthesis — Gate 1 note: no genuinely new mechanic) | concept:action-disjunction, concept:unchanged, concept:init-predicate, concept:square-bracket-action, concept:deliberate-violation |
| T34 | Tier 3 Capstone — Pure TLA+ from Scratch | (capstone — composes prior) | exempt (capstone) |

**T28 and T33 are borderline.**

- **T28** — demo (Chess King) uses `\E dx, dy \in {-1, 0, 1}` in `Move` to compact the 8 directional moves. `\E` is Tier 2 territory (T24 quantifiers, not yet introduced). The `\E` here is purely syntactic compaction, not a teaching point — it could be unrolled to explicit alternatives — but it sits in the demo body. Recorded as borderline so future authors can choose to swap the demo when Tier 2 priors are available; revising now would churn the demo without changing the strip-test verdict.
- **T33** — README explicitly says "no new mechanic; you reach for what you already know." Gate 1 (Concept Uniqueness) asks "what ONE new thing does this puzzle teach?" — T33's answer is *synthesis*, which is a tier-recap skill, not a concept. The pre-filled `concept:spec-form` is suspect: T32 already taught the `[A]_v` spec form; T33's actual job is composing five Tier 3 pieces under one roof, exactly like a mini-capstone before the formal T34 capstone. Recorded as borderline-PASS with a Gate 1 note; resolution (rename concept, lift to capstone, or accept synthesis-as-concept) parked alongside T04's Gate 2 note for a later Gate 1/2 sweep.

**No revisions shipped this audit.** All Tier 3 demos pass demo-bareness on the new concept. The Tier 1 pre-bareness pattern (T05/T06/T07 demos carrying `while`-loops from a prior puzzle, in violation of Gate 7's bareness clause) does not appear in Tier 3, because Tier 3 demos are constructively built up from T26's spec triple — every demo uses exactly the priors needed to express the new concept and no scaffolding from "outside" beyond T28's borderline `\E`. The pivot is the meta-concept: every puzzle's demo and task share the same medium (pure TLA+), and the only legitimate pre-bareness risk would be PlusCal vestiges, of which there are none.

## Tier 4 — Multi-Process & Synchronization

T35–T41 audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.4 (2026-05-05). C01, R06, R07 are scoped to tla-3vt.10 and remain TBD here.

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| C01 | Cross-Tier Capstone (Tiers 2-4) | (cross-capstone — composes prior) | exempt (capstone) |
| R06 | Review — Function-as-State | refresh: concept:function-constructor + concept:function-except + self (T12, T14, T04) | exempt (review — refresh, not new concept) |
| R07 | Review — Nondeterministic Init in Pure TLA+ | refresh: concept:init-predicate with `\E` (T28) | exempt (review — refresh, not new concept) |
| T35 | Distinct Processes (Asymmetric) | concept:distinct-processes | concept:while, concept:variables, concept:deliberate-violation (residue: two-process race exposed by interleaving) |
| T36 | await for Synchronization | concept:await | concept:distinct-processes (residue: two-process handoff with ordering invariant) |
| T37 | ENABLED — When Can An Action Fire? | concept:enabled | concept:next-relation, concept:action-disjunction, concept:square-bracket-action, concept:spec-form (residue: pure-TLA+ spec with multi-action Next) |
| T38 | Producer/Consumer with a Queue | concept:producer-consumer | concept:await, concept:sequence-literal, concept:sequence-concat, concept:distinct-processes, concept:while (Gate 1 note: pattern-as-concept, mini-capstone shape) |
| T39 | Mini-Mutex (Two-Process) | concept:mutex | concept:await, concept:multi-label-race, concept:cardinality (residue: T04 race scenario without atomicity) |
| T40 | Procedures and call/return | concept:procedure-call | concept:distinct-processes, concept:if-pluscal, concept:variables (residue: two-process shared-counter accumulation) |
| T41 | Tier 4 Capstone — Bounded Buffer | (capstone — composes prior) | exempt (capstone) |

**Revisions shipped (tla-3vt.4):**

- **T35** — demo replaced. Original Mailroom demo carried `while` loops + integer counters in BOTH process bodies (postman delivers 3, sorter sorts 5), violating Gate 7's demo-bareness clause the same way T05/T06/T07 did in the tla-4ln pilot. Revised demo (`Stage`: Spotlight + Actor) shows two `fair process (NAME = "ID")` blocks with one label and one assignment each — the minimum needed to demonstrate asymmetric distinct-process declaration. Puzzle (Kitchen) unchanged.

**Borderline notes:**

- **T38** — borderline-PASS. The "new concept" `concept:producer-consumer` is a *compositional pattern* rather than a new piece of syntax (the README explicitly says "no new syntax; you're just fitting pieces together"). This is structurally a mini-capstone bundling `await` (T36) + `Append`/`Head`/`Tail` (T10/T11) + `distinct-processes` (T35) + `while` (T01). **Gate 1 concern flagged**: pattern-as-concept may not satisfy Concept Uniqueness as cleanly as a syntax-introducing puzzle. Demo also carries a `Len(queue) < 3` cap that previews T41's bounded-buffer; could be trimmed but is not a hard violation. Parked alongside T04's process-set-bundling note for a future Gate 1/Gate 2 minimal-novelty sweep.
- **T39** — borderline on Gate 7 demo–puzzle domain disjointness. Bathroom-key (demo) and printer-flag (puzzle) both use the "shared-physical-resource gated by a boolean flag with a process set tracking holders" frame; the artifacts differ but the cognitive shape is similar. Acceptable under the rubric (different domains, different invariant names) but worth noting as the curriculum's tightest disjointness margin so far.
- **T40** — minor demo-bareness margin. Piggy-bank demo defines TWO procedures (`deposit`, `withdraw`) and a saver making 3 sequential calls plus a trailing `s4: skip`. The two-procedures + multi-call shape is justifiable to show parameters varying per call, but a barer demo (one procedure, one call) was available. Recorded as borderline rather than revised since the demo's extras teach the parameter-varies-per-call point.

## Tier 5 — Temporal Logic & Fairness

Audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.5 (2026-05-05). T47b is exempt from Gate 3 and Gate 7 as an intra-tier prelude (workflow puzzle on lasso-reading; the puzzle README self-describes as "Tier 5 prelude. No new concept. No code to write.") — same exemption shape as T0a–T0e, with the QUALITY_GATE.md exemption clause extended to cover it. T49 is exempt by capstone construction. The remaining eight concept puzzles (T42, T43, T44, T44b, T45, T46, T47, T48) all introduce a temporal-logic operator or a liveness-debug workflow; their specs irreducibly carry concurrency scaffolding (a fair process, a loop, await/either) to host the temporal property under check, so the strip-test residue is always non-trivial. Gate 7's demo-bareness clause was the binding constraint — see borderline notes below; one demo (T42) was replaced.

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| R08 | Review — Quantifiers in Properties | refresh: concept:forall (T24) inside a `<>` property | exempt (review — refresh, not new concept) |
| R09 | Review — Either/Or with Liveness | refresh: concept:either-or + concept:eventually + WF semantics of `fair process` (T03) | exempt (review — refresh, not new concept) |
| T42 | <> Eventually — Deeper | concept:eventually (conjunction) | concept:either-or, concept:while, concept:eventually (T03 prior; the "deeper" form composes multiple `<>` claims into one property) |
| T43 | [] Always — As Property | concept:always | concept:either-or, concept:if-pluscal, concept:while (residue: thermostat 3-branch up/down/hold guarded loop) |
| T44 | ~> Leads-To | concept:leads-to | concept:await, concept:either-or, concept:while (residue: client/server two-process await coordination) |
| T44b | Leads-To Failure — When ~> Doesn't Hold | concept:liveness-debug (leads-to failure mode) | concept:leads-to, concept:await, concept:either-or (T44 prior; debug workflow on a leads-to violation) |
| T45 | []<> Infinitely Often | concept:infinitely-often | concept:label, concept:while (residue: two-label pulse/rest cycle) |
| T46 | <>[] Eventually Always | concept:eventually-always | concept:either-or, concept:if-pluscal, concept:while (residue: counter-with-skip stabilization) |
| T47 | Strong Fairness | concept:strong-fairness | concept:await, concept:either-or, concept:if-pluscal, concept:infinitely-often (T45 prior; user/printer flicker pattern) |
| T47b | Reading Lasso Traces — Stem and Cycle Anatomy | workflow:read-lasso | exempt (prelude — workflow, not concept) |
| T48 | Liveness Debugging | concept:liveness-debug | concept:await, concept:infinitely-often (T45 prior; debug workflow — diagnose and add fairness) |
| T49 | Tier 5 Capstone — Request/Response System | (capstone — composes prior) | exempt (capstone) |

**Tier 5 revisions shipped (tla-3vt.5, branch worktree-agent-ae72bbe8):**

- **T42** — demo replaced (README only). Original "Packet clearing three security checkpoints" demo used `while + either/or/or + 3 booleans + fair process`, structurally identical to the puzzle's morning-routine spec; a learner could solve the puzzle by renaming the demo's variables. Replaced with a "Stopwatch" demo: 1 variable `t = 0`, 3 sequential labels (`tick`, `tick2`, `tick3`) advancing `t` to 1, 2, 3, fair process, no `while`, no `either/or`. The new demo isolates the conjunction-of-`<>` concept on a barer spec (1 var, 1 process, 3 labels, no branching) and is structurally distinct from the puzzle (boolean flags + branching either/or/or in the puzzle vs. monotonic counter + sequential labels in the demo). Strip-test residue in the puzzle (3 booleans + either/or/or + while-fair-process) is non-trivial. Puzzle solution unchanged. Gate 5 verify-puzzle.sh: PASS-CLEAN.

**QUALITY_GATE.md extension shipped (tla-3vt.5):**

- **Exemptions clause (line ~67)**: extended the Tier 0 prelude clause to cover intra-tier preludes (T47b). T47b's README self-classifies as "Tier 5 prelude. No new concept. No code to write." — functionally identical to T0b (read counterexample) but for liveness/lasso traces. Same exemption rationale applies (no demo + puzzle dual structure; teaches `workflow:read-lasso`, not a `concept:*` from the curriculum's concept taxonomy).

**Borderline notes (Tier 5):**

- **T43, T44, T47** are borderline-PASS on Gate 7's demo-bareness/domain-disjoint axis. Each demo and puzzle share the same dominant structural pattern because the temporal operator under instruction *only makes sense* in that pattern: `[]P` requires a state-predicate-on-a-loop spec (T43); `~>` requires a request/response 2-process pattern (T44); `SF` requires a self-disabling-action-with-flickering-precondition pattern (T47). Each demo lives in a different domain than its puzzle (bank account vs. thermostat for T43; elevator vs. client/server for T44; bus stop vs. printer for T47), so the renames trick is partial — the learner must abstract the temporal operator from the demo and apply it to the puzzle, but the surface structure is similar enough that a careless rename works on parts of the spec. Recorded as borderline; not revised.
- **T44b and T48** both teach `concept:liveness-debug` — Gate 1 (Concept Uniqueness) borderline. T44b is the leads-to-specific failure mode (puzzle ID `concept:liveness-debug (leads-to failure mode)`); T48 is the general lasso-debug workflow. Tier 5's pedagogy positions T44b as the leads-to-specific case study while T48 generalizes to any liveness violation. Recorded as borderline; not revised.
- **T44b and T48 demos** are the puzzle's broken-spec pattern in a different domain (water cooler / courier+sender). The demo *is* the diagnosis worked example: same broken-fairness pattern, same fix. Gate 7's demo-bareness clause is met (each demo isolates the diagnose-and-fix workflow on a minimal spec) but Gate 7's domain-disjoint clause is borderline because the diagnosis pattern itself is the lesson. Recorded as borderline.

## Tier 6 — Specification Structure & Refinement

T50–T59 audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.6 (2026-05-05). All nine non-capstone puzzles PASS. Two are recorded borderline: T50 (heavier-than-bare Tournament demo) and T58 (counter-vs-clock domain proximity). No REVISE work shipped — borderline-PASS is a legitimate matrix outcome under the sharpened gates and mirrors the tla-4ln pilot's treatment of T02. Tier 6's refinement puzzles (T53–T58) introduce a multi-spec structure (abstract module + concrete module); their demos are mini abstract+concrete pairs in domains disjoint from the puzzle, applied judgmentally rather than by single-spec bareness. C02, R10, R11 audited by tla-3vt.10.

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| C02 | Cross-Tier Capstone (Tiers 4-6) | (cross-capstone — composes prior) | exempt (capstone) |
| R10 | Review — Pure TLA+ Init Refresh | refresh: concept:init-predicate with `\/` + `\in` (T28) | exempt (review — refresh, not new concept) |
| R11 | Review — Multi-Process Refresh | refresh: concept:distinct-processes + concept:await (T35, T36) | exempt (review — refresh, not new concept) |
| T50 | CONSTANTS and ASSUME | concept:constants | concept:either-or, concept:while, concept:await, concept:variables (borderline: Tournament demo carries `while` + fair process) |
| T51 | Multi-Module Specs | concept:multi-module | concept:init-predicate, concept:next-relation, concept:spec-form |
| T52 | INSTANCE for Parameterization | concept:instance | concept:constants, concept:spec-form, concept:action-disjunction, concept:unchanged |
| T53 | Refinement — The Abstract Spec | concept:refinement-abstract | concept:constants, concept:next-relation, concept:spec-form, concept:choose |
| T54 | Refinement — The Concrete Spec | concept:refinement-concrete | concept:refinement-abstract, concept:instance, concept:next-relation |
| T55 | Refinement — Variable Mapping | concept:refinement-mapping | concept:refinement-abstract, concept:refinement-concrete, concept:instance, concept:action-disjunction |
| T56 | Refinement — Auxiliary Variables | concept:refinement-auxiliary | concept:refinement-mapping, concept:refinement-concrete, concept:instance |
| T57 | Refinement — Stuttering Steps | concept:refinement-stutter | concept:square-bracket-action, concept:refinement-concrete, concept:refinement-mapping |
| T58 | Refinement — Debugging a Failed Refinement | concept:refinement-debug | concept:refinement-concrete, concept:refinement-stutter, concept:deliberate-violation (borderline: clock-counter demo near integer-counter puzzle domain) |
| T59 | Tier 6 Capstone — Two-Level Refinement | (capstone — composes prior) | exempt (capstone) |

**Borderline notes:**

- **T50** — PASS borderline (Gate 7 demo bareness). The Tournament demo carries `while` (T01), `fair process` (T04), and `\div` arithmetic alongside the new CONSTANT/ASSUME content. The multi-constant relation (`Players = 2^Rounds`) does enrich the ASSUME demo beyond the puzzle's single-constant case, which partially justifies the demo complexity. By Tier 6, `while` is foundational and treating it as scaffolding-noise in a demo is a defensible relaxation versus the strict Tier 1 bareness; recording the borderline preserves the question for a future bareness sweep without forcing churn.
- **T58** — PASS borderline (Gate 7 domain disjoint). The demo (clock with broken minute rollover) and the puzzle (integer counter with broken Reset guard) both center on counter-style state machines; the demo isn't in a *fundamentally* different domain. T58's pedagogy is debugging-by-trace-reading, which inherently re-uses the structural pattern of the puzzle to teach the bug taxonomy — same constraint pattern as T07 (`concept:deliberate-violation`). Recorded; revisitable.

## Tier 7 — Production Craft

Audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.7 (2026-05-05). All six concept-bearing Tier 7 puzzles (T60–T65) are exempt from Gate 3 and Gate 7's prior-load and demo-bareness expectations: each presents a pre-written abstract spec and walks the learner through running TLC with a flag (`SYMMETRY`, `VIEW`, model-value cfg, `-coverage`, `-simulate`, `-difftrace`) and observing what changes — no demo + authoring dual structure. The new concept is a `workflow:*`-shape operation (cfg directive or CLI flag), not a `concept:*` from the curriculum's concept taxonomy, so the prior-load expectation has no targets in the same way as the Tier 0 prelude. README worked examples DO appear in T60–T65 (unlike Tier 0), but they illustrate the workflow on a different domain rather than serving as a Gate-7 demo paired with a Gate-3 authoring task. The remaining gates (Concept Uniqueness, 15-Minute, TLC Verification, Trace Quality) apply and hold by inspection. T66 (capstone) is exempt by construction. R12, R13 are review puzzles, deferred to tla-3vt.10.

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| R12 | Review — Refinement Quick Refresh | refresh: concept:refinement-mapping via INSTANCE WITH (T53–T55) | exempt (review — refresh, not new concept) |
| R13 | Review — Boundary Values | refresh: spec hygiene — small CONSTANTS for tractable state space (cross-tier) | exempt (review — refresh, not new concept) |
| T60 | SYMMETRY for State-Space Reduction | workflow:symmetry | exempt (production-craft — workflow, not concept) |
| T61 | VIEW for Equivalence Classes | workflow:view | exempt (production-craft — workflow, not concept) |
| T62 | Model Values vs Concrete Values | workflow:model-value | exempt (production-craft — workflow, not concept) |
| T63 | -coverage for Spec Hygiene | workflow:coverage | exempt (production-craft — workflow, not concept) |
| T64 | -simulate Mode | workflow:simulate | exempt (production-craft — workflow, not concept) |
| T65 | -difftrace and Debugging Workflow | workflow:difftrace | exempt (production-craft — workflow, not concept) |
| T66 | Tier 7 Capstone — Production-Ready Spec | (capstone — composes prior) | exempt (capstone) |

**Audit verdicts (7/7, with R12/R13 deferred):**

- T60: exempt (production-craft — workflow, not concept). Teaches `SYMMETRY` cfg directive + `Permutations(...)` from the `TLC` module. Pre-written `Lockers` spec; learner toggles the SYMMETRY line and re-runs.
- T61: exempt (production-craft). Teaches `VIEW` cfg directive. Pre-written `Hopper` spec with unbounded `history` variable; learner toggles VIEW and observes finite-vs-infinite state space.
- T62: exempt (production-craft). Teaches the model-value vs concrete-value judgment (and the `Permutations(S \ {distinguished})` pattern). Pre-written `Tasks` spec; learner edits cfg to swap model values for strings and observes TLC's symmetry rejection.
- T63: exempt (production-craft). Teaches `-coverage N` CLI flag. Pre-written `Vending` spec with a deliberately dead `Refunder` action; learner reads the per-action / per-line coverage report.
- T64: exempt (production-craft). Teaches `-simulate num=N -depth D` CLI mode. Pre-written `RandomWalk` spec with intractable BFS; carries `solution/.verify-skip` ("teaches -simulate mode; intractable under standard BFS by design") so `verify-puzzle.sh` skips the BFS run that would never terminate. Verification floor preserved by the SKIP verdict — not a FAIL.
- T65: exempt (production-craft). Teaches `-difftrace` CLI flag. Pre-written `Inventory` spec with 9 fruits + `sold` (deliberate violation); learner contrasts the full-state trace against the diff trace.
- T66: exempt (capstone). Composes prior Tier 7 techniques on a `Scheduler` spec — boundary values (`WorkerSlots = 1`), model values (`Jobs = {j1, j2, j3}`), `SYMMETRY`, `VIEW`, `-coverage` walkthrough, `-simulate` smoke test, deliberate-violation step using `-difftrace`.

**Borderline notes:**

- T60 has a Gate 2 (Minimal Novelty) note in its own README ("Two New Things at Once — Model Values & SYMMETRY"). The lesson explicitly bundles model values with SYMMETRY because SYMMETRY is meaningless without model values, then T62 returns to model values as a standalone judgment. This is a deliberate pedagogical choice (introduce the inseparable pair, then unpack the judgment one puzzle later) rather than a Gate 2 violation; recorded here for retrievability.
- T64's `.verify-skip` is the right escape valve: the puzzle's *whole point* is that BFS doesn't terminate, so `verify-puzzle.sh` must not insist on a green BFS run. The exemption marker is the same shape used elsewhere in the curriculum for "expected non-termination" specs.

**No revisions shipped.** All seven puzzles pass the gates as-is under the workflow-not-concept exemption. No demo-bareness fixes needed (worked examples are present and domain-disjoint, but they aren't load-bearing under the exemption — Gate 7 doesn't apply).

## Apalache Track

Audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.8 (2026-05-05). All eight non-capstone Apalache puzzles are exempt from Gate 3 (Strip Test) and Gate 7's prior-load + demo-bareness expectations: each puzzle teaches a single `apa:*` Apalache feature (type system, `:=` discipline, `ApaFoldSet`, terminal stutter, `--cinit`, TLC↔Apalache comparison) on a small pure-TLA+ spec rather than a `concept:*` from the curriculum's concept taxonomy. The Apalache track is a parallel thread, not a sequel to Tier 1+, so the prior-load expectation has no `concept:*` targets. Within-track composition (later A-puzzles building on earlier `apa:*` priors) is recorded as a parenthetical hint after the exempt tag for histogram visibility. Gate 7's domain-disjoint clause applies and holds by inspection (each puzzle's demo and task live in different domains: A01 thermostat→vending machine, A02 music library→package tracker, A03 chess→library catalog, A04 stopwatch→door, A05 grade book→warehouse, A06 cake-bake→counter, A07 bounded queue→bank account, A08 counter→token bucket). The remaining gates (Concept Uniqueness, Minimal Novelty, 15-Minute, TLC Verification, Trace Quality) apply and hold by inspection.

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| A01 | Apalache — Hello, Snowcat | apa:type-base | exempt (apalache track — tool feature, not concept) |
| A02 | Apalache — Composite Types | apa:type-composite | exempt (apalache track — tool feature, not concept; within-track: apa:type-base) |
| A03 | Apalache — Type Aliases | apa:type-alias | exempt (apalache track — tool feature, not concept; within-track: apa:type-composite) |
| A04 | Apalache — := for Explicit Assignment | apa:assign | exempt (apalache track — tool feature, not concept; within-track: apa:type-base) |
| A05 | Apalache — Folds (ApaFoldSet) | apa:fold | exempt (apalache track — tool feature, not concept; within-track: apa:assign, apa:type-alias, apa:type-composite) |
| A06 | Apalache — Terminal Stutter | apa:terminal-stutter | exempt (apalache track — tool feature, not concept; within-track: apa:assign) |
| A07 | Apalache — --cinit for Constants | apa:cinit | exempt (apalache track — tool feature, not concept; within-track: apa:assign, apa:terminal-stutter) |
| A08 | Apalache — TLC vs Apalache Comparison | apa:vs-tlc | exempt (apalache track — tool feature, not concept; within-track: apa:cinit) |
| A09 | Apalache Capstone — Full Type-Annotated Spec | (capstone — composes prior) | exempt (capstone) |
| A10 | TLC + Apalache Joint Capstone | (capstone — composes prior) | exempt (capstone) |

**Audit verdicts (10/10):** A01–A08 exempt (apalache track — tool feature, not concept); A09–A10 exempt (capstone — composes prior `apa:*` techniques). All ten pass `./scripts/verify-puzzle.sh` PASS-CLEAN under TLC; the `solution/Apalache.tla` shim (the official Apalache standard library) is correctly handled by `verify-puzzle.sh` (skipped as a `.tla` without a `.cfg`, copied alongside the puzzle's spec when present). No revisions shipped — all eight non-capstone puzzles already follow the demo-bareness pattern under their toolchain interpretation, and the capstones (A09 Pizzeria, A10 Buffer) compose prior `apa:*` techniques without new concept introduction.

**Borderline notes.** None at puzzle level. The track-wide exemption rationale (the `apa:*` taxonomy parallels rather than composes-with `concept:*`) is the load-bearing decision; if a future audit decides Apalache puzzles *should* compose with Tier 2+ `concept:*` (e.g., A05 Folds composing with `concept:set-comprehension-filter` from T17 once Tier 2 is in place), this exemption can be revisited. As of this audit, the Apalache Track is taught **before** most Tier 2+ concepts in the standard curriculum order, so requiring `concept:*` priors would be impossible regardless.

## Judgment Intersticials

Audited against sharpened Gate 3 + extended Gate 7 by tla-3vt.9 (2026-05-05). All seven judgment puzzles are exempt from Gate 3 and Gate 7's prior-load and demo-bareness expectations: each J-puzzle presents two (or more) pre-written specs side by side plus a rubric for choosing between them, teaching a *meta-skill* (when to use which technique) rather than a new `concept:*` from the curriculum's taxonomy. With no new concept introduced, Gate 3's strip test has nothing to remove; with no demo + puzzle dual structure (the comparison specs are the lesson — they ship together, not as a separate worked example versus a learner exercise), Gate 7's demo-bareness and demo-puzzle-domain-disjoint clauses have no targets. The remaining gates (Concept Uniqueness — one decision per puzzle; 15-Minute — read both sides, internalize the rubric; TLC Verification — all 13 .tla/.cfg pairs PASS via `./scripts/verify-puzzle.sh`, including J05's `NoFairness` and J07's `Split` as deliberate-violation contrasts; Trace Quality — J05/J07 traces are short and instructive) apply and hold by inspection.

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| J01 | Judgment — When records vs separate variables? | (judgment — when to bundle vs scatter state) | exempt (judgment — meta-skill, not concept) |
| J02 | Judgment — PlusCal vs Pure TLA+ for X? | (judgment — sequential/process vs relational/action) | exempt (judgment — meta-skill, not concept) |
| J03 | Judgment — TLC vs Apalache for X? | (judgment — enumerative vs symbolic model checker) | exempt (judgment — meta-skill, not concept) |
| J04 | Judgment — When to Use Refinement? | (judgment — single-level vs abstract+concrete+mapping) | exempt (judgment — meta-skill, not concept) |
| J05 | Judgment — Choosing Fairness Type | (judgment — none vs WF vs SF) | exempt (judgment — meta-skill, not concept) |
| J06 | Judgment — Safety vs Liveness | (judgment — INVARIANT vs PROPERTY classification) | exempt (judgment — meta-skill, not concept) |
| J07 | Judgment — When to split a label vs combine actions? | (judgment — atomicity boundary placement) | exempt (judgment — meta-skill, not concept) |

## Final Capstone

| ID | Title | New concept | Scaffolding |
|---|---|---|---|
| T67 | Final Capstone — Distributed Counter | (capstone — composes prior) | exempt (capstone) |

---

## Cross-tier audit (tla-3vt.10, 2026-05-05)

Cross-cutting audit covering the 13 review puzzles (R01–R13), the two cross-tier capstones (C01, C02), and the Final Capstone (T67). Each row's `New concept` and `Scaffolding` cells in the per-tier tables above were filled by this pass; tier-specific T-row audits are owned by their respective tla-3vt.* siblings.

**R-series (R01–R13).** All thirteen review puzzles passed. Each one re-drills a single prior concept in a fresh domain with a worked demo whose domain differs from the puzzle's domain. The strip-test residue is the entire puzzle (since R-puzzles introduce no new concept), so Gate 3 doesn't bind in the usual sense. Gate 7's Demo Bareness clause also doesn't bind: the demo's job here is precisely to recap a prior technique in a fresh composition, mirroring the capstone exception. Demo–Puzzle Domain Disjoint (the other half of Gate 7) DOES apply and holds by inspection in every R-puzzle. R-series exemption locked in [QUALITY_GATE.md](QUALITY_GATE.md#exemptions); per-row tags read `exempt (review — refresh, not new concept)`.

**Cross-tier capstones (C01, C02) and Final Capstone (T67).** All three composes prior concepts from multiple tiers. They pass Gate 3 by construction (their job is composition) and replace Gate 7's worked demo with a fresh-domain recap — the same treatment as in-tier capstones (T08, T25, T34, etc.). T67 additionally exercises the Apalache track (`@type:` annotations + `ApaFoldSet`) so it doubles as the joint TLC + Apalache capstone. Per-row tag remains `exempt (capstone)`; the existing capstone exemption clause in [QUALITY_GATE.md](QUALITY_GATE.md#exemptions) was extended to name C01, C02, and T67 explicitly.

**Verification.** Every puzzle in scope verified green via `scripts/verify-puzzle.sh`: 17 PASS-CLEAN. No revisions were required to puzzle source. (Note: an earlier draft of this section recorded R12, C02, and T67's `DistributedCounter` as PASS-OTHER and attributed it to `CHECK_DEADLOCK FALSE` terminal stutter; that misread was actually the tla-xpv bug — `verify-puzzle.sh` was omitting INSTANCE helpers (`Counter`, `AbstractTicketing`, `AbstractCounter`) from the scratch dir, so TLC failed parse silently and fell through to PASS-OTHER. After the tla-xpv fix all three verify PASS-CLEAN.)

## Coverage Histogram

For each prior concept, the later puzzles that reuse it as scaffolding. Aggregated by the parent agent after the tla-3vt.{2-10} parallel audit pass (2026-05-05); per-tier subsections record what that tier's audit found. Tier 7 (production-craft), Apalache Track, Judgment, R-series — all whole-track exempt — contribute zero rows here by design; their scaffolding lives in `apa:*` / `workflow:*` taxonomies tracked separately.

### Tier 1 reuse (after tla-4ln, 2026-05-05)

| Prior concept | Reused as scaffolding in |
|---|---|
| concept:while (T01) | T05, T06, T07 |
| concept:variables (T01) | T04, T06 |
| concept:label (T01) | T04 |
| concept:if-pluscal (T01) | T02, T07 |
| concept:with (T02) | T03 |
| concept:either-or (T03) | T05, T06 |
| concept:eventually (T03) | T05 |

### Tier 2 reuse (after tla-3vt.2, 2026-05-05)

| Prior concept | Reused as scaffolding in |
|---|---|
| concept:define-block (T06) | T09, T11, T12, T13, T14, T15, T16, T17, T18, T19, T20, T21, T22, T23, T24 |
| concept:with (T02) | T16, T19, T20, T22, T24 |
| concept:while (T01) | T22 |
| concept:function-application (T13) | T17, T18, T23 |
| concept:function-except (T14) | T15 |
| concept:function-constructor (T12) | T16, T24 |
| concept:subseteq (T19) | T20 |

### Tier 3 reuse (after tla-3vt.3, 2026-05-05)

| Prior concept | Reused as scaffolding in |
|---|---|
| concept:plain-tla-translation (T26) | T27, T28, T29 |
| concept:init-predicate (T28) | T29, T30, T33 |
| concept:unchanged (T29) | T30, T31, T33 |
| concept:next-relation (T30) | T31 |
| concept:action-disjunction (T31) | T32, T33 |
| concept:square-bracket-action (T32) | T33 |
| concept:eventually (T03, cross-tier from Tier 1) | T32 |
| concept:deliberate-violation (T07, cross-tier from Tier 1) | T33 |

### Tier 4 reuse (after tla-3vt.4, 2026-05-05)

| Prior concept | Reused as scaffolding in |
|---|---|
| concept:while (T01) | T35, T38 |
| concept:variables (T01) | T35, T40 |
| concept:if-pluscal (T01) | T40 |
| concept:multi-label-race (T04) | T39 |
| concept:deliberate-violation (T07) | T35 |
| concept:sequence-literal (T10) | T38 |
| concept:sequence-concat (T11) | T38 |
| concept:cardinality (T20) | T39 |
| concept:next-relation (T30), concept:action-disjunction (T31), concept:square-bracket-action (T32), concept:spec-form (T33) | T37 |
| concept:distinct-processes (T35, internal) | T36, T38, T40 |
| concept:await (T36, internal) | T38, T39 |

### Tier 5 reuse (after tla-3vt.5, 2026-05-05)

| Prior concept | Reused as scaffolding in |
|---|---|
| concept:while (T01) | T42, T43, T44, T45, T46, T47 (heavy — 6 of 8 non-exempt rows) |
| concept:either-or (T03) | T42, T43, T44, T44b, T45, T46 (heavy — 6 reuses) |
| concept:if-pluscal (T01) | T43, T46, T48 |
| concept:await (T36) | T44, T44b, T45, T46, T47 |
| concept:eventually (T03) | T42 |
| concept:label (T01) | T48 |
| concept:infinitely-often (T45, internal) | T46, T48 |
| concept:leads-to (T44, internal) | T44b |

### Tier 6 reuse (after tla-3vt.6, 2026-05-05)

| Prior concept | Reused as scaffolding in |
|---|---|
| concept:constants (T50, internal) | T52, T53 |
| concept:next-relation (T30) | T51, T52, T53, T54 |
| concept:spec-form (T33) | T51, T52, T53 |
| concept:instance (T52, internal) | T54, T55, T56 |
| concept:refinement-abstract (T53, internal) | T54, T55 |
| concept:refinement-concrete (T54, internal) | T55, T56, T57, T58 |
| concept:refinement-mapping (T55, internal) | T56, T57 |
| concept:refinement-stutter (T57, internal) | T58 |
| concept:action-disjunction (T31) | T52, T55 |
| concept:unchanged (T29) | T52 |
| concept:square-bracket-action (T32) | T57 |
| concept:choose (T21) | T53 |
| concept:either-or (T03) | T50 |
| concept:while (T01), concept:variables (T01), concept:await (T36) | T50 |
| concept:deliberate-violation (T07) | T58 |

### Cross-tier observations (after the full tla-3vt.{2-10} audit pass)

- **Heaviest single-tier reuse:** Tier 2's `concept:define-block` (15 reuses across T09–T24) and Tier 5's `concept:while` + `concept:either-or` (6 reuses each across 8 non-exempt rows). Both are expected because of structural shape (Tier 2 expression-shape concepts naturally live inside `define`; Tier 5 temporal properties irreducibly need a fair process + loop + choice host).
- **Sparse Tier 1 priors that finally resurface:** `concept:label` (T01) → T04, T48 (only 2 reuses after Tier 5); `concept:eventually` (T03) → T05, T32, T42 (3 reuses, T32 is a Tier 3 cross-tier resurfacing).
- **Concepts with zero reuse to watch:** `concept:assert` (T05), `concept:multi-label-race` (T04, only T39 reuses it).
- **Cross-tier heavy hitters:** `concept:next-relation` (T30) seen heavily in Tier 4 (T37) and Tier 6 (T51–T54) — the pure-TLA+ Next idiom anchors most multi-process and refinement work. `concept:await` (T36) becomes Tier 5's most-reused Tier 4 prior (5 reuses).
- **Tier 7 / Apalache / Judgment / R-series contribute zero rows by design.** Their concepts live in `workflow:*`, `apa:*`, and meta-skill-not-concept taxonomies and are taught for direct application, not as scaffolding for later concept puzzles. Within-track reuse (e.g., A04 `apa:assign` → A05/A06/A07) is recorded inline in the per-tier table's `Scaffolding` column.

When this histogram is non-trivial, watch for:

- **Concepts with zero reuse** — taught once, never reinforced. Either fold a review puzzle in, or move the concept later so it reappears.
- **Concepts with heavy reuse in a short stretch** — e.g., `concept:either-or` scaffolding three consecutive puzzles. Choose a different prior concept for the next puzzle in that stretch.
- **Concepts whose reuse all clusters in one tier** — same problem, longer wavelength. Spread them across tiers when possible.
