# laytime step 5: leakage check and delivery-boundary audit

Written under V2-PLAN §9.7 against the four learner-facing files of
`authoring/laytime/statement/`. Bead `tla-h2cg.8`, rung 2 of batch 2, task
shape A, form 0. I didn't author the reference, the statement or the traces.

Author-only. This file names what the statement hands over and what it
doesn't, so it lives in `reports/` and never travels with the problem.

**Verdict: SHIP after D1.** One paragraph in the checking section tells a
correct learner their model is wrong, and I measured it. Everything else I
found is a note for central.

Order of work, because it changes what my screen is worth. I read the four
learner files and nothing else, ran `harness/PUZZLE-SCREEN.md` against them,
and wrote §1 below before opening the plan, the reference, the description or
either sibling report. Section 1 is that record unedited. Wave 1's checkers
found they couldn't screen independently after reading the answers side, and
this is the fix.

## 1. The screen, written from the learner set alone

Shape A ships no spec, so Q1 and Q2 are in their first form, about actions.

| # | Question | My answer | reads |
|---|---|---|---|
| 1 | Hand over the legal moves. Anything left? | The actions. Whether the latch is carried or read off the allowance, and whether the classification is one action or two, are open. | system |
| 2 | Actions given, or decided? | Given, with a split. Below. | puzzle |
| 3 | What is asked? | Is this design correct. Three requirements, no goal state. | system |
| 4 | Who works once it compiles? | The learner models. TLC checks 11 states. | system |
| 5 | Where does the difficulty live? | Abstraction choice. How the allowance is carried. | system |
| 6 | Agents, fallibility, interleaving? | One, infallible. `PROBLEM.md:38-41` says so outright. | puzzle |
| 7 | Delete TLC, decision left? | Yes. Whether the latch is state is arguable on paper. | system |
| 8 | Names an optimum? | No [grep for optimal, minimum, fewest, best, shortest, rc=1]. | system |

**Two puzzle rows of eight, against a threshold of three. KIND: ACCEPT,
system.**

The Q2 split, since the screen wants both halves. Given: Rules 3, 5 and 9
name tender, log a working period, log an excepted period, and close, and
Rule 4 fixes the atomicity by saying time moves only when the agent writes a
period. That's a decomposition and a step boundary, handed over. Decided:
whether the two kinds are one parameterized action or two, and what state a
logged period leaves behind.

I land on given where the author landed on decided
(`reports/step4-screens.md`, Q2). The disagreement doesn't move either
verdict, since neither of us is near three, and I think it's worth recording
rather than smoothing. The author answered about the interface, which fixes
four facts and says nothing about what moves them. I answered about the
rules, which do say.

### R, the route

**Intended route.** Read the eleven rules. Decide how the allowance is
carried and whether the latch is a fact you keep or a fact you read off the
allowance. Write the state, write `Observe`, render three requirements under
the keywords given, run at `Allowance = 2` and `Limit = 2`, then hold the
model against the three pairs.

**Probes.** Tiling first. Three requirements against three pairs, one to one,
and `PROBLEM.md:217` says so, which is §3.9 by construction. Eleven rules
against three requirements is the table that doesn't close, and the statement
declares the largest hole itself at lines 209-213. A learner who builds that
table gets holes to think about rather than a shortcut past them. Vocabulary
absence fires on "working" and "excepted", which appear in the prose and
nowhere in the traces, and that's the declared Rule 8 gap. Elimination fires
on pair 3, the only single-state run against the only state predicate, so
pair lengths index the kinds. At form 0 the kinds are given anyway
(`PROBLEM.md:193`), so it costs nothing. Answer form gives every keyword,
every kind and both subscripts, which is form 0's own level. Pre-clearing
finds two passages, the subscript warning at 201-207 and the Rule 8 note at
209-213, both required honesty. Recall is §5.7's row, not mine.

**Shortest route found.** Read the checking section first. Line 251 says the
run should find 11 distinct states and line 252 says TLC counts over every
variable you declare. Together they say your variable set has to be the four
facts, or something the four facts determine. That's the rung's abstraction
question answered by a number before a rule has been read. Take the four
field names as your variable names and the rest is transcription.

