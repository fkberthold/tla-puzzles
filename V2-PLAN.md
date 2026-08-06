# V2 Rebuild — Execution Plan

**Status:** handoff document, written 2026-08-06. Tracked by bead **`tla-qpm`**.
**Audience:** the next session, which will have none of the originating context.

---

## 0. How to use this document

Read §1 and §3 before doing anything. §3 is a list of decisions that are *closed*; reopening
them wastes a session and usually re-derives a worse answer, because most were settled against
measured evidence rather than intuition.

Six stages, ordered by dependency: **Stage 1** refinement chapter (§4) · **Stage 2** harness
(§5) · **Stage 3** pilot problem (§6) · **Stage 4** tutor directory (§6b) · **Stage 5** batched
production (§7) · **Stage 6** assembly (§8). Stages 1 and 2 are parallel; everything else is
sequential. Within each stage the work decomposes into units meant to be **dispatched to
subagents**, with copy-pasteable briefs in §9.

**The production model is BATCHED, not one big fan-out.** Frank works through each batch
before the next is authored, so real learner telemetry informs the remaining problems. See
§7 — this is a change from the original plan and it reshapes everything downstream of the
pilot.

**Why subagents specifically.** Isolation is load-bearing, not just parallelism:

- A **blind solver** is only a valid instrument if it genuinely has not seen the reference
  solution. A fresh agent with a minimal brief guarantees that; a same-context continuation
  cannot.
- The **comment pass** must not be able to reshape the spec it is annotating. Giving an
  isolated agent the frozen spec and a comments-only mandate enforces this structurally.
- The **leakage check** must be adversarial against a statement its author is attached to.

Treat "spawn a fresh agent" as the enforcement mechanism for these gates, and never shortcut
one by doing the work inline.

---

## 1. Orientation — read these first

**Three decision drawers** in the `tla_puzzles` MemPalace wing, room `decisions`:

| Drawer | Contents |
|---|---|
| `drawer_tla_puzzles_decisions_78e0afcd8f0f7bb925f61ef0` | v1 post-mortem — why the microlesson curriculum failed structurally |
| `drawer_tla_puzzles_decisions_d6fc1f6386188c44b58278b8` | v2 problem-set contract, production pipeline, exclusion regime |
| `drawer_tla_puzzles_decisions_be8cc4b03efbea276e444a12` | v2 mechanical grading architecture + TLC harness constraints |

Retrieve with `mempalace_get_drawer`, or search `tla_puzzles/decisions`. There are also **35
`provenance:mined` drawers** filed 2026-08-05 covering v1's design rationale as recovered from
git history — search by the `provenance:mined` tag.

**The implementation epic is `tla-kl5`** — 22 children, filed 2026-08-06 from this document.
Every child cites the section it implements, so the mapping is one hop in either direction:

| Stage | § | Beads |
|---|---|---|
| 1 — refinement chapter | §4 | `tla-kl5.1` author · `tla-kl5.2` verify |
| 2 — harness | §5 | `tla-kl5.3` TLAiBench survey · `.4` verdict channel · `.5` grading · `.6` vacuity · `.7` refinement · `.8` seeded bugs · `.9` comment gate · `.10` screens |
| 3 — pilot | §6 | `tla-kl5.11` |
| 4 — tutor directory | §6b | `tla-kl5.12` isolation · `.13` tutor · `.14` grader · `.15` logging |
| 5 — batched production | §7 | `tla-kl5.16` batch 1 · `.17` holdout set |
| 6 — assembly | §8 | `tla-kl5.18` coverage audit · `.19` ordering · `.20` J01–J07 rewrite · `.21` final screen |
| — | §11 | `tla-kl5.22` open research gaps |

Ready to start now, in parallel: `tla-kl5.1`, `.3`, `.4`, `.9`, `.10`. Everything else is
dependency-blocked in the order above. Stages 5 and 6 are filed **coarse on purpose** — batch 1's
telemetry is expected to reshape them (§7.1), so they get decomposed when the pilot lands.

**Other open beads:**

- `tla-qpm` (P1) — this plan; `tla-kl5` is the epic it called for
- `tla-syn` (P2) — `verify-puzzle.sh` should branch on `$?`, not stdout greps; must pin `-workers 1`.
  Now depends on `tla-kl5.4`, which owns the canonical rc table — rewire, don't reimplement
- `tla-5b4` (P2) — CI downloads `tla2tools.jar` from `latest`; pin the release
- `tla-xme` (P2) — wire the 8 scaffolded `scripts/` stubs, or mark N/A
- `tla-nov` (P3) — review the 35 mined drawers; 6 have bodies truncated at a backslash
- `tla-9ic` (P3) — `bd preflight` runs Go-hardcoded checks here; misleading
- `tla-9h1` (P2, epic) — the pangram-set notation-fluency appendix. **Not superseded by v2**, but
  it carries an unresolved tension with §3.1 (a "pangram" is coverage-as-generator by definition).
  Its own notes say to settle that consciously before resuming, rather than letting the two
  documents quietly disagree.

**The goal, in Frank's words:** *"get good at thinking in TLA, the way it's meant to be used"* —
ending able to write entirely in TLA+.

---

## 2. Decisions — settled and outstanding

### 2.1 The taxonomy — SETTLED 2026-08-06

The problem set is a **two-axis grid**. Conflating the axes into a flat list is what produces a
tier structure by accident, which is what v1 did.

**Axis 1 — the situation** (what kind of system is being modeled):

| # | Situation | Note |
|---|---|---|
| S1 | Shared mutable state under concurrency | most classic instances are burned; re-skin structurally, not nominally |
| S2 | Resource allocation and contention | |
| S3 | Unreliable messaging — loss, duplication, reordering **as a modeling choice** | |
| S4 | **Time, expiry, and leases** | gap #6 — unserved anywhere |
| S5 | Lifecycle state machines — orders, claims, approvals | |
| S6 | Data consistency under concurrent mutation — lost update, versioning | |
| S7 | **Version coexistence and migration** | gap #7 — entire public corpus is one blog post |
| S8 | **Human-process and UI flows** | gap #13 |
| S9 | Business rules with **no concurrency at all** | pure invariants over entities |

**Axis 2 — the task shape** (what the learner is asked to do):

| | Shape | Note |
|---|---|---|
| A | Model from prose | the backbone |
| B | Write the **property**, given a spec | ships with one satisfying + one violating trace |
| C | **Critique — "what does this spec fail to say?"** | gap #11; format exists nowhere in TLA+ pedagogy |
| D | Diagnose — given a failing trace, or a **vacuous pass** | nothing public covers vacuous passes |
| E | Most-permissive correct design | no memorizable canonical answer |
| F | Small-scale refinement | everything extant is Paxos-sized |

**A problem is a CELL.** Three consequences, all load-bearing:

- **Interleaving falls out mechanically.** Walk the grid **diagonally**; you then never get two
  consecutive problems sharing either a situation or a task shape. This turns §3.4 from a
  judgment call into a checkable ordering rule.
- **Coverage-as-audit becomes natural** — audit which *cells* are filled, not which constructs
  are hit. This is what keeps §3.1 honest.
- **Gap #1 (choosing the abstraction) stops being a corner case.** If statements follow §3.2 and
  §3.3, every column-A problem *is* an abstraction-choice problem. The highest-value gap is
  served by the bulk of the set rather than by a few specials.

**Allocation, 60 total:** A 18 (two per situation) · B 8 · C 8 · D 8 · E 6 · F 8 · **+4 reserved
for the closing coverage audit (§8)**.

