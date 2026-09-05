# Step 6: the panel, and the spread read on the argument

Rung 7 of batch 2, bead `tla-h2cg.13`, shape A, form left open 1, property
kind 3. Read under V2-PLAN §6's rule: the argument, not the verdict. Panel
recorded per rule 5 (`V2-PLAN.md:1467`). Each seat's report is copied under
`reports/step6-panel/` so the record outlives the staging directory.

## The panel

| seat | model | properties | attempts | instruments |
|---|---|---|---|---|
| p1 | claude-fable-5-1 | 8, plus its own `TypeOK` | 1 model draft, 2 harness fixes, 1 reformat and re-run | 97-row produce/replay matrix over 16 forced runs, 9-row mutant table, narrow-subscript blindness shown in both directions, 5-way fairness sweep |
| p2 | claude-opus-5 | 8, plus its own `TypeOK` | 1, nothing revised | `Reach`/`Replay` harness of 178 modules and cfgs, 7 single-rule mutants, 2 narrow-subscript controls, 7-way fairness sweep, the 77 hand-counted before the run |
| p3 | claude-haiku-4-5 | 8, no type invariant | 2 syntax passes, then clean | 3 TLC runs on its own model, trace check written out in prose, no harness and no mutants |

One instance each, 2026-09-05, isolated directories holding the nine learner
files named at `step5-leakage.md` §5.

## Verdict: GREEN on the spread, and the statement owes one fix

The letter of rule 2's column-A reading points the other way, so I'll take that
first. All three seats wrote the same state: the identity over `standing`,
`notice` and `distributed`, one variable per `Observe` field. Nobody kept a
phase, a counter, or a partition. Three near-identical models, one attempt
each, and under the old reading that's the trivial-or-leaking flag.

I don't fire it, and the reason is that step 5's count of what was still open
overstates the room. `step5-leakage.md` §1 lists five live forks and offers a
partition of `Creditors` into named sets as one of them. That partition
computes `standing` and carries nothing else. Five re-encodings of the same
three facts aren't five representations, and at representation 2 the reference
itself holds no state past the interface (`EstateNotice.tla:4,14`). The
divergence available here was cosmetic. This is the fourth A rung at that level
to land on the structural discount (buyclub, laytime, and now this one, with
consign the exception because its ledger fork carried real information), and
each spread has re-argued it from scratch. I'd rather the rule carried it.

Where the spread did land is the rung's own graded axis, which is the outcome
the cell was built for. Requirement 4's subscript is the one decision the
statement withholds (`step4-trace-map.md:76-93`), and it got three answers at
three depths. p1 took `_(Observe.standing)` on every step rule, with the
reasoning stated at `p1/SOLVE.md:36-38` and a mutant proving the hazard runs
the other way: the same formula under the wrong field holds over 88 states
(`p1/mutants/results.txt`, `reopen/r5-narrow rc=0 distinct=88 holds`). p2 took
`_Observe` and earned it rather than copying it, with a constructed control at
`p2/SOLVE.md:97` showing `Req2Narrow` passing over the late-lodge mutant. p3
took the raw variable tuple and said nothing about subscripts at all.

Then the thing that makes the panel worth its cost. p2 read requirement 1's
wording and predicted the wrong formalization (`p2/SOLVE.md:105`). p3 wrote
that formalization (`p3/Estate.tla:60-61,90`). Same panel, blind seats, one
naming the trap and one walking into it. So this isn't three models that all
pass. p3's model distributes the residue while a claim sits admitted and
unpaid, and its own requirement 1 is bent the same way, so TLC reports rc=0 at
86 distinct states. Held against the reference's own requirement 1, that model
breaks in five states [`tlc -workers 1 -deadlock` over a staged copy of
`p3/Estate.tla` carrying `SheDistributesOnlyWhenClear`: `Invariant RefReq1 is
violated`, c1 at `"admitted"` when `distributed` goes true].

**Step 6 closes GREEN on the spread. The statement doesn't ship until D3
closes.**

## Instruments, split per rule 1

p2 built the deepest set. Two harnesses from one generator, `Reach<n><A|F>`
replaying each run against the real `Init` and `Next`, `Replay<n><A|F>` making
the run the whole behavior so only the requirements answer. Then seven mutants,
one broken rule each, and every requirement caught its own
(`p2/SOLVE.md:95`). The fairness sweep runs seven ways, including her set minus
each of its four conjuncts, and all four are caught (`p2/check/mutants.sh:40-44`).

p1's matrix is the same idea with the property named by TLC rather than by the
author, which is the better design for the forbidden half. Its produce rows
show seven of eight forbidden runs blocked by the model and pair 7's produced
in full, because pair 7's fault is the stall and not a bad step
(`p1/SOLVE.md:85`). Its fairness sweep is five ways and lands the same place p2
does on blanket `WF_vars(Next)`, which holds.

p3 ran TLC three times on its own model and wrote the trace argument out by
hand in `p3/verify_traces.txt`. Every line there is a claim of the form "caught
by ReqN", with no run behind it. That's (a) without (b) under rule 1, and it's
where the wrong requirement 1 survived: the paper argument reads its own
formula back to itself.

## Findings carried forward

