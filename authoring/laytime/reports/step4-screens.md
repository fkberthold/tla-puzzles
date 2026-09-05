# laytime step 4, screens on the statement as worded

Written under V2-PLAN §9.6 against `authoring/laytime/statement/PROBLEM.md`.
Bead `tla-h2cg.8`, rung 2 of batch 2, shape A. The domain cleared step 0
before the reference was written (`reports/step0-screens.md`). This run asks
whether my wording kept it clear, which passing once doesn't settle (§5.7b).
Both screens ran on the statement as delivered, not on a draft.

I recorded my answers before reading the step 0 record's answers back. The
step 0 screen is the only prior screen of this domain and I'd already read it
as part of the brief, so that ordering claim is weaker here than it would be
against an unread record. Worth saying rather than claiming a blind run.

## §5.7, the mechanism screen

Two runs of `harness/screen.sh --name Laytime`, both phrasings lifted from
the statement's own words, verdicts pasted:

```
=== CANDIDATE: a fixed allowance of time to get the cargo off and when it runs out the charterer keeps paying under a different name
--- step 1: NAME collision
    query: 'Laytime language:tla'
    hits: 2 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

```
=== CANDIDATE: the ship agent logs periods against a laytime allowance and once it is spent the charter exceptions stop applying and every period accrues demurrage
--- step 1: NAME collision
    query: 'Laytime language:tla'
    hits: 2 -> clear (<=3)
--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)
    no mechanism derived from this phrasing.
    NOT a clean bill: it may mean the mechanism vocabulary in this script is
    missing a synonym. Name the mechanism yourself before trusting a CLEAR.