**Pure TLA+ ~25:** column F is inherently pure TLA+ (8); back-load ~17 more across A/B/D in the
final third, concentrated rather than sprinkled.

### 2.2 Domain list — SETTLED 2026-08-06 (all 17 in play, none approved)

Problems must sit in domains Frank does **not** already have a schema for (§3.10). He works in
industrial IoT / facility management (CrossnoKaye Atlas: facility status, control state,
alarms, sensors, refrigeration, HVAC, energy). **Those domains are disqualified for judgment
problems.**

Frank's verdict on the 17 candidates: *"I don't think it would be safe to say I can think
cleanly enough in any of them to model them. I'd call them all in."* So none are struck — but
**"in play" is not "approved."** Every one must still pass **both** screens — §5.7 (mechanism
collision) and §5.7b (puzzle-versus-system) — and several are expected to fail one or the other
(see the suspicion table below).

library hold queues · restaurant seating with party sizes and table combining · clinical trial
cohort assignment · tournament brackets with byes and forfeits · airline standby and upgrade
lists · museum exhibit loans with conservation limits · ski pass validation with blackout dates
· shared-custody calendars with holiday overrides · community garden plot allocation · blood
bank inventory with type compatibility and expiry · apprenticeship hour logging with
per-category minimums · seed library checkout with return obligations · change-ringing method
rules · orchestra audition rounds · beekeeping hive splits · escape room booking with reset
time · municipal permit review with parallel department sign-offs

**Pre-screen suspicions — record these so §5.7 is not run blind:**

| Domain | Suspected problem |
|---|---|
| restaurant seating with table combining | bin-packing / knapsack — 56 public `Knapsack` specs |
| library hold queues · community garden plots · airline standby | the `Resource Allocator` spec in different dress |
| orchestra audition rounds | tournament ranking — same mechanism as brackets, so at most one of the two survives |
| change-ringing method rules | **fails the §5.7b puzzle screen, not the §5.7 collision screen.** The rules (permutation, adjacent-swap only, no repeats, start and end on rounds) are the complete action set, stated in the domain's own terms before you write a line. Also does not scale: a full extent on 7 bells is 5,040 rows, on 8 it is 40,320, and explicit history puts a subset of rows in the state. **Rescuable** by the §5.7b agents-and-fallibility pattern (a band of ringers who mistime, refining the method) — but do not put that in batch one |
| beekeeping hive splits | rules may be too biologically fuzzy to state crisply enough for §3.2 |

**Three caveats:**

1. **Unfamiliarity is the design goal, not a handicap.** The statement *gives* the domain rules;
   what it withholds is the representation. Frank not knowing blood-bank compatibility costs
   nothing — that is the point of §3.10.
2. **But unfamiliar domains raise the bar on statements, and create a confound.** Frank cannot
   repair an ambiguity from experience, so the system description must be genuinely
   self-contained. And difficulty can migrate from *modeling* to *understanding the rules*
   without being visible from outside: a blind-solve round where all three fail reads as
   "underspecified" (§6), and you would go rewrite a statement that was fine.
   **Therefore the tutor log (§6b.4) MUST distinguish a domain impasse from a modeling impasse.**
   This is load-bearing for §7.1 — domain-opacity is *broken* and gets fixed; modeling
   difficulty is *hard* and gets left alone. Without the distinction the refinement policy
   cannot be applied.
3. **Situations S7 and S8 break the domain-novelty rule and cannot be fixed.** Migration and UI
   flows are inherently software-shaped, and Frank knows software. The mitigation is that the
   *situation* is still novel to him — he has presumably never formally specified a schema
   migration or a double-submit — but those ~10 problems are weaker instruments for measuring
   modeling ability even though they remain valuable to work through. Do not site the
   **holdout set** (§7.2) in S7 or S8.

**Reuse across cells is a feature.** 17 domains over 60 problems means each recurs ~3–4 times.
Same domain under a different situation or task shape is exactly the "criss-crossing the
conceptual landscape" the ill-structured-domain literature recommends, and it amortizes whatever
domain-learning cost each one carries.

### 2.3 Refinement chapter scope — SETTLED 2026-08-06

Approved, with Frank's framing as the thesis: **refinement is what makes it reasonable to model
large and complex systems** (§4.1). Remaining open detail is only length, and whether it ships
as one document or as chapter + worked example.

### 2.4 Repo layout — SETTLED 2026-08-06

`harness/` and `chapter/` are **new top-level directories in this repo**. v1's `puzzles/` and
`scripts/` are left untouched — v2 replaces the content, not the infrastructure, and there is no
reason to disturb a working docs build to make room for it.

```
tla-puzzles/
├── harness/     verdict.sh · grade.sh · Gate.tla · vacuity.sh · refinement.sh
│                seeded-bugs.sh · comment-gate.sh · screen.sh · PUZZLE-SCREEN.md
├── chapter/     refinement.md + snippets/
├── pilot/       the one Stage-3 problem
├── puzzles/     v1, untouched
└── scripts/     build/docs, untouched
```

`tla-practice/` and `tla-answers/` are **separate repos** created at Stage 4 (§6b.2). That
separation is a leak defense, not a preference — see §6b.1 — so it does not get "simplified" into
two directories of this repo later.

---

## 3. Invariants — do not relitigate

Each of these was settled against evidence. The evidence is in the drawers; the one-line
reasons are here so you can recognize a re-derivation attempt.

**3.1 Coverage is an end-of-run AUDIT, never the problem-list generator.**
Organizing by construct produces problems whose purpose is "this one exercises `CHOOSE`,"
which is contrived by construction and is how v1 failed one level up.

**3.2 The statement fixes the SYSTEM and leaves the REPRESENTATION open.**
"Three philosophers, two forks, must hold both to eat" — fully specified as a system, free as a
model. "Model `forks` as a function from fork-id to philosopher-or-null" has crossed the line.

**3.3 The statement names an OBSERVATION OPERATOR, not a variable vocabulary.**
The learner supplies e.g. `Observe == [balance |-> ..., pending |-> ...]`; grading keys off
`Observe`, never raw state. This is what resolves the otherwise-fatal conflict between "never
name the variables" and seeded-bug grading, which needs a fixed interface.

**3.4 Interleave by idiom. Never consecutive problems of one kind.**
Preregistered cluster RCT, 54 classes, d=0.83 (61% vs 38%). Mechanism: *"interleaved practice
requires students to choose a strategy and not merely execute a strategy."*

**3.5 Reference-comparison grading is invalid.**
Over ~96,000 Alloy submissions, the instructor's oracle ranks #1 among correct forms for only
**33%** of exercises and is **absent entirely in 18.6%**. Use conjunct-wise two-sided
implication + non-vacuity instead (§5.2).

**3.6 Mechanical layer decides pass/fail; LLM judge explains only and can never override.**
TLC is sound; an LLM is not.

**3.7 Feedback is error LOCATION, not prose and not a prettified trace.**
The only RCT on the question: location hints 9.12 tasks vs 5.67 control; counterexample hints
**statistically indistinguishable from no hint**; natural-language description hints *below*
control and the most demoralizing arm. Nothing improved retention.

**3.8 Comments are added in a separate post-freeze pass, enforced by strip-and-diff.**
Comments written alongside a spec bend the spec toward the commentary.

**3.9 Every property ships with one satisfying and one violating trace.**
Multiple *positive* instances had no measured effect; *negative* instances did.

**3.10 Problems go in domains the learner does not already know.**
A designer holding a matching prior schema behaves ~3× more top-down and you learn nothing
about their modeling ability.

---

## 3b. The learner path — reading and practice order