It doesn't reach an answer. Four actions still have to be written, and Rule
7's fork and Rule 9's cap still have to be guarded, and those are real work.
So the shortcut narrows the representation and leaves the specification.

**ROUTE: ACCEPT**, with the count recorded as residue. It's also where D1
lives, which I didn't see until I had the reference.

## 2. Does the statement give away the state representation?

Partly. What it gives away is what the shape obliges, plus one sentence more.

**The field names are the reference's variable names.** `PROBLEM.md:150-153`
names `noticeTendered`, `laytimeLeft`, `demurrage` and `finished`.
`reference/Laytime.tla:75` declares those four variables, in that order, and
`:78-82` defines `Observe` as the identity record over them. So a learner who
names their variables after the fields, which is the obvious move, lands on
the reference's exact state.

This isn't the author's slip and a reword can't close it. §3.3 obliges the
statement to fix the field names, because grading compares them. The only way
to break the coincidence is upstream, by naming the reference's internal
variables something else so `Observe` becomes a rename rather than an
identity. `DESCRIPTION.md:12-13` declares the identity in advance, so it was
a decision. I'd still rather it were said out loud in a leakage report than
inferred later from a panel that all wrote the same four variables.

**The decomposition and the atomicity boundary are handed over.** Rules 3, 5
and 9 name four moves and `reference/Laytime.tla:119-137` has exactly four
disjuncts, one to one. Rule 4 says time moves only when the agent writes a
period, and Rule 7 says a logged period does one thing. That fixes what one
step is. §3.2 obliges the statement to fix the system, and both of those are
system facts rather than solution structure, so I don't call either a leak.
It is why Q2 reads given.

**Nothing else fires.** The statement never names a variable that isn't an
`Observe` field, never gives a range, and never shows a formula. It says "a
natural number" at lines 158-159 where `TypeOK` says `0..Allowance` and
`0..Limit` (`reference/Laytime.tla:84-88`), so it's looser than the reference
on purpose. That's right. The ranges are the reference author's cfg line and
not a learner requirement.

## 3. The fields

Stated as facts, with shapes pinned, and nothing more. Four fields at
150-153, four types at 157-160, and lines 162-164 say there's no absent
marker anywhere and that every field carries a value from the opening onward.
No model value and none needed, which is the right handling here.

No field forces a side of a §5 fork. The fork `DESCRIPTION.md` §3 names is
whether the latch gets a fifth field, and four fields with no latch field
answers it. That answer is mandatory rather than a concession. You can't ship
an `Observe` contract and leave a field's existence open. What stays open is
whether the learner carries the latch in state, which is the half that's
graded, and the statement says nothing about it.

## 4. The pairs

No representation and no formula. Each file carries a heading, one shared
sentence, and state dumps over the four fields. A sweep across all three for
`requirement`, `invariant`, `propert`, `rule`, `safety`, `subscript`,
`Observe`, `rc=`, `S0`, `S1`, `Allowance`, `Limit`, `excepted` and `working`
returns three hits, all of them the shared sentence "The first run stays
inside the rules" [grep, 3 lines]. Nothing else.

Each violating half breaks its own requirement and nothing simpler.

- **Pair 1.** The allowance falls with the notice untendered. Requirement 2
  allows a fall by one, and requirement 3 is vacuous at zero demurrage, so
  only requirement 1 rejects it.
- **Pair 2.** The allowance falls from 2 to 0 in one step, with the notice
  tendered. Only requirement 2 rejects it.
- **Pair 3.** One state, one period accrued against a full allowance. Both
  action properties are trivially true over a one-state run, so only
  requirement 3 rejects it.

Three for three, each isolating its own requirement. `PROBLEM.md:225-226`
licenses overlap and none of the three needs it. That's cleaner than the
shape requires and I'd rather say so than let it pass unremarked.

## 5. The delivery boundary

The learner set is four files:

```
statement/PROBLEM.md
statement/traces/pair-1.md
statement/traces/pair-2.md
statement/traces/pair-3.md
```

`statement/` holds those four and nothing else [`find`, 4 lines]. No file in
the set mentions `authoring/`, `reference/`, `author-notes`, `reports/`,
`FREEZE`, `V2-PLAN`, a `tla-` bead id or a `§` section mark [grep, rc=1].

