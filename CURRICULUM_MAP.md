# Curriculum Map

Auto-generated from `bd list` queries. **Do not hand-edit** — regenerate via `bash scripts/gen-curriculum-map.sh`.

Each row is one puzzle bead. Status icons: ✓ closed (done) · ○ open · ◐ in progress · ● blocked · ❄ deferred.

Style: PC = PlusCal · TLA = pure TLA+. Difficulty: 1=⭐ (~15 min) · 2=⭐⭐ (~30 min) · 3=⭐⭐⭐ (~60+ min).

`Kind` legend: puzzle / review / capstone / cross-capstone / judgment.

> **Note:** Within each tier, rows are sorted alphabetically by ID. The actual
> learner sequence is encoded in the `bd` dependency graph (see `bd ready`).
> One intentional reorder: in Tier 7, **T62 (Model Values) is the dep-chain
> successor of T60 (SYMMETRY)**, since T62 deepens model-value semantics that
> T60 introduces. T61 (VIEW) follows T62 in the dep chain even though it
> appears before T62 in this table.


## Tier 0 — Prelude (Workflow Basics)

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-4pu | T0a: First Run — Hello, TLC | prelude | none | 1 | workflow:read-output,workflow:tlc-run |
| ✓ | tla-a1s | T0b: Reading a Counterexample | prelude | none | 1 | workflow:read-output,workflow:read-trace |
| ✓ | tla-rm6 | T0c: The .cfg File — Anatomy and Editing | prelude | none | 1 | workflow:cfg-anatomy,workflow:cfg-edit |
| ✓ | tla-8gm | T0d: pcal — The Translator | prelude | none | 1 | workflow:pcal-translate,workflow:read-translation |
| ✓ | tla-b0q | T0e: Anatomy of a TLA+ Module | prelude | none | 1 | workflow:module-anatomy,workflow:read-translation |

## Tier 1 — PlusCal Basics (Done)

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-5fv | T01: The Light Switch | puzzle | PC | 1 | concept:assign,concept:deliberate-violation,concept:fair-process,concept:if-pluscal,concept:invariant,concept:label,concept:typeok,concept:variables,concept:while |
| ✓ | tla-06t | T02: The Guessing Game | puzzle | PC | 1 | concept:deliberate-violation,concept:nondet-init,concept:typeok,concept:with |
| ✓ | tla-1ad | T03b: Roll Call | puzzle | PC | 1 | concept:process-set,concept:self |
| ✓ | tla-xyl | T03: The Fork in the Road | puzzle | PC | 1 | concept:either-or,concept:eventually,concept:property-eventually |
| ✓ | tla-m0b | T04: The Broken Door | puzzle | PC | 2 | concept:multi-label-race,concept:multiple-labels |
| ✓ | tla-ci3 | T05: The Toll Booth | puzzle | PC | 1 | concept:assert,concept:either-or,concept:property-eventually |
| ✓ | tla-zt6 | T06: The Scoreboard | puzzle | PC | 1 | concept:define-block,concept:either-or,concept:operator,concept:operator-params |
| ✓ | tla-0hh | T07: The Off-By-One | puzzle | PC | 2 | concept:deliberate-violation,concept:if-pluscal,concept:while |
| ✓ | tla-ua5 | T08: The Ticket Machine | capstone | PC | 2 | concept:assert,concept:define-block,concept:deliberate-violation,concept:either-or,concept:fair-process,concept:variables,concept:while,concept:with |