Settled with Frank 2026-08-06. His instinct was to read learntla core up to but not including
the TLA+ chapter, then work PlusCal problems. That is right, with one correction.

1. **Read learntla core ch.1–11.** Do not skip ch.10 (More Operators) or ch.11 (Action
   Properties) — action properties are load-bearing for the grading harness.
2. **Work batch 1** (§7.2) — PlusCal.
3. **Read core ch.12 (TLA+) and ch.13 (Modules), then the refinement chapter (§4).**
4. **Everything after that interleaves both notations**, with the pure-TLA+-only problems
   concentrated in the final third.

**Why not all PlusCal first, then all TLA+.** That is blocked practice at the coarsest grain
(§3.4), and it means hitting ~25 consecutive problems in an unfamiliar notation months after
last reading the material.

**Why stopping before ch.12 is right, though.** learntla teaches pure TLA+ *to reading depth,
as a bridge from PlusCal* — the chapter is framed as "here's what the translator produced and
what it means." Arriving there with real PlusCal fluency means it lands as *"oh, that's what my
code becomes,"* which is the best available entry point. Reading it cold would waste it.

---

## 4. Stage 1 — The refinement chapter

**Dependency:** none. Start immediately, in parallel with Stage 2.
**Dispatch:** 1 author agent + 1 verifier agent. See briefs §9.1 and §9.2.

### 4.1 Thesis (Frank's, and it is well supported)

Refinement is the technique that makes modeling large and complex systems tractable — not a
formalism to be admired. Supporting evidence to use in the chapter:

- Lamport & Merz, *Prophecy Made Simple* §5: rather than adding prophecy variables to Afek's
  snapshot algorithm, they **invent an intermediate spec** so one link needs only history
  variables and the other needs prophecy on a *simple* spec. Their justification: *"the
  specification of what an algorithm is supposed to do is generally much simpler than the
  algorithm."*
- `ewd998/EWD998ChanID.cfg` chains three instance hops (`EWD998Chan!EWD998!TD!Live`) —
  transitivity as practiced.
- Properties proved of the abstract transfer to the concrete for free.

**Honest counterweight to include:** Lamport (SS §10.9) says that when writing from scratch, a
monolithic spec is usually easier to understand. The chapter must say refinement earns its keep
when the system exceeds what you can hold in one spec — not that it is always better.

### 4.2 What learntla already covers (do not re-teach)

Core ch.13 (Modules) already teaches `INSTANCE`, `INSTANCE ... WITH`, constant and variable
substitution, `EXTENDS` vs `INSTANCE`, and partial parameterization. Core ch.12 teaches `vars`,
`Init`, `Next`, actions, primed variables, `UNCHANGED`, `Spec == Init /\ [][Next]_vars`,
stuttering via `[A]_v`, `ENABLED`, and formal `WF`/`SF` — but **to reading depth, as a bridge
from PlusCal**.

**The gap is narrow:** the *idea* that a concrete spec implements an abstract one, refinement
mappings, and the `Spec => Abstract!Spec` check. `learntla topics/refinement` is a **stub** —
the topics index says outright *"Most of the topics haven't been written yet."*

### 4.3 Cut list — dense notation, easy idea

- `\EE` / `∃∃`. Lamport calls it the stone in the soup; neither TLC nor TLAPS handles it.
  Present once for meaning, never for use.
- The `LM!Inner(omem, octl, obuf)!ISpec` chains from SS §5.8 — pure module bookkeeping.
- The overbar `F̄`. It means "substitute." Say "substitute."
- Parametrized instantiation `Inner(q) == INSTANCE InnerFIFO`. Lamport himself: *"If this seems
  confusing, don't worry about it."*
- `Prophecy.tla`'s general machinery (`ProphAction`, `ProphCondition`, `DomInj`, `PredDom`).
  Use PMS §4.2's three-line recipe instead.
- Abadi & Lamport's `Σ, F, N, L` tuples and structured proofs — 1988 completeness scaffolding.

### 4.4 Slow-down list — genuinely hard

1. **Stuttering as constitutive, not permissive.** A spec describes *part* of a world; that
   alone forces `[...]_vars`. Refinement then gets stuttering for free.
2. **The vacuity hole — make this the CENTREPIECE of the stuttering section, not a footnote.**
   `[][ANext]_(mapped)` unfolds to `ANext \/ UNCHANGED(mapped)`. A frozen mapping makes the
   right disjunct true at every step, so `ANext` is never evaluated once. Verified: a concrete
   spec with three interleaving actions and 27 distinct states passes at rc=0.
   **Stuttering is both the load-bearing beam and the trapdoor.**
3. **The `vars`-substitution consequence.** The abstract's stuttering subscript is itself
   rewritten by the mapping, determining which concrete steps are invisible. Almost never stated.
4. **Why refinement mappings can fail to exist** — Abadi & Lamport's three counterexamples.
5. **Prophecy variables.** Unlock: PMS §4.3 — *"a specification is not a rule for generating
   behaviors. It's a predicate on behaviors."* Get that sentence in early.
6. **The non-constraining obligation** — an equivalence, not an implication. History variables
   get it free (syntactic); prophecy variables must earn it.
7. **`ENABLED` not distributing over substitution**, which is what makes liveness refinement hard.
8. **Machine closure**, and prophecy's interaction with it.
9. **"Refinement is a claim about three things, not two."** From *Hiding* §5: for **any** two
   specs, adding suitable auxiliary variables makes a mapping exist. So *"X refines Y"* is a
   fact about X, Y, **and the mapping**. **Put this near the beginning, not the last page.**

### 4.5 Hard requirements on the chapter

- **Every TLA+ snippet must be executed before it ships.** Non-negotiable. A published-paper
  typo was already found this way: *Hiding* Fig 8 prints `qPbar == IF s = 0 THEN <<>> ELSE
  End(seq)` — there is no `seq` in scope; it must be `End(queue)`.
- **Do not quote from WebFetch.** WebFetch runs a summarizer and returns paraphrase, not bytes.
  Quote from a clone or from your own runs.
- Use the `Refines == Abstract!Spec` + `PROPERTY Refines` idiom — 18 of 20 real configs in
  `tlaplus/Examples` do.
- Teach `MCIProp == [][V!Next]_<<vars>>` as the debugging rung below full refinement, and
  `Inv!N` for conjunct localization (verified: TLC reports `Error: Invariant Inv2 is violated.`).
- Teach the `ALIAS` trick for reading refinement failures.

---

## 5. Stage 2 — The harness

**Dependency:** none. Parallel with Stage 1.
**Dispatch:** ~5 agents, one per component. Components are independent. Briefs in §9.3.

Everything below was **empirically verified** on TLC 2026.03.04 / tla2tools 1.8.0 and
Apalache 0.57.0. Do not re-derive; do re-verify if you change TLC versions.

### 5.1 Component: verdict channel

Replace stdout greps with exit codes throughout:

| rc | meaning |
|---|---|
| 0 | success |
| 10 | `ASSUME` or `-postCondition` false |
| 11 | deadlock |
| 12 | safety violation (`INVARIANT`) |
| 13 | liveness / action-property violation (`PROPERTY`, incl. refinement) |
| 150 | parse / semantic failure — **including a missing `.tla` module** |
| 151 | config failure (*semantic*: the `.cfg` parsed but names something the spec lacks) |
| 255 | TLC's generic unexpected-exception catch-all — a missing `.cfg`, a malformed `.cfg` |