1. **Requirement 1's phrasing lets a wrong model through, and pair 1 can't see
it.** Rule 7 at `PROBLEM.md:110-112` and requirement 1 at `:177-179` both say
"every claim lodged with her is either rejected or paid". Read "lodged" as the
standing rather than as brought-to-her, and the guard becomes `# "lodged"`,
which permits distributing over an admitted claim. Pair 1's forbidden run
leaves c1 at `"lodged"` (`step4-trace-map.md:19`, variant S01), so the bent
model blocks it and the bent property rejects it. The learner is told they
passed. **D3, and it blocks the ship.** The fix I'd take is to move pair 1's
offending step so it distributes with c1 at `"admitted"`. The tiling stays one
to one, and the produce direction catches the wrong model regardless of what
the learner wrote for requirement 1. Rewording alone leaves the oracle blind,
and prose is what the two seats read apart in the first place.

2. **No requirement forbids a step that changes two `Observe` fields at once,
and p1 is the only seat that noticed** (`p1/SOLVE.md:99`). A model that closes
the notice and lodges a claim in one motion passes all eight. Requirement 2
sees the notice open before the step and is satisfied, requirement 5 sees it
open and says nothing, and requirement 8 watches creditors against each other
rather than fields. The allowed runs don't catch it either, since they test
that the model can produce eight runs and never that it produces no more. I
think this is a real hole in the requirement set rather than a wording slip,
and it belongs in step 7 and in the grading split.

3. **The fairness has a third passing form the statement doesn't name.** p3
wrote one `WF` over the disjunction of her four kinds of step
(`p3/Estate.tla:82-86`). The statement warns about blanket fairness on the
whole next-state relation (`PROBLEM.md:233-238`), and `step5-leakage.md` §7
names blanket and the deleted-action case. Neither names this one, and it
passes for the same structural reason: her acts disable themselves for good and
`Creditors` is finite [the frozen reference with `WF_vars(HerSteps)` in place of
the four conjuncts, `tlc -workers 1`: no error, 138 generated, 77 distinct,
`TheEstateIsEventuallyDistributed` holds]. It's closer to right than blanket,
which makes it harder to catch by eye. The grading split should carry it as a
named tier.

4. **Requirement 4's subscript table needs a fourth row.** `step5-leakage.md`
§7 scores `_Observe` as correct with no evidence of the judgment, on the
grounds that six siblings read the same. p2 wrote `_Observe` and produced the
evidence anyway, by building the control that shows a narrow subscript going
blind (`p2/SOLVE.md:97`). The table reads the answer, and it should read the
argument. p1's `_(Observe.standing)` with its stated reasoning and p1's
88-state mutant are the same tier by a different route. Only p3's answer is the
copy case the table already covers, and p3 reached it without opening the
question.

5. **Step 5's live alternative on D1 was the right call.** §8 offered a choice:
withhold the subscript on all six action properties, or ship as written and let
the three-tier table read a copied answer out of the panel data. The panel data
reads it. Two seats opened the question unprompted and one didn't, and the
three answers separate cleanly. I wouldn't reword D1 now.

6. **Two small statement asks, and I'd take one of them.** p2 wants a sentence
saying the traces are prefixes rather than complete runs, because requirement 7
breaks on five of the eight allowed halves and that reads as a false alarm
(`p2/SOLVE.md:107`). Both p1 and p2 worked it out on their own, and p1 spent a
paragraph doing it (`p1/SOLVE.md:86`). Worth a sentence. p1 also wants the 77
arithmetic published, 25 open plus 36 closed plus 16 distributed
(`p1/SOLVE.md:101`), and p2 hand-counted the same three before running
(`p2/SOLVE.md:85`). That one collides with D2, which wants fewer numbers in the
statement and not more, and I'd hold with D2. A learner whose count is off has
77 to compare against already.

## Recognition

Asked last, per `V2-PLAN.md:1414-1415`. No seat reported a published problem, so
nothing is disqualified. All three named a mechanism and all three are recorded.
p1 named a claims window with a bar date at the first paragraph and said it
isn't a published TLA+ problem as far as it knows (`p1/SOLVE.md:105`). p2 named
it at rule 4 before writing anything, as an advertise-then-bar barrier, spelled
out the skeleton (one monotone flag, a standing that never goes backwards, a
terminal gate on all live items settled), and said what the recognition bought
and what it didn't (`p2/SOLVE.md:109`). p3 named the domain and called it "a
canonical finite-state protocol ... widely used in probate law"
(`p3/SOLVE.md:81`). That last one reads like a published-problem claim on a
skim and isn't one, since it names the legal practice rather than an exercise.
I read it as a domain naming and let the run stand.

## Rule 6

Not every seat was first-try clean in the sense that matters, so the automatic
human-review flag doesn't fire. p1 and p2 were clean on the first model run and
neither found a bug of its own. p3 was clean after two syntax passes and stayed
wrong. The telemetry that reads is the split between them: two seats built
instruments that would have caught the requirement 1 error and one wrote the
argument out by hand, and the hand argument is the one that missed. That's rule
1 doing its job on a rung where the answer column would have scored p3 at eight
of eight.

**Step 6 closes GREEN on the spread, with D3 open. Statement goes back for
pair 1 before step 7.**