## Tier 2 — PlusCal Data Structures

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-zph | R01: Review — Either/Or in a New Skin | review | PC | 1 | concept:either-or,concept:fair-process,concept:variables |
| ✓ | tla-krz | R02: Review — Define Block in a New Skin | review | PC | 1 | concept:define-block,concept:operator,concept:operator-params,concept:record-dot |
| ✓ | tla-4ls | R03: Review — Process Set with self | review | PC | 1 | concept:multi-label-race,concept:process-set,concept:self |
| ✓ | tla-nh4 | T09: Records — Constructor, Dot, EXCEPT | puzzle | PC | 2 | concept:record-constructor,concept:record-dot,concept:record-except |
| ✓ | tla-6sn | T10: Sequences — Literal, Append, 1-Indexed Access | puzzle | PC | 1 | concept:function-domain,concept:sequence-append,concept:sequence-head-tail,concept:sequence-index,concept:sequence-len,concept:sequence-literal |
| ✓ | tla-7m4 | T11: Sequences — Concat and SubSeq | puzzle | PC | 1 | concept:sequence-concat,concept:sequence-len,concept:sequence-subseq |
| ✓ | tla-1b1 | T12: Functions — Constructor | puzzle | PC | 1 | concept:function-constructor,concept:function-domain |
| ✓ | tla-kri | T13: Functions — Application and DOMAIN | puzzle | PC | 1 | concept:function-application,concept:function-domain |
| ✓ | tla-6d1 | T14: Functions — EXCEPT Update | puzzle | PC | 1 | concept:function-application,concept:function-except |
| ✓ | tla-uqu | T15: Functions — EXCEPT with @ | puzzle | PC | 1 | concept:function-application,concept:function-except,concept:function-except-at |
| ✓ | tla-175 | T16: Function Sets — [S -> T] | puzzle | PC | 1 | concept:function-constructor,concept:function-set,concept:typeok |
| ✓ | tla-xw4 | T17: Set Comprehension — Filter | puzzle | PC | 1 | concept:set-comprehension-filter |
| ✓ | tla-47z | T18: Set Comprehension — Map | puzzle | PC | 1 | concept:set-comprehension-filter,concept:set-comprehension-map |
| ✓ | tla-hqe | T19: \\subseteq and SUBSET | puzzle | PC | 1 | concept:powerset,concept:subseteq |
| ✓ | tla-l44 | T20: Cardinality and FiniteSets | puzzle | PC | 1 | concept:cardinality,concept:finitesets,concept:typeok |
| ✓ | tla-2e1 | T21: CHOOSE — Picking a Witness (Beware: Deterministic) | puzzle | PC | 2 | concept:choose,concept:exists |
| ✓ | tla-h18 | T22: IF/THEN/ELSE Expressions and CASE | puzzle | PC | 1 | concept:case-expression,concept:if-expression |
| ✓ | tla-fbg | T23: LET-IN | puzzle | PC | 1 | concept:let-in |
| ✓ | tla-96q | T24: Quantifiers in Invariants | puzzle | PC | 1 | concept:exists,concept:forall |
| ✓ | tla-y8g | T25: Tier 2 Capstone | capstone | PC | 2 | concept:forall,concept:function-except,concept:function-except-at,concept:let-in,concept:record-constructor,concept:record-except,concept:sequence-append,concept:set-comprehension-filter |

## Tier 3 — Pure TLA+ Pivot

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-sr8 | R04: Review — Records via TLA+ EXCEPT | review | TLA | 1 | concept:function-except-at,concept:primed-vars,concept:record-except |
| ✓ | tla-6sl | R05: Review — Sequences in Pure TLA+ | review | TLA | 1 | concept:primed-vars,concept:sequence-append,concept:sequence-concat |
| ✓ | tla-5sn | T26: Reading a Pure TLA+ Spec | puzzle | TLA | 1 | concept:init-predicate,concept:next-relation,concept:plain-tla-translation,concept:spec-form |
| ✓ | tla-q8e | T27: The Level System — Recognize Each | puzzle | TLA | 1 | concept:level-action,concept:level-state,concept:level-temporal |
| ✓ | tla-99q | T28: Writing Init Predicates | puzzle | TLA | 1 | concept:init-predicate,concept:level-state,concept:nondet-init |
| ✓ | tla-p2t | T29: UNCHANGED for Stability | puzzle | TLA | 1 | concept:primed-vars,concept:unchanged |
| ✓ | tla-rom | T30: Writing Next as a Single Action | puzzle | TLA | 2 | concept:level-action,concept:next-relation,concept:primed-vars,concept:unchanged |
| ✓ | tla-mr7 | T31: Disjunction in Next — Multiple Actions | puzzle | TLA | 2 | concept:action-disjunction,concept:next-relation,concept:unchanged |
| ✓ | tla-bj5 | T32: Spec Form and [A]_v | puzzle | TLA | 2 | concept:spec-form,concept:square-bracket-action,concept:stuttering,concept:weak-fairness |
| ✓ | tla-oum | T33: Counter in Pure TLA+ | puzzle | TLA | 2 | concept:init-predicate,concept:invariant,concept:next-relation,concept:spec-form,concept:unchanged |
| ✓ | tla-97d | T34: Tier 3 Capstone — Pure TLA+ from Scratch | capstone | TLA | 3 | concept:action-disjunction,concept:init-predicate,concept:invariant,concept:next-relation,concept:spec-form,concept:square-bracket-action,concept:unchanged |