65 author-only files sit outside that subtree, and two of them carry the
graded answer outright. `DESCRIPTION.md` §2 lists the three must-be-trues in
English and labels their kinds, and `author-notes/step4-trace-map.md` maps
every pair to the obligation it witnesses. The structural boundary holds, so
this isn't a defect, but the panel brief has to name the four files one by
one. No directory and no glob. `PROBLEM.md:11` and `:217` point the learner
at `traces/` as a location, which is right for somebody holding a delivered
directory and wrong for a brief written against this tree.

## 6. The vector

`bash harness/test-vector.sh` ends **`FAILED: 28 passed, 4 failed`**. The
laytime row passes: `authoring/laytime/VECTOR.md records the package frozen
at authoring/laytime/reference/FREEZE.sha256`, PASS [grep over the run
output]. The four failures are `assay-office`, `estate-notice`,
`floor-malting` and `river-call`, each frozen without a record yet, which is
expected mid-pipeline.

The freeze holds. `sha256sum -c FREEZE.sha256` over `Laytime.tla` and
`Laytime.cfg`, both OK.

I checked all fifteen citations in `VECTOR.md`. The six levels are right as
far as I can tell. Four citations are off, all of them hygiene rather than a
wrong level.

- `reference/Laytime.tla:109`, under representation, is a blank line.
  `OnePeriodOneMove` ends at 108 and `vars` is at 111. I think the intended
  target is 75 or 111, either of which carries the claim.
- `reports/step2-variants.md:183-184` catches "11 distinct states found" on
  183 and misses "15 states" on 182. The record's own text says "15
  generated, 11 distinct", so the range wants to start at 182.
- `reference/Laytime.tla:117-137`, under step sources, starts inside `Init`.
  `Next` runs 119 to 137.
- `reference/Laytime.tla:139`, under property kind, is
  `Spec == Init /\ [][Next]_vars`. It carries no property kind. I read it as
  evidence that there's no fairness conjunct, so the ceiling is 2 and not 3.
  That reading holds, but the line says it by absence and the reader has to
  supply the argument.

## 7. Defect

**D1. `PROBLEM.md:251-254` tells a correct learner their model is wrong.**

> Whatever else you declare, the run should find 11 distinct states. TLC
> counts over every variable you declare, so that number checks your whole
> model and not only the four facts. A different count means your model and
> the system above have come apart, and the rules are where to look first.

Line 212 tells the learner to model Rule 8 whole, because it's the rule of
the trade. The most obvious way to do that is to keep the kind of the period
you just logged. I built that model and ran it: same four actions, same
guards, plus `lastKind` carrying `"none"`, `"working"` or `"excepted"`, with
the reference's own four obligations checked over the same `Observe`. It
comes back "Model checking completed. No error has been found", **25 states
generated, 19 distinct states found** [`tlc -workers 1 -deadlock`, scratch
module, deleted before the footprint check]. The frozen reference on the same
build and instance reads **15 generated, 11 distinct** [same flags, staged
copy], matching `reports/step2-variants.md:182-183`.

So a learner who does what line 212 asks gets 19, passes every requirement
and every pair, and is told at line 253 that their model has come apart from
the system and to go back to the rules. Nothing is wrong with their model.

Line 18 widens it rather than narrowing it. It offers PlusCal, and PlusCal
declares `pc` unless the algorithm has exactly one label. The reference is a
one-label `while (TRUE)` with four `either` arms, which is why its
translation's `vars` has four entries and no `pc`
(`reference/Laytime.tla:111`). A learner who writes the same four moves as
four labels reads above 11 for a reason that has nothing to do with the
rules. [INFERRED. I measured the extra-variable case and not the `pc` case.]

The two sentences also disagree with each other. Line 252 gives the
mechanism, that TLC counts over every variable you declare. Line 253 draws
the opposite conclusion from it. The mechanism is exactly why a correct model
can read differently.

The author got close and stopped one step short. `reports/step4-screens.md`
names the count as the piece they're least happy with, and says the
counts-over-every-variable sentence is there so a multi-label PlusCal learner
doesn't get "a count they can't explain and a wrong diagnosis". The sentence
explains the mechanism and the next one hands over the wrong diagnosis
anyway.