**Corrected 2026-08-06 while building `tla-kl5.4`.** The row for 255 previously read "file not
found", which was wrong twice over. A missing **module** is 150, not 255 (`Fatal errors while
parsing TLA+ spec in file NoSuchModule`); only a missing **config** reaches 255 — and so does a
`.cfg` full of garbage tokens, via the same `ConfigFileException` path. So 255 is not about files
at all. Name the verdict token for the catch-all, never for missing files: a token called
`FILE_NOT_FOUND` would have the tutor tell a learner with a typo'd `.cfg` that their file is
missing. Verified on TLC 2026.03.04.183147.

Canonical invocation:

```bash
tlc -workers 1 -deadlock -noGenerateSpecTE -nowarning \
    -coverage 1 -dumpTrace json trace.json \
    -postCondition "Gate!NonVacuous" \
    -metadir "$SCRATCH/states" Harness.tla -config Harness.cfg
```

Wrap in `timeout`; treat rc=124 as its own verdict. **`-workers 1` is mandatory** —
counterexamples are nondeterministic above one worker (five runs at `-workers 8` gave three
different traces). State *counts* are stable and safe to publish (measured identical across
workers 1/4/8, three fingerprint polynomials, and TLC 2.15 → 2026.03.04).

### 5.2 Component: grading engine

Conjunct-wise two-sided implication plus non-vacuity. Given student Ψ and reference Φ:

1. `Ψ => φᵢ` for each **reference** conjunct → not too weak *(per-conjunct partial credit)*
2. `Φ => ψⱼ` for each **student** conjunct → not too strong
3. `Ψ => false` must **FAIL** → not vacuous

Report over-constraint and under-constraint **independently, and allow BOTH** — 23.6% of wrong
models are both simultaneously. Emit one witness of each.

Include a **`Relational` suite** that rejects specs which are *too strict*. Over-constraining
is the sin that reference-comparison grading actively teaches, and it dominates in the measured
data.

### 5.3 Component: vacuity probes

The trap: unsatisfiable `Init` yields `No error has been found`, `0 states generated`, **rc=0**.
**Deadlock checking does NOT catch it.**

- **Cheap smoke test:** `tlc -inv "FALSE" Learner.tla`. rc=12 → reachable states exist (GOOD);
  rc=0 → space is EMPTY (VACUOUS). No file edits; evaluates in the learner's namespace. The
  injected invariant is auto-named `__DebuggerExpr__<nanotime>` — never pattern-match the name.
- **Real gate:** `-postCondition "Gate!NonVacuous"` with `TLCGet("distinct") >= N`.
  **Must live in a separate module** or you get `Circular dependency among .tla files`.
  Verified to fire correctly even at 0 initial states.

```tla
---- MODULE Gate ----
EXTENDS Naturals, TLC
NonVacuous == TLCGet("distinct") >= 4
====
```

- **The check that was never configured — a SECOND vacuity vector, found 2026-08-06.** A `.cfg`
  keyword with no operand is not an error. Given `SPECIFICATION Spec` + a bare `INVARIANT` line,
  TLC reports `Model checking completed. No error has been found.` at **rc=0**, having checked no
  invariant whatsoever. **The gate above does not catch this**: the state space is perfectly
  healthy (3 distinct states in the reproduction), so `TLCGet("distinct") >= N` passes. It is not
  the state space that is empty — it is the *checking*.

  The mechanical guard, verified on TLC 2026.03.04.183147 (rc=10 on the dangling keyword, rc=0 on
  a real invariant):

  ```tla
  InvariantConfigured == TLCGet("spec").invariants # {}
  ```

  This generalizes. TLAiBench guards the same failure one field over — `impliedinits` /
  `impliedactions` for "the `.cfg` never declared the refinement `PROPERTY`" (§5.4). Treat
  **"the check was actually configured"** as a guard *family* over `TLCGet("spec")`, and run the
  relevant member alongside `NonVacuous` on every problem. The two catch disjoint failures: an
  empty state space, versus an empty obligation over a healthy one.

- **Dead-action detection** via `-coverage 1`: the predicate is **`total == 0`, NEVER
  `distinct == 0`.** An action can fire and discover nothing new; PlusCal's generated
  `Terminating` shows `0:1` on *every* terminating spec (verified on the real
  `puzzles/T01-the-light-switch` solution). Indented sub-counts localize where an action died,
  enabling "your guard `x > 100` is never true" rather than "unreachable."

### 5.4 Component: refinement checking

Idiom: define `Refines == Abstract!Spec` in the module; `.cfg` gets `SPECIFICATION Spec`
(concrete) + `PROPERTY Refines`. **`.cfg` accepts only bare identifiers** — `PROPERTY A!Spec`
fails with a misleading message about `A`.

**The probe (mandatory on every refinement problem).** Name the mapped expression, assert as an
ordinary invariant that it never leaves its initial value, and require TLC to **violate** it:

```
SPECIFICATION Spec
PROPERTY  Refines
INVARIANT Probe        \* MappedExpr = <initial value>
```

**A passing probe is a failing refinement check.** If TLC cannot violate `Probe`, the mapping
is frozen and the refinement proved nothing.

**The probe is vindicated, and the wording above is if anything too mild** (survey `tla-kl5.3`,
2026-08-06). TLAiBench — the only public TLA+ benchmark that grades refinement — has this
trapdoor wide open. A completely frozen mapping (`WITH big <- 0, small <- 0`) passes both its
plain refinement check *and* its `Gold!Refinement` postcondition at rc=0, while our `INVARIANT
Probe` cleanly separates frozen (rc=0 → fail) from correct (rc=12 → pass). Its `Gold!Stats`
postcondition discriminates nothing about the mapping — it rejects correct and frozen mappings
alike, on an unrelated diameter mismatch.

**Steal TLAiBench's configuration guard, though** — it closes a hole we did not name. It catches
a `.cfg` that never declared the refinement `PROPERTY` at all, which otherwise exits 0 silently:

```tla
\* Adapted from tlaplus/TLAiBench, gold/DieHardGold.tla (MIT, (c) 2025 TLA+ Foundation).
RefinementConfigured ==
    /\ TLCGet("spec").impliedinits   # {}
    /\ TLCGet("spec").impliedactions # {}