## Tier 4 — Multi-Process & Synchronization

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-9s3 | C01: Cross-Tier Capstone (Tiers 2-4) | cross-capstone | PC | 3 | concept:await,concept:distinct-processes,concept:function-except,concept:invariant,concept:property-eventually,concept:record-constructor |
| ✓ | tla-muu | R06: Review — Function-as-State | review | PC | 1 | concept:function-application,concept:function-except,concept:process-set |
| ✓ | tla-wqt | R07: Review — Nondeterministic Init in Pure TLA+ | review | TLA | 1 | concept:exists,concept:init-predicate,concept:nondet-init |
| ✓ | tla-t8f | T35: Distinct Processes (Asymmetric) | puzzle | PC | 2 | concept:distinct-processes,concept:label,concept:process |
| ✓ | tla-kjm | T36: await for Synchronization | puzzle | PC | 1 | concept:await,concept:distinct-processes |
| ✓ | tla-fsh | T37: ENABLED — When Can An Action Fire? | puzzle | TLA | 2 | concept:await,concept:enabled,concept:level-state |
| ✓ | tla-t05 | T38: Producer/Consumer with a Queue | puzzle | PC | 2 | concept:await,concept:producer-consumer,concept:sequence-append,concept:sequence-head-tail |
| ✓ | tla-au1 | T39: Mini-Mutex (Two-Process) | puzzle | PC | 2 | concept:await,concept:distinct-processes,concept:multi-label-race,concept:mutex |
| ✓ | tla-jyx | T40: Procedures and call/return | puzzle | PC | 2 | concept:procedure-call |
| ✓ | tla-9j0 | T41: Tier 4 Capstone — Bounded Buffer | capstone | PC | 2 | concept:await,concept:distinct-processes,concept:enabled,concept:producer-consumer,concept:sequence-append,concept:sequence-head-tail |

## Tier 5 — Temporal Logic & Fairness

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-5kc | R08: Review — Quantifiers in Properties | review | PC | 1 | concept:eventually,concept:forall,concept:function-application |
| ✓ | tla-va4 | R09: Review — Either/Or with Liveness | review | PC | 1 | concept:either-or,concept:eventually,concept:weak-fairness |
| ✓ | tla-kgk | T42: <> Eventually — Deeper | puzzle | PC | 1 | concept:eventually,concept:property-eventually |
| ✓ | tla-cqz | T43: [] Always — As Property | puzzle | PC | 1 | concept:always,concept:invariant,concept:property-eventually |
| ✓ | tla-z8b | T44b: Leads-To Failure — When ~> Doesn't Hold | puzzle | PC | 2 | concept:leads-to,concept:liveness-debug,concept:weak-fairness |
| ✓ | tla-aum | T44: ~> Leads-To | puzzle | PC | 3 | concept:always,concept:eventually,concept:leads-to |
| ✓ | tla-2xs | T45: []<> Infinitely Often | puzzle | PC | 2 | concept:always,concept:eventually,concept:infinitely-often |
| ✓ | tla-33k | T46: <>[] Eventually Always | puzzle | PC | 2 | concept:always,concept:eventually,concept:eventually-always |
| ✓ | tla-znq | T47b: Reading Lasso Traces — Stem and Cycle Anatomy | puzzle | PC | 1 | concept:lasso-trace,workflow:read-trace |
| ✓ | tla-3an | T47: Strong Fairness | puzzle | PC | 2 | concept:enabled,concept:strong-fairness,concept:weak-fairness |
| ✓ | tla-281 | T48: Liveness Debugging | puzzle | PC | 2 | concept:liveness-debug,concept:strong-fairness,concept:weak-fairness |
| ✓ | tla-ric | T49: Tier 5 Capstone — Request/Response System | capstone | PC | 3 | concept:infinitely-often,concept:leads-to,concept:liveness-debug,concept:strong-fairness |