**Arrow: step 4, the prose.** A reword closes it. The count has to stay, and
`author-notes/step4-trace-map.md` says why: the opening is graded by nothing
else, so the 11 is what a learner has instead of a fourth requirement. What
has to go is the claim that any other number is a fault. Say what the 11 is a
count of, and say that a model carrying bookkeeping the four facts don't
determine will read higher without being wrong. The honest cost of that
reword is that such a learner loses the oracle, and I'd say so in the same
sentence.

## 8. Notes for central, not defects

**N1. The `Observe` names are the reference's variable names.** Section 2.
Upstream and declared, so it's a fact about the rung rather than this
statement. Every rung at representation 2 with an identity `Observe` will
land here again.

**N2. The two screens disagree on Q2.** Section 1. Neither crosses the
threshold and the KIND verdict is the same either way.

**N3. Requirement 1 is mostly ungradable against the reference.** Section 9.

## 9. The grading split

Per requirement, what counts as a property that carries it and what counts as
one that passes the shipped instance without carrying it.

**Requirement 1.** Carries it: four conjuncts subscripted over the whole of
`Observe`, saying that nothing but the notice moves before the notice is
tendered, that nothing moves after completion, that the notice is never
withdrawn, and that the completion is never undone. Passes without carrying
it: anything that drops the first conjunct. The reference has no action that
withdraws a notice, undoes a completion, or leaves a finished state, since
every disjunct but the tender guards on `~finished`
(`reference/Laytime.tla:119-137`). Five of the eleven states are terminal and
the run with deadlock checking on comes back `DEADLOCK` rc=11
(`reports/step4-screens.md`, verification block). So three of the four
conjuncts can't fail at this instance, and pair 1's forbidden run is the only
thing that separates a learner who wrote them from one who didn't. Grade
requirement 1 on the pair, not on the run.

**Requirement 2.** Carries it: three conjuncts, subscripted `_Observe`.
Passes without carrying it: the same formula subscripted on a single field.
Step 2's finding 5 measured rc=13 under `_Observe` and rc=0 under a
single-field subscript, on both action properties
(`reports/step4-screens.md`, constraint 2). The "never both" conjunct is the
weak one here. Nothing in the reference moves both counters in a step and no
pair shows one, so a learner who omits it scores the same as one who writes
it.

**Requirement 3.** Carries it: `demurrage > 0 => laytimeLeft = 0`, declared
under `INVARIANT`. Passes without carrying it: `demurrage <= Limit`, or
anything else `TypeOK` already implies. It holds on the reference, since
`TypeOK` is a declared invariant and the run is `OK` rc=0, and it admits pair
3's forbidden state, where the demurrage is 1 and the limit is 2. Pair 3 is
what separates them.

**Kind 3 fairness doesn't apply here.** The vector puts property kind at 2,
and `PROBLEM.md:195-198` tells the learner that a fairness conjunct is
modeling a different ship. A submission that carries one is wrong on the
statement's own terms rather than a judgment call.

Three rules on top:

1. **Grade the pairs, not the run.** Two of three requirements have conjuncts
   that can't fail against the reference at this instance.
2. **Extra state isn't an error.** A model reading above 11 that passes all
   three requirements and all three pairs is correct. D1 is why this needs
   saying to a panel before it reads the statement.
3. **An invented property is sound-and-extra or unsound.** Same split qsl
   proposed (`authoring/qsl/reports/step5-leakage.md` §0), and §3.5's
   reasoning carries over unchanged.

## 10. Verdict

**SHIP after D1.** Reword the checking paragraph at step 4 and the four files
are fit for a blind panel.

The boundary holds at four files with a clean sweep. The pairs carry targets
and no formulas, and each violating half isolates its own requirement. The
fields are stated as facts with their shapes pinned and no absent marker. The
vector row passes and its four citation slips are hygiene.

Both screens accept. KIND at two puzzle rows of eight, one of them the actor
count the rung pins at step sources 0 and no wording rescues. ROUTE on a
shortcut that narrows the representation and leaves the specification.

What I'd want carried past the verdict is that D1 and N1 point the same way.
The count says your variables are the four facts, and the field names say
which four. Neither is fatal here, and both will land again on every rung
that pairs representation 2 with an identity `Observe`. D1 closes with a
reword. N1 closes only in the reference, which means the next rung has to
decide it before the reference is frozen rather than after.
