# V2 Rebuild — Execution Plan

**Status:** handoff document, written 2026-08-06. Tracked by bead **`tla-qpm`**.
**Audience:** the next session, which will have none of the originating context.

---

## 0. How to use this document

Read §1 and §3 before doing anything. §3 is a list of decisions that are *closed*; reopening
them wastes a session and usually re-derives a worse answer, because most were settled against
measured evidence rather than intuition.

Stages 1–5 are ordered by dependency. Within each stage, the work is decomposed into units
that are meant to be **dispatched to subagents**, with copy-pasteable briefs in §9.

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

**Open beads:**

- `tla-qpm` (P1) — this plan
- `tla-syn` (P2) — `verify-puzzle.sh` should branch on `$?`, not stdout greps; must pin `-workers 1`
- `tla-5b4` (P2) — CI downloads `tla2tools.jar` from `latest`; pin the release
- `tla-xme` (P2) — wire the 8 scaffolded `scripts/` stubs, or mark N/A
- `tla-nov` (P3) — review the 35 mined drawers; 6 have bodies truncated at a backslash
- `tla-9ic` (P3) — `bd preflight` runs Go-hardcoded checks here; misleading

**The goal, in Frank's words:** *"get good at thinking in TLA, the way it's meant to be used"* —
ending able to write entirely in TLA+.

---

## 2. Decisions still owed by Frank

These block Stage 3 and beyond. Do not guess them.

### 2.1 The modeling-situation taxonomy (BLOCKING)

The problem set is organized around **modeling situations**, not language constructs (see §3).
The taxonomy — which situations, how many problems each, what order — is not yet chosen.

Inputs available: the five confirmed-unserved gaps (§7.1), the four surviving problem veins,
and the interleaving constraint (§3.4). Frank has approved ~40–60 problems with ~25 in pure
TLA+, back-loaded.

Bring him a proposed taxonomy of 8–12 situations with a problem-count allocation. Do not start
authoring problems before this is settled — the taxonomy determines the interleave order, and
retrofitting an interleave onto an already-written set is how you end up with blocked practice
wearing an interleaved label.

### 2.2 Domain list

Problems must sit in domains Frank does **not** already have a schema for (§3.7). He works in
industrial IoT / facility management (CrossnoKaye Atlas: facility status, control state,
alarms, sensors, refrigeration). **Those domains are disqualified for judgment problems.**

Propose 15–20 candidate domains and get them checked against "do you already think in this?"

### 2.3 Refinement chapter scope

Frank has approved it and supplied the framing: **refinement is what makes it reasonable to
model large and complex systems.** That framing is the chapter's thesis (§4). Remaining
question is length and whether it ships as one document or as chapter + worked example.

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
| 150 | parse / semantic failure |
| 151 | config failure |
| 255 | file not found |

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

### 5.8 Read before building

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

## 7. Stage 4 — Fan-out

**Dependency:** pilot complete and pipeline debugged.

Run the §6 pipeline per problem. Problems are independent; use a pipeline (no barriers) rather
than staged batches, so a problem in step 7 does not wait on a problem in step 2.

Budget roughly 8 agent invocations per problem (1 author + 1 verifier + 1 statement + 1 leakage
+ 3 solvers + 1 commenter). At 40 problems that is ~320 invocations. This is the intended
scale — Frank has explicitly allocated the tokens.

### 7.1 Where the problems come from

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

### 7.2 Format techniques worth using

- **ENSEEIHT's split** — withhold practice solutions, publish fully-worked *exam* solutions.
  Calibration without spoiling the thing currently being attempted. This is also where the
  post-hoc commentary belongs.
- **Bordeaux's "most permissive" framing** — ask for the *most permissive* correct design, not
  *a* correct one. No memorizable canonical answer, and "does A admit behaviours B rejects,
  both still correct?" is mechanically checkable.
- **Predict → model → check → explain the divergence.** The self-explanation prompt is the piece
  with meta-analytic support (g=0.55), and requiring a prediction commitment *before* running
  TLC is the defense against grader-gaming.

### 7.3 Calibration

- Difficulty tracks **nesting depth, not size**. Nested quantifiers ~34% success vs ~53%
  unnested; anything temporal ~27%. Budget ~2× attempts for temporal problems.
- Learners quit around attempt 6 (32.6% gave up after a mean of 5.85 edits).
- Target 20–40 minutes. If the blind solvers take materially longer, the problem is too big.

---

## 8. Stage 5 — Assembly

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