## Tier 6 — Specification Structure & Refinement

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-76hq | C02: Cross-Tier Capstone (Tiers 4-6) | cross-capstone | TLA | 3 | concept:distinct-processes,concept:leads-to,concept:refinement-mapping,concept:refinement-stutter,concept:strong-fairness |
| ✓ | tla-y5yk | R10: Review — Pure TLA+ Init Refresh | review | TLA | 1 | concept:init-predicate,concept:level-state,concept:nondet-init |
| ✓ | tla-v1fv | R11: Review — Multi-Process Refresh | review | PC | 1 | concept:await,concept:distinct-processes,concept:process |
| ✓ | tla-ujf | T50: CONSTANTS and ASSUME | puzzle | PC | 1 | concept:assume,concept:constants |
| ✓ | tla-jqb | T51: Multi-Module Specs | puzzle | TLA | 1 | concept:constants,concept:multi-module |
| ✓ | tla-a6e9 | T52: INSTANCE for Parameterization | puzzle | TLA | 2 | concept:instance,concept:instance-with,concept:multi-module |
| ✓ | tla-ya3e | T53: Refinement — The Abstract Spec | puzzle | TLA | 2 | concept:init-predicate,concept:next-relation,concept:refinement-abstract |
| ✓ | tla-awsy | T54: Refinement — The Concrete Spec | puzzle | TLA | 2 | concept:instance-with,concept:refinement-concrete,concept:spec-form |
| ✓ | tla-nlyz | T55: Refinement — Variable Mapping | puzzle | TLA | 2 | concept:instance-with,concept:refinement-concrete,concept:refinement-mapping |
| ✓ | tla-ouoq | T56: Refinement — Auxiliary Variables | puzzle | TLA | 3 | concept:refinement-auxiliary,concept:refinement-concrete,concept:refinement-mapping |
| ✓ | tla-la42 | T57: Refinement — Stuttering Steps | puzzle | TLA | 3 | concept:refinement-mapping,concept:refinement-stutter,concept:square-bracket-action |
| ✓ | tla-67wv | T58: Refinement — Debugging a Failed Refinement | puzzle | TLA | 3 | concept:refinement-auxiliary,concept:refinement-debug,concept:refinement-mapping,concept:refinement-stutter |
| ✓ | tla-rrqt | T59: Tier 6 Capstone — Two-Level Refinement | capstone | TLA | 3 | concept:instance-with,concept:refinement-abstract,concept:refinement-auxiliary,concept:refinement-concrete,concept:refinement-mapping,concept:refinement-stutter |

## Tier 7 — Production Craft

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-ql5b | R12: Review — Refinement Quick Refresh | review | TLA | 1 | concept:instance-with,concept:refinement-mapping,concept:spec-form |
| ✓ | tla-8wz5 | R13: Review — Boundary Values | review | PC | 1 | concept:boundary-values,concept:typeok |
| ✓ | tla-itd6 | T60: SYMMETRY for State-Space Reduction | puzzle | TLA | 2 | concept:model-value,concept:symmetry |
| ✓ | tla-0dmy | T61: VIEW for Equivalence Classes | puzzle | TLA | 2 | concept:symmetry,concept:view |
| ✓ | tla-a7lp | T62: Model Values vs Concrete Values | puzzle | TLA | 2 | concept:model-value,concept:symmetry |
| ✓ | tla-07sz | T63: -coverage for Spec Hygiene | puzzle | PC | 1 | concept:coverage |
| ✓ | tla-tk2x | T64: -simulate Mode | puzzle | PC | 1 | concept:coverage,concept:simulate |
| ✓ | tla-z9co | T65: -difftrace and Debugging Workflow | puzzle | PC | 1 | concept:difftrace,concept:liveness-debug |
| ✓ | tla-xtg8 | T66: Tier 7 Capstone — Production-Ready Spec | capstone | TLA | 3 | concept:boundary-values,concept:coverage,concept:model-value,concept:symmetry,concept:view |