--- §5.7 VERDICT: CLEAR   (name: CLEAR | mechanism: CLEAR)
```

Neither phrasing fired the `warehouse|robot` row, and neither fired the
`blood bank|inventory|expiry` row that step 0 recorded as this rung's known
false positive (`reports/step0-screens.md:50-60`). My statement never uses
the word expiry, which is why. That reads to me as luck of vocabulary rather
than a fix, and rungs 5 and 7 should still expect the row.

The two name hits are the GitHub tokenizer artifact step 0 chased down: both
sit in one repo and match the substring inside `ReplayTimeClose`, not the
word laytime (`reports/step0-screens.md:118-122`). Unchanged.

The tool derived no mechanism from either phrasing and says itself that isn't
a clean bill. So, named by hand, and I keep step 0's naming because the
statement didn't move the mechanism: **a non-refilling allowance drawn down
at a rate the actor declares, with a one-way latch that changes which future
steps count.** The allowance only falls, the latch fires once, and after it
fires the classification that used to exempt a period stops exempting it.

Why the nearest burned mechanisms still don't fit, checked against my wording
rather than step 0's:

- **Token bucket**, 41 public hits and the closest named neighbour. A bucket
  refills at a rate and running dry denies the request. My Rule 6 says
  nothing refills the allowance, and my Rule 7 says running dry reprices
  rather than denies.
- **Scheduling.** Assigns work to slots against a constraint. My Rule 4 says
  the agent writes a period after the fact, so there's no slot and no
  ordering choice.
- **Resource allocation.** Needs contention over something finite with
  somebody waiting. My parties paragraph has one actor and nobody waiting.
- **Atomic commitment.** Needs a vote and an abort path. A logged period has
  neither.

CLEAR, with the mechanism named by hand rather than by the tool.

## §5.7b, the puzzle screen, action-centric form

Shape A hands the learner no spec, so Q1 and Q2 are answered in their first
form, about actions. Q3 to Q8 as written.

| # | Question | My answer |
|---|---|---|
| 1 | Hand over the legal moves. Anything left to model? | **Yes, the actions.** The rules name what the agent does in the log. Whether a period is one step or two, whether the kind is an action or an attribute, and whether the mode is carried or derived are all left open. |
| 2 | Actions given, or decided? | **Decided.** The prose names domain events and nobody hands over a decomposition. The interface fixes four facts and says nothing about what moves them. |
| 3 | What is asked? | **Is this design correct.** Three requirements to establish. No goal state, no reachability. |
| 4 | Who works once it compiles? | **The learner models, TLC checks.** 11 distinct states is nothing to search. |
| 5 | Where does the difficulty live? | **Abstraction choice.** How the allowance is carried, and whether the latch is state or falls out of the allowance being spent. |
| 6 | Agents, fallibility, interleaving? | **One, infallible.** Puzzle row, and mandated by the vector at step sources 0. |
| 7 | Delete TLC, decision left? | **Yes.** Whether "once on demurrage, always on demurrage" is a state predicate or a step rule is arguable on paper, and my answer set splits it across both. |
| 8 | Names an optimum? | **No.** |

**One puzzle row of eight, against a threshold of three.** It's row 6, and
step 0 predicted it would be: the rung pins one actor, so no wording rescues
that row (`reports/step0-screens.md:66-71`).

**KIND: ACCEPT, system.**

## R, the route

**Intended route.** Read the eleven rules. Decide how the allowance is
carried, whether the mode is a fact you keep or a fact you read off the
allowance, and what one logged period is as a step. Write the state, write
`Observe`, render the three requirements under the keywords the statement
gives, run TLC, then hold the model against the three pairs.

**Probes.**

- **Tiling.** Three requirements against three pairs, one to one. The
  statement says so itself, so this is §3.9 by construction rather than a
  leak. Eleven rules against three requirements is the interesting table, and
  it doesn't close: rules 2, 10 and 11 have no requirement, and the statement
  says outright that half of rule 8 has none either. A learner who builds
  that table finds holes and has to decide what each hole means, which is the
  judgment rather than a shortcut past it.
- **Vocabulary absence.** "Excepted" appears 7 times in the prose and 0 times
  across the three trace files. "Working" likewise. That absence is real and
  it's the declared Rule 8 gap, which the statement names in its own
  paragraph rather than leaving to be found.
- **Elimination.** Requirement 3 is the only state predicate and the only
  single-state pair, so a learner who reads the pair lengths can guess which
  requirement is the invariant. That's inherent to shipping pairs and a
  reword can't remove it.
- **Answer form.** Form 0 gives every keyword, every kind and both
  subscripts. That's the rung's own level and not a concession. It fixes how
  each requirement is declared and says nothing about what any of them
  contains.
- **Pre-clearing.** Two passages. The Rule 8 paragraph says a stated rule
  isn't watched, and the checking section says a count other than 11 means
  the model has come apart from the rules. Both are required honesty. The
  second one is the one I'd watch, and the next section says why.
- **Recall.** §5.7 above. No tool-derived mechanism, hand-named, and no
  published spec of the mechanism found at step 0 to crib a property list
  from.

**Shortest route found.** Pattern-match the three pairs and skip the prose.
It gets you what each requirement forbids. It doesn't get you the state, the
`Observe` rendering, or the decision the rung is built on, because the pairs
show four scalar fields and never show how anything is carried underneath. So
the prose gets read anyway, and the abstraction is still unmade. I don't see
a route to a passing model that skips it.

**Where the residue lives.** In the artifact, and the piece I'm least happy
with is the 11-state count. It's a real oracle against the failure this rung
is built on, since a learner who carries the mode as a variable that drifts
gets a different number and requirement 3 breaks. It's also a hint that the
intended model is small, and the sentence about TLC counting over every
variable narrows it further. I put that sentence in because without it a
learner who writes multi-label PlusCal gets a count they can't explain and a
wrong diagnosis. I think the trade is right and I'd rather record it than
round it off. A reword can soften the sentence but can't remove the count,
because the count is what the brief asks the statement to ship.

**ROUTE: ACCEPT.** The shortest route I can find is the intended one.

## The step 2 constraints, and how the statement handles them

**1. Rule 8's second half is graded by nothing** (finding 1: S14 has the
reference's exact state graph, 15 generated and 11 distinct, every number
matching). Handled by saying it. The statement's Rule 8 paragraph under "What
to establish" says the first half is carried by requirement 2, that the
second half is invisible to this interface, that a period's kind never
reaches `Observe`, and that the learner should model the rule whole anyway
because it's the rule of the trade. No pair covers it and none pretends to.

**2. The wrong subscript is the live failure mode** (finding 5: rc=13 under
`_Observe`, rc=0 under a single-field subscript, reproduced on both action
properties). Handled twice. Each of the two step requirements carries its own
subscript line, and a bolded paragraph names the failure mode: satisfied for
free by a step that moves only the other fields, and TLC won't warn you.
Interface terms only, no formula.

**3. Two rules ride on the type invariant** (finding 4: S13 and S19 caught by
`TypeOK` alone, which isn't a learner requirement). Not handled in the
statement, on purpose. The statement lists three requirements and says a type
invariant of the learner's own is fine and isn't one of them. The carrier for
those two rules is §5.2's under-approximation, which is a grading-side fact
and not something a statement can say without turning it into a fourth
requirement.

**4. The vacuity floor.** Step 2's finding 3 left this call to me. I set it
at 4, and the reasoning is in `author-notes/step4-trace-map.md` rather than
here because it's a grader-side parameter.

## The transcription sentence

Every empirical constant this report leans on was measured on TLC2 Version
2026.07.31.184830, the project's canonical build, and the numbers match step
2's on the same build. Nothing here was carried over from a different jar.

## Verification behind the shipped artifacts, in one block

- FREEZE check: `sha256sum` over `reference/Laytime.tla` and
  `reference/Laytime.cfg` against `reference/FREEZE.sha256`, both digests
  equal, before anything was derived. `reference/` was never written to.
- The reference's own run: `harness/verdict.sh -t 120` with the reference
  cfg, `OK` rc=0, **15 states generated, 11 distinct states found**, matching
  step 2's counts exactly.
- Deadlock: the same module and instance with the check on comes back
  `DEADLOCK` rc=11, which is what the statement's `-deadlock` instruction is
  for. Five of the eleven reachable states are terminal
  (`reports/step0b-fit-review.md:69`).
- Violating traces: S01, S05 and S11 re-run through `harness/verdict.sh` with
  their committed cfgs. rc 13, 13 and 12, obligations and trace lengths
  matching step 2's table row for row.
- Satisfying traces: hand-built, then machine-validated against the frozen
  reference by a trace-forcing scratch module. rc=12 means the walk reached
  the last row under `Next`. Three of three validated, and a deliberately
  illegal control came back rc=0, so the check can fail.
- Vector: `bash harness/test-vector.sh` passes on
  `authoring/laytime/VECTOR.md`. The suite's one failure is
  `authoring/bonded-store/VECTOR.md: missing file`, which is rung 1's record.
  It's absent at my merge base and present on `main`, so the failure is my
  stale base and not this bead's work.