```

Run it **alongside** the probe, never instead of it — they catch disjoint failures. No `PROPERTY`
in the cfg: guard fires, probe silent. `PROPERTY` present but mapping frozen: guard silent, probe
fires. This is the §5.3 "check was actually configured" family applied to refinement.

**Do not copy TLAiBench's config ownership.** It lets the subject under evaluation author its own
`.cfg` — which is *how* the trapdoor stays open. Our `.cfg` stays harness-owned.

**Grading consequence of Lamport's caveat (§4.4 item 9): WE supply the mapping and grade only
the concrete spec.** Where the mapping is itself the exercise, grade by probe + inspection,
never by TLC's verdict alone.

Other verified traps: omitting `WITH` is silent (implicit same-name substitution → a different,
usually wrong mapping that passes); the abstract's `vars` tuple is substituted too.

### 5.5 Component: seeded-bug matrix

"This spec catches this bug" is exactly `rc == 12` against the variant and `rc == 0` against the
reference. This is the **only** mechanical defense against `Inv == TRUE`.

**Caveat to record in the code, not just here:** only ~10.9% of real faulty student specs are
one mutation away from correct (mistakes are multi-step), and 39.3% of single mutations are
semantically inert. Mutants of our reference are systematically unlike real learner errors.
A bootstrap, not a proxy.

Diff counterexamples via `ALIAS` + `-dumpTrace json`: normalize state *before* dumping, and
diff the **action-name sequence plus trace length**, which are stable. Concrete values vary
with representation and must not be diffed.

### 5.6 Component: comment-pass gate

Strip comments from the frozen and commented versions, diff, require identical.

**Wrinkle that breaks the naive implementation:** in PlusCal specs the algorithm lives inside
`(* --algorithm ... *)`. A naive comment stripper deletes the spec. The stripper must preserve
the block containing `--algorithm` / `--fair algorithm` and the `\* BEGIN/END TRANSLATION`
markers.

**Cleaner gate for PlusCal:** re-run `pcal` after commenting and require the TRANSLATION block
byte-identical. Comments inside the algorithm block are not carried into the generated TLA+, so
any change means the pass touched the algorithm.

### 5.7 Component: screening

```bash
gh api -X GET search/code -f q='<SystemName> language:tla' --jq '.total_count'
```

Treat **>3 hits as burned**. Then — the step that catches the misses — **grep the MECHANISM,
not the name**, against the `tlaplus/Examples` README table. "Warehouse robot coordination" is
`MisraReachability` + mutual exclusion; "seat reservation" is the allocator; "leader failover"
is Paxos. **Name novelty is not mechanism novelty.**

### 5.7b Component: the puzzle screen

A **second, independent** screen. §5.7 asks "has someone already solved this?" This one asks
"is it even the right *kind* of thing?" A candidate can pass §5.7 cleanly and still be useless.

> **The screen: if you hand the learner the legal moves, is there anything left to model?**
> If no, it is a puzzle. Cut it, or add agents and failure until it isn't.

**Puzzle and system are two different things you can write in TLA+, and they exercise different
skills:**

| | Puzzle | System |
|---|---|---|
| The legal moves | **given by the domain** | **the thing you have to decide** |
| The question | "is the goal reachable?" | "is this design correct?" |
| Who does the work | TLC searches | you model, TLC checks |
| Where the difficulty lives | state-space size | abstraction choice |

**Why this is not pedantry.** Every puzzle in `tlaplus/Examples` — Die Hard, Tower of Hanoi,
N-Queens, missionaries and cannibals, the sliding block puzzle — is flagged **Beginner**. Not
because they are small, but because the modeling was pre-done by whoever wrote the rules. And
"puzzles where the state space is handed to you and the work is search" is the **first of the
four categories** the corpus survey found the entire public corpus consists of. It is the
category this project is defined against (§7.3).

**Local representation choices do not rescue a puzzle.** A puzzle usually still offers real
choices — for change-ringing: model bells→positions or positions→bells (inverse functions,
and picking wrong makes half the constraints awkward), or track visited rows explicitly versus
noticing that a repeated row *is* a repeated state so TLC's own deduplication enforces
no-repeats for free. Those are genuine and interesting. But they are **local** — about
transcribing a given action set tidily, not about deciding what the actions are. That is the
difference between good taste and modeling judgment, and only the second is what we are
teaching.

**The rescue pattern: add agents and fallibility.** This converts search into specification.
Change-ringing as a puzzle is "find a Hamiltonian path through the Cayley graph of Sₙ." Change-
ringing as a system is:

> Model a *band* — one ringer per bell, each with a reaction time, each able to mistime or lose
> their place, plus a conductor who can call corrections. The method they are attempting is the
> abstract spec. Does the band's actual behaviour refine it?

Now the actions are not given: you decide what a ringer's step is, what "losing your place"
means as state, and how much timing to model. It also lands naturally in **column F** — the
method is the abstract spec, the band is the concrete one, and the refinement question is
exactly "did they ring what they meant to ring."

**The screen has teeth beyond change-ringing.** From the §2.2 candidates:

- **Tournament brackets** — borderline. Advancement rules are given, but byes interacting with
  forfeits create genuine state questions.
- **Restaurant seating** — *fails* under one framing ("seat this party optimally" = bin-packing
  puzzle) and *passes* under another ("model the host stand with walk-ins and reservations
  arriving concurrently" = system). **The screen is what tells you which framing you wrote.**

Apply it at statement time (§6 step 4) as well as at domain-selection time — the same domain
can yield a puzzle or a system depending on how the statement is worded, so passing once does
not immunize the domain.

### 5.8 Read before building — **DONE 2026-08-06** (`tla-kl5.3`)

> Survey complete. Findings in `drawer_tla_puzzles_decisions_6251f5ad5930c77a531e9917`. Headlines:
> steal the `impliedinits`/`impliedactions` **configuration guard** (§5.4); keep our `>= N`
> threshold over their exact-equality fingerprint; steal **nothing** of the grading semantics —
> refinement-against-gold is one-sided and structurally blind to over-constraint. TLAiBench has
> the frozen-mapping trapdoor **wide open**, which vindicates §5.4's probe. And its `Gold!Stats`
> originally demanded the submission's state space equal the reference's *numerically*, then was
> relaxed in the field — third-party corroboration of §3.5 from the benchmark's own author.
> Do **not** copy its config ownership: it lets the subject under evaluation author its own
> `.cfg`, which is how the trapdoor stays open.

The original note, kept for context:

`github.com/tlaplus/TLAiBench` (MIT) already checks specs against a gold reference via two-stage
refinement plus `-postcondition Gold!Refinement` and **`Gold!Stats`** — that Stats postcondition
is precisely the vacuity guard derived independently above. Read it first; steal what fits.

Note its ten puzzles are simultaneously in LLM training data and graded benchmark targets, so
they are doubly excluded as problems — **and blind solvers will have memorized them.**

---

## 6. Stage 3 — Pilot problem, end to end

**Dependency:** §2.1 taxonomy + Stage 2 harness.
**Do exactly ONE problem through the full pipeline before any fan-out.** The pipeline has eight
steps and four gates; find the breakages on one problem, not forty.

Pick the pilot from gap **#11 (critique exercises — "what does this spec fail to say?")**. It is
the cheapest to author, has no public prior art anywhere in TLA+ pedagogy, and exercises the
grading engine without needing refinement.

### Pipeline

| # | Step | Dispatch | Gate |
|---|---|---|---|
| 1 | Write reference **cold** — optimized only as a spec, no commentary | agent A (§9.4) | — |
| 2 | Verify: properties pass, vacuity probes fail correctly, seeded variants caught | agent B (§9.5) | all green |
| 3 | **Freeze + hash** | central, inline | hash recorded |
| 4 | Write statement **from** frozen spec | agent C (§9.6) | — |
| 5 | **Leakage check** — adversarial, separate agent | agent D (§9.7) | no representation leaked |
| 6 | **Blind solve ×3** — fresh agents, statement only | agents E1–E3 (§9.8) | see spread rules |
| 7 | **Comment pass** — frozen spec, comments only | agent F (§9.9) | — |
| 8 | **Strip-and-diff gate** | central, inline | byte-identical modulo comments |

### Reading the blind-solve spread (step 6)

- **All three fail** → underspecified, or requires knowledge outside learntla core. Fix the statement.
- **All three succeed first-try with near-identical structure** → **trivial, or the statement is
  leaking.** This is a *failure*, not a pass. Send back to step 4.
- **All three succeed with genuinely different state representations** → **target achieved.**
  This is the measurable proxy for "admits real modeling choice."
- **Mixed** → read the telemetry: attempts taken, whether TLC caught bugs in the first draft,
  whether the solver revised its state representation.

A first-try clean solve from every solver should always flag for human review.

---

## 6b. Stage 4 — The tutor directory

**Dependency:** harness (§5) + pilot (§6).
**Dispatch:** ~3 agents. Briefs §9.10–§9.11.

Frank works the problems through a live Claude configuration rather than reading static text —
it presents the problem, answers questions, and drives review. He raised the leakage risk
himself, and it is the whole design constraint.

### 6b.1 Instruction isolation is NOT isolation

**Telling an agent not to look at the answers does not work.** An agent debugging a harness
failure will `cat` the reference, and it will be right to. Isolation must be structural.

| Leak vector | Fix |
|---|---|
| Filesystem — reference readable from the working tree | two directories, not one |
| Context bleed — one agent both answers questions and holds the reference | two agents, different filesystem views |
| Git history — reference ever committed alongside | separate repo, never co-committed |
| Grader output — "you're missing conjunct 3 of the reference" leaks the decomposition | return a verdict object, never a diff |
| **Training data — the model already knows burned problems** | **unclosable.** This is the operational reason §5.7 screening is not optional |

### 6b.2 Architecture

- **`tla-practice/`** — statements, Frank's attempts, the harness *client*, its own `.claude/`.
  This is where Frank and the tutor live.
- **`tla-answers/`** — references, seeded variants, expected state counts, post-hoc commentary.
  **Separate repo, not co-located**, denied in `tla-practice/.claude/settings.json`.
- **Tutor agent** runs in `tla-practice/` and genuinely does not possess the answer. Not "is
  instructed not to peek" — does not have it.
- **Grader** is a separate invocation with read access to `tla-answers/`. Takes
  `(learner spec, problem id)`; returns a **verdict object**: pass/fail per obligation plus
  **error location** (§3.7). Never reference conjuncts, never a diff.

### 6b.3 The tutor is a LANGUAGE tutor, not a solution tutor

It knows TLA+/PlusCal and learntla content. It does not know this problem's answer. It
**declines "is my approach right?"** — that is the thing being measured.

This constraint is not merely safe, it is the evidence-backed intervention. Perkins & Martin
(ERIC ED295618): content-free strategic prompts alone resolved **32% (conservative) to 55%
(liberal)** of impasses; specific hints added only ~15–17% on top — *"if the knowledge is there
to be marshalled, strategic questions usually suffice."* An agent that structurally cannot give
the answer is forced into the intervention that works best anyway.

Diagnostic bonus: when a strategic prompt unlocks Frank, the knowledge was **inert, not
absent** — a different problem with a different remedy, and one you can only distinguish by
prompting before hinting.

### 6b.4 Log everything — this is a research artifact

There is **no published record of TLA+ learner errors anywhere** — no misconception catalogue,
no corpus, no controlled study (see the pedagogy findings in
`drawer_tla_puzzles_decisions_be8cc4b03efbea276e444a12` and its companions). A tutor directory
that logs attempts, impasses, what unlocked each one, and how many edits preceded a pass
produces exactly the artifact the field lacks, for a language where nobody has it.

Log per attempt: timestamp, problem id, spec submitted, verdict object, questions asked, prompts
given, and whether the unlock was strategic or specific.

**Also log the impasse KIND — this is load-bearing, not nice-to-have.** Every problem sits in a
domain Frank does not know (§2.2), so an impasse can be either:

- **domain** — "I don't understand the rules of the system" → the statement is **broken**; fix it
- **modeling** — "I understand the system, I don't know how to represent it" → the problem is
  **hard**; leave it alone

These look identical from outside, and §7.1's refinement policy cannot be applied without the
distinction. The tutor should ask directly when an impasse is reached — "is it the rules of the
system that are unclear, or how to model them?" — and record the answer. Do not infer it.

---

## 7. Stage 5 — Batched production

**Dependency:** pilot (§6) + tutor directory (§6b).

### 7.0 Batched, NOT one big fan-out — deliberate reversal

An earlier draft of this plan said to pipeline all problems with no barriers, for throughput.
**That was superseded 2026-08-06 and should not be "fixed" back.** The batching is
*pedagogical*, not operational: Frank works each batch before the next is authored, so real
learner telemetry informs the remaining problems. Batch 1's data then shapes ~48 problems
instead of 0.

Within a batch, still pipeline freely — the barrier is between batches, at the point where a
human works them.

**Batch 1 = the DIAGONAL of the §2.1 grid**, ~12 problems. Walking the diagonal maximizes
situation × task-shape variety in the smallest possible set, so the first telemetry is broad
rather than deep. Batch 1 is PlusCal (§3b step 2).

Budget ~8 agent invocations per problem (1 author + 1 verifier + 1 statement + 1 leakage +
3 solvers + 1 commenter). At 60 problems that is ~480 invocations. This is the intended scale.

### 7.1 Progressive refinement policy

Problems get revised between batches. The line that keeps this honest:

> **Refine problems that are BROKEN, not problems that are HARD.**

- **Fix:** ambiguous statement, misfiring harness, a mechanism that turns out to be burned, a
  problem whose blind-solve spread was wrong (§6).
- **Leave alone:** frustrating but well-formed.

Two reasons the line matters:

1. Frank is simultaneously the subject and the instrument. You cannot measure progress with a
   ruler you are bending.
2. **78% of Kornell & Bjork's participants preferred the format that taught them worst.** His
   in-the-moment sense that a problem is *bad* is an unreliable signal for difficulty — though
   it is a **reliable** signal for ambiguity. Treat "this was confusing" as a bug report and
   "this was hard" as a non-event.

### 7.2 The holdout set

Build ~5 problems early, **never tune them**, and reserve them for a **delayed transfer check
on a different system**. This is the only honest measurement the research endorses — performance
during practice is an unreliable index of learning.

Do not site the holdout in S7 or S8 (§2.2 caveat 2).

### 7.3 Where the problems come from

Confirmed unserved across ~18 university courses plus the entire community corpus. The five
**safest** — pedagogically central, publicly unserved, structurally recall-resistant:

- **#1 choosing the abstraction** — every existing exercise hands you the state variables.
  Zero coverage worldwide. Highest value.
- **#6 time, timeouts, leases, TTL** — lease expiry, heartbeat vs GC interval, retry backoff,
  clock skew, "the timeout fired but the work actually succeeded."
- **#7 deployment, migration, schema evolution** — expand-contract, dual-write + backfill,
  rolling deploy with both versions live. Entire public corpus: one blog post.
- **#11 critique exercises** — "what does this spec fail to say?" **This format does not exist
  anywhere in TLA+ pedagogy.**
- **#13 UI / human-process flows** — checkout with back-button and double-submit, approval
  chains, undo/redo, optimistic UI reconciliation.

Also unserved: business-rule/domain-logic modeling with no concurrency at all; writing the
*property* rather than the spec; state-space management as a modeling decision; small-scale
refinement (everything extant is Paxos-sized); modeling from existing code; under-specified
problems requiring elicitation. Partially served: failure/adversary modeling — but
**retry/idempotency, exactly-once, and partition-and-heal have no exercise anywhere.**

### 7.4 Format techniques worth using

- **ENSEEIHT's split** — withhold practice solutions, publish fully-worked *exam* solutions.
  Calibration without spoiling the thing currently being attempted. This is also where the
  post-hoc commentary belongs.
- **Bordeaux's "most permissive" framing** — ask for the *most permissive* correct design, not
  *a* correct one. No memorizable canonical answer, and "does A admit behaviours B rejects,
  both still correct?" is mechanically checkable.
- **Predict → model → check → explain the divergence.** The self-explanation prompt is the piece
  with meta-analytic support (g=0.55), and requiring a prediction commitment *before* running
  TLC is the defense against grader-gaming.

### 7.5 Calibration

- Difficulty tracks **nesting depth, not size**. Nested quantifiers ~34% success vs ~53%
  unnested; anything temporal ~27%. Budget ~2× attempts for temporal problems.
- Learners quit around attempt 6 (32.6% gave up after a mean of 5.85 edits).
- Target 20–40 minutes. If the blind solvers take materially longer, the problem is too big.

---

## 8. Stage 6 — Assembly

1. **Coverage audit** (not before this point). Enumerate learntla core constructs; find the
   uncovered ones; add 2–3 problems at most. Do not let this reshape the set.
2. **Interleave order.** Never consecutive problems of one idiom. Interleave confusable
   near-neighbours: invariant vs inductive invariant; type invariant vs safety property;
   `WF` vs `SF`; `[]<>` vs `<>[]`; refinement mapping vs auxiliary variable; atomicity split at
   the read vs at the write.
3. **Back-load pure TLA+.** ~25 of 60, concentrated in the final third so there is a real
   transition rather than a sprinkle. Include a few problems only natural in pure TLA+
   (refinement mappings, non-algorithmic system contracts).
4. **Rewrite J01–J07 as comparison tasks.** Present two cases *without* the rule, prompt "what
   are the key parallels?", supply the distinction only afterward. 48% vs 16% transfer. Stop
   printing the answers under the classification exercise.
5. **Final screening sweep** (§5.7) over every shipped problem, by mechanism as well as name.

---

## 9. Subagent briefs — copy-paste

### 9.1 Refinement chapter author

> Write a chapter teaching refinement in TLA+, pitched as a direct continuation of
> learntla.com's core section — same register, same assumed background, same voice.
>
> **Thesis:** refinement is the technique that makes it reasonable to model large and complex
> systems. Not a formalism to admire — a tractability tool. Include the honest counterweight
> that Lamport says monolithic specs are usually easier when writing from scratch.
>
> **Assume the reader knows** (learntla core ch.12–13): `vars`, `Init`, `Next`, actions, primed
> variables, `UNCHANGED`, `Spec == Init /\ [][Next]_vars`, `[A]_v`, `ENABLED`, `WF`/`SF`,
> `INSTANCE`, `INSTANCE ... WITH`, `EXTENDS` vs `INSTANCE`. **Do not re-teach these.**
>
> **Cut** (dense notation, easy idea): `\EE`, `LM!Inner(...)!ISpec` chains, the overbar
> notation, parametrized instantiation, `Prophecy.tla`'s general machinery, Abadi & Lamport's
> tuple formalism.
>
> **Slow down on** (in this order of emphasis): stuttering as constitutive rather than
> permissive; **the vacuity hole as the centrepiece of the stuttering section**; the
> `vars`-substitution consequence; why mappings can fail to exist; prophecy variables; the
> non-constraining obligation; `ENABLED` not distributing; machine closure; and — near the
> beginning — that "X refines Y" is a claim about X, Y, **and the mapping**.
>
> **Hard requirements:** every TLA+ snippet must be executed before you include it. Quote from
> a git clone or your own runs, never from WebFetch (it summarizes; it does not return bytes).
> Use `Refines == Abstract!Spec` + `PROPERTY Refines`. Flag anything you could not verify.
>
> Sources: Lamport, *Specifying Systems* ch.10–11 (free PDF); *Hiding, Refinement, and
> Auxiliary Variables*; *Prophecy Made Simple*; `tlaplus/Examples/specifications/`
> (`locks_auxiliary_vars/` is a ready-made auxiliary-variable worked example).

### 9.2 Refinement chapter verifier

> You are given a draft chapter on TLA+ refinement. For **every** TLA+ snippet in it:
> extract it into a runnable module, run TLC, and report whether the claimed behaviour occurs.
> Report each snippet as VERIFIED / FAILED / NOT-RUNNABLE with the actual TLC output.
> Do not fix the chapter; report only. Flag any claim about TLC behaviour that the text asserts
> but does not demonstrate.

### 9.3 Harness component (template)

> Build `<component>` for a TLA+ autograder. Spec is in
> `drawer_tla_puzzles_decisions_be8cc4b03efbea276e444a12` §<n> — retrieve it with
> `mempalace_get_drawer` before starting.
>
> Every behavioural claim in that drawer was empirically verified on TLC 2026.03.04 /
> tla2tools 1.8.0. Re-verify anything you depend on if you are running a different version.
> Write tests that assert the exit codes and counts, not stdout text.
>
> Read `github.com/tlaplus/TLAiBench` first and reuse what fits.

### 9.4 Reference-solution author (step 1)

> Write a TLA+ specification for the system described below. Optimize **only** for it being a
> good specification — correct, idiomatic, at the right level of abstraction.
>
> **Write no comments.** Commentary is added in a later, separate pass; writing it now would
> bend the spec toward what is easy to narrate.
>
> Deliver: the `.tla`, a `.cfg`, the named observation operator, and — separately from the spec
> — a note on the state-representation alternatives you considered and rejected.
>
> <system description>

### 9.5 Reference verifier (step 2)

> Given a TLA+ spec, `.cfg`, and a list of properties it should satisfy:
> 1. Run TLC; confirm all properties pass (rc=0).
> 2. Run `tlc -inv "FALSE"`; confirm **rc=12** (reachable states exist).
> 3. Run with `-postCondition "Gate!NonVacuous"`; confirm pass.
> 4. Run `-coverage 1`; confirm **no action has `total == 0`** (not `distinct == 0` — an action
>    can fire and discover nothing new; PlusCal's `Terminating` shows `0:1` on every
>    terminating spec).
> 5. For each seeded-broken variant supplied, confirm **rc=12** against it.
> 6. Record the exact distinct/generated state counts.
>
> Report every command verbatim with its exit code. Do not fix anything; report only.

### 9.6 Statement author (step 4)

> You are given a **frozen** TLA+ reference solution. Write the problem statement a learner will
> receive.
>
> **Rules:**
> - Specify the SYSTEM completely and unambiguously — its entities, rules, and what must be true.
> - Leave the REPRESENTATION entirely open. Never name a variable, data structure, or
>   decomposition that appears in the reference.
> - Name an **observation operator** the learner must supply (e.g. `Observe == [...]`), and say
>   what it must expose — but not how their state is shaped.
> - State a property to establish or refute. Never ask for an algorithm to be implemented.
> - Target 20–40 minutes for someone who has read learntla.com core.
>
> **Then apply the §5.7b puzzle screen to your own statement before delivering:** if you have
> handed the learner the complete set of legal moves, you have written a puzzle, and TLC will do
> all the remaining work. The same domain yields a puzzle or a system depending purely on how
> you word it — "seat this party optimally" is bin-packing; "model the host stand with walk-ins
> and reservations arriving concurrently" is a system. If your statement fails the screen,
> rewrite it with agents and fallibility until it passes, and say in your delivery that you did.
>
> **Run the screens as the tools, not from memory of this brief.** The rubric is
> `harness/PUZZLE-SCREEN.md` — an 8-question checklist where Q1 is the screen and Q2–Q8 exist to
> catch a wrong Q1; work it in order and record your answers. Then run
> `./harness/screen.sh --name '<SystemName>'` for the §5.7 mechanism-collision check and paste
> its verdict. A `CLEAR` from `screen.sh` is **not** a clean bill when it reports no mechanism
> derived — that means its synonym table did not recognize your phrasing, so name the mechanism
> yourself before trusting it.
>
> Deliver the statement only.

### 9.7 Leakage checker (step 5)

> You are given a problem statement and, separately, the reference solution it was written from.
>
> Answer one question: **does the statement give away the state representation?**
>
> Flag every sentence that names or strongly implies a variable, data structure, decomposition,
> or atomicity boundary present in the reference. Be adversarial — assume the statement's author
> leaked structure without noticing, because writing the statement from the solution makes that
> nearly automatic.
>
> Report flagged sentences with the reference element each one leaks. Do not rewrite.
>
> **Then run `harness/PUZZLE-SCREEN.md` against the statement independently of its author.** The
> author already screened their own work and is attached to it; you are the second, adversarial
> pass. A statement can leak nothing and still be a puzzle — those are different defects, and
> §5.7b explicitly says passing the screen once does not immunize a domain, because the wording
> is what decides it. Report a screen verdict alongside your leakage findings.

### 9.8 Blind solver (step 6 — dispatch THREE, independently)

> Solve the TLA+ modeling problem below. You have the statement and your own knowledge of
> TLA+/PlusCal. **You do not have a reference solution, and must not search for one** — if you
> recognize this as a known published problem, say so immediately and stop.
>
> Deliver: a complete `.tla`, a `.cfg`, and the observation operator the statement names.
>
> Also report, honestly — this telemetry is the point of the exercise:
> - how many attempts before TLC was clean
> - whether TLC caught a bug in your first draft, and what it was
> - whether you revised your state representation mid-way, and why
> - which representation alternatives you considered and rejected
>
> <statement>

### 9.9 Comment-pass author (step 7)

> You are given a **frozen** TLA+ specification. Add comments.
>
> **You may add ONLY comments. You may not change a single non-comment character.** A mechanical
> strip-and-diff gate will reject your output if you do — this is checked, not trusted.
>
> Comment on **modeling decisions**, not syntax. The reader has read learntla.com core and does
> not need TLA+ explained. Cover:
> - why this state representation, and what was rejected
> - where the atomicity boundaries are and why
> - why this invariant captures the stated property, and what it deliberately does not capture
> - **what was elided from the model, and why that elision is safe**
>
> Purpose, in the project owner's words: *"if there is an idea I missed, I can at least get a
> gist of it from the solution."*
>
> If the spec is PlusCal, remember the algorithm lives inside `(* --algorithm ... *)`; comments
> you add there must not alter the generated TRANSLATION block.

### 9.10 Tutor-directory builder

> Build `tla-practice/` — a Claude working directory in which a learner solves TLA+ modeling
> problems with an agent's help. Architecture spec is §6b of `V2-PLAN.md`; read it first.
>
> **The single hard requirement: the tutor must not be able to reach the reference solutions.**
> Not "must be instructed not to" — must not be *able to*. References live in a separate,
> non-co-located `tla-answers/` repo. Add a deny rule for it in
> `tla-practice/.claude/settings.json`. Assume any agent debugging a harness failure will read
> whatever it can reach, and design so that reaching it is impossible rather than forbidden.
>
> Build:
> 1. A problem-presentation flow (statement, working area, submit).
> 2. A **grader invocation** that runs OUTSIDE the tutor's filesystem view, takes
>    `(learner spec, problem id)`, and returns a verdict object: pass/fail per obligation plus
>    **error location**. It must never return reference conjuncts or a diff against the
>    reference — that leaks the decomposition.
> 3. An **attempt log** (§6b.4): timestamp, problem id, spec submitted, verdict, questions
>    asked, prompts given, whether the unlock was strategic or specific.
>
> Do NOT give the tutor the answers "so it can help better." That is the entire failure mode.

### 9.11 Tutor system prompt author

> Write the system prompt for the tutor agent in `tla-practice/`.
>
> **Framing: it is a LANGUAGE tutor, not a solution tutor.** It knows TLA+/PlusCal and
> learntla.com content. It does not know the current problem's answer and has no access to it.
>
> Behaviour:
> - Answers questions about TLA+ and PlusCal language, semantics, tooling, and learntla content.
> - **Declines "is my approach right?" / "is this the intended model?"** — that is the thing
>   being measured, and answering it destroys the measurement.
> - **Offers content-free strategic prompts BEFORE any specific hint.** Evidence: strategic
>   prompts alone resolve 32–55% of impasses; specific hints add only ~15–17% on top. If a
>   strategic prompt unlocks the learner, the knowledge was inert rather than absent — note that
>   in the log, because it is a different diagnosis with a different remedy.
> - When relaying a grader verdict, give **error location**, never prose explanation of what is
>   wrong and never a prettified trace. The only RCT on this found location hints beat control
>   (9.12 vs 5.67 tasks solved), counterexample hints statistically indistinguishable from no
>   hint, and natural-language descriptions *below* control and the most demoralizing arm tested.
> - Requires a **prediction commitment before running TLC** ("what do you expect to happen?"),
>   and grades the prediction. This is the defense against grader-gaming — students otherwise
>   "learn the grader, not the concepts."
>
> It should be warm but not reassuring-by-default. The learner will systematically prefer the
> interaction style that teaches worst; do not optimize for their in-the-moment comfort.

---

## 10. Known traps

- **`THEOREM Spec => A!Spec` does nothing.** TLC silently ignores `THEOREM`; it is TLAPS
  documentation. Verified: a deliberately wrong concrete spec with a `THEOREM` and no `PROPERTY`
  returns `No error has been found`. Reject any submission whose refinement claim lives only in
  a `THEOREM`.
- **`SYMMETRY` and `VIEW` make temporal checking unsound** — SS p.244/246: may "miss errors,
  report an error that doesn't exist, or report a real error with an incorrect counterexample."
  **No symmetry on any problem checking a temporal property.**
- **Apalache: never trust exit 0 alone.** `SmtTimeout` and `ExecutionsTooShort` both exit 0.
  Parse the outcome string. It also silently ignores `PROPERTY`, `CONSTRAINT`, `SYMMETRY`,
  `VIEW`, and `ALIAS` in a `.cfg`, and requires `@type:` annotations on every variable and
  constant. TLC is primary; Apalache is an optional second opinion.
- **`bd preflight` here runs Go-hardcoded checks** (`go test`, `golangci-lint`, `gofmt`) and is
  actively misleading on this repo. bd 1.0.2 has no `preflight.template` support. See `tla-9ic`.
- **`docs/` is generated** (gitignored, built by `scripts/build-docs.sh` from `module-docs/`).
  Never edit it; edits are destroyed on the next build.
- **`scripts/` holds 8 unwired `exit 2` stubs** scaffolded by `/loom-adopt` P2. The project
  constitution deliberately leaves `canonical_commands` empty because of this. See `tla-xme`.
- **Six of the 35 mined drawers have bodies truncated at a backslash** (`fcb4b15`, `31f52bc`,
  `790039b`, `c1a33f8`, `4eba5f1`, `33a2c38`). Recover full text with `git show <sha>`. See
  `tla-nov`.

---

## 11. Open research gaps

Worth closing if cheap; none blocks execution.

- **Nievelstein, van Gog, van Dijck & Boshuizen (2013)**, *Contemporary Educational Psychology*
  38(2):118–125 — worked examples and expertise reversal **in an ill-structured task** (legal
  reasoning). The single most relevant title for "do worked examples transfer to design-shaped
  domains." Every open route was blocked.
- **Holland (1965)** and **Krumboltz (1964)** — the primary sources for the programmed-instruction
  component dismantling. Cited consistently in secondary literature; primaries unverified.
- **No community-observed record of TLA+ learner confusion.** All pitfall material is
  Lamport-sourced or reproduction-verified, not observed. A pass over the tlaplus Google group
  and Stack Overflow for "here is the confused question people actually ask" would be genuinely
  new — there is **no published empirical study of TLA+ learning at all**.
- **`writingspecs.com`** returns HTTP 403 to automated fetch; content and authorship unverified.
  Worth a manual browser visit.
- **Hillel Wayne's paid workshop materials** — no public exercise repo found. Worth a direct ask.