## Apalache Track (parallel after Tier 3)

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-417k | A01: Apalache — Hello, Snowcat | puzzle | TLA | 1 | apa:type-base |
| ✓ | tla-7ygr | A02: Apalache — Composite Types | puzzle | TLA | 1 | apa:type-base,apa:type-composite |
| ✓ | tla-0zhk | A03: Apalache — Type Aliases | puzzle | TLA | 1 | apa:type-alias,apa:type-composite |
| ✓ | tla-wcgu | A04: Apalache — := for Explicit Assignment | puzzle | TLA | 1 | apa:assign,apa:type-base |
| ✓ | tla-jog7 | A05: Apalache — Folds (ApaFoldSet) | puzzle | TLA | 2 | apa:assign,apa:fold |
| ✓ | tla-sixl | A06: Apalache — Terminal Stutter | puzzle | TLA | 1 | apa:assign,apa:terminal-stutter |
| ✓ | tla-5n4x | A07: Apalache — --cinit for Constants | puzzle | TLA | 2 | apa:cinit,apa:type-base |
| ✓ | tla-7qij | A08: Apalache — TLC vs Apalache Comparison | puzzle | TLA | 2 | apa:type-base,apa:vs-tlc |
| ✓ | tla-qszc | A09: Apalache Capstone — Full Type-Annotated Spec | capstone | TLA | 3 | apa:assign,apa:fold,apa:terminal-stutter,apa:type-alias,apa:type-base,apa:type-composite |
| ✓ | tla-9ju | A10: TLC + Apalache Joint Capstone | capstone | TLA | 2 | apa:type-base,apa:vs-tlc |

## Judgment Intersticials

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-dkk | J01: Judgment — When records vs separate variables? | judgment |  | 1 | concept:record-constructor,concept:record-dot |
| ✓ | tla-3f8 | J02: Judgment — PlusCal vs Pure TLA+ for X? | judgment |  | 1 | concept:judgment-pluscal-vs-tla |
| ✓ | tla-hu8n | J03: Judgment — TLC vs Apalache for X? | judgment |  | 2 | apa:vs-tlc |
| ✓ | tla-e21j | J04: Judgment — When to Use Refinement? | judgment |  | 2 | concept:refinement-abstract,concept:refinement-concrete |
| ✓ | tla-c96 | J05: Judgment — Choosing Fairness Type | judgment |  | 2 | concept:liveness-debug,concept:strong-fairness,concept:weak-fairness |
| ✓ | tla-905 | J06: Judgment — Safety vs Liveness | judgment |  | 1 | concept:eventually,concept:invariant,concept:safety-vs-liveness |
| ✓ | tla-ug9 | J07: Judgment — When to split a label vs combine actions? | judgment |  | 2 | concept:label,concept:multi-label-race,concept:multiple-labels |

## Final Capstone

| Status | ID | Title | Kind | Style | Diff | Concepts |
|---|---|---|---|---|---|---|
| ✓ | tla-77oy | T67: Final Capstone — Distributed Counter | capstone | TLA | 3 | apa:fold,apa:type-base,concept:await,concept:distinct-processes,concept:instance-with,concept:leads-to,concept:refinement-mapping,concept:strong-fairness |

---

## Concept-Decay Query Examples

```bash
bd list -l concept:either-or --status closed --json | jq -r '.[].closed_at' | sort | tail -1   # Last time either/or was drilled
bd list -l concept:function-application --status all                                            # All puzzles touching function application
bd list --status open --label tier:2 --label kind:puzzle                                        # Tier 2 puzzles still to write
bd ready --label tier:2                                                                         # Next unblocked Tier 2 work
```

## Workflow

1. **Author next puzzle:** `bd ready` → pick the lowest-tier unblocked puzzle. `bd show <id>` for context.
2. **Mark in progress:** `bd update <id> --status in_progress`.
3. **Write puzzle directory:** `puzzles/T0N-the-x/{README.md, solution/Name.tla, solution/Name.cfg}`.
4. **Verify:** `pcal Name.tla && java tlc2.TLC Name.tla` (or whatever the local TLC invocation is).
5. **Close:** `bd close <id> --reason "Authored, verified by TLC"`.
6. **Regenerate this map:** `bash scripts/gen-curriculum-map.sh`.
7. **At session end:** `bd sync`.

## Spaced-Repetition Selection

When picking the next review puzzle (`R0N`), use:

```bash
# Find the concept tag whose closed beads have the oldest most-recent close date
bd list --status closed --label kind:puzzle --json | \
  jq -r '.[] | .labels[] as $l | select($l | startswith("concept:")) | "\(.closed_at) \($l)"' | \
  sort | head -20
```

The concept that hasn't been touched longest is the next review's target.
