# Step 6: the panel, and the spread read on the argument

Rung 2 of batch 2, bead `tla-h2cg.8`, shape A. Read under §6's rule: the
argument, not the verdict. Panel recorded per rule 5. Each seat's report is
copied under `step6-panel/` so the record outlives the staging directory.

## The panel

| seat | model | attempts to clean | state representation | instruments |
|---|---|---|---|---|
| p1 | claude-fable-5-1 | 1 | four variables, one per `Observe` field, kind quantified inside the step | replay-and-produce harness over all six runs, nine single-defect mutants each run against each requirement alone, a producibility control, a 16-instance sweep |
| p2 | claude-opus-5 | 1 | four variables, one per `Observe` field, kind quantified inside the step | `TraceCheck.tla` reaching the delivered text by `INSTANCE`, a mutant battery, a ghost kind log, `StrictCap.tla` as the rival Rule 9 reading, a 16-instance sweep |
| p3 | claude-haiku-4-5 | 3 | four variables carrying the reference's own names, no kind anywhere | one green TLC run, trace attribution written out by hand |

One instance each, 2026-09-05, isolated directories holding the four learner
files by name.

## Verdict: GREEN, and the step 5 prediction lands

The statement ships. The rung's shape-A discrimination is thinner than the
cell wants, and step 5 said in advance why, so the arrow points at the
reference rather than at the prose.

Take the bad news first, because the column-A reading asks for it. **There is
no state-representation spread at all.** All three seats declared four
variables, one per `Observe` field. p3 used the reference's four names
outright (`p3.md:12`). p1 and p2 renamed to `notice, left, dem, done` and
`notice, left, dem, closed` (`p1.md:11`, `p2.md:12`), which is a rename and
not a different state. `DESCRIPTION.md` §3 names the one fork this rung was
built to open, whether the latch gets its own field, and step 5 §3 left the
graded half of it open: does the learner carry the latch, or read it off
`laytimeLeft = 0`. Three families of three all read it off. Nobody kept a
phase variable, a period counter, or a kind.

The state graph converged with it. All three land on 11 distinct states at
depth 7, the number `PROBLEM.md:251` predicts. p1 at 19 generated, p3 at 11,
the frozen reference at 15 [`tlc -workers 1 -deadlock`, three runs against
staged copies at `Allowance = 2, Limit = 2`]. The generated counts differ only
by how many `Observe` stutters each model carries as its own disjunct.

Under rule 2's column-A reading that's the trivial-or-leaking signal, and I
don't think sending it back to step 4 does anything. Step 5 measured the cause
and ruled that a reword can't close it. `PROBLEM.md:150-153` has to fix the
four field names because grading compares them, and the reference declares
`Observe` as the identity over its own four variables, so naming your
variables after the fields lands you on the reference's state
(`step5-leakage.md` §2, N1). The 11-state sentence narrows it further. The
panel is the measurement step 5 asked for rather than a new finding, and N1's
own arrow already points upstream: it closes in a reference, before the
freeze, not in this statement.

What did spread is everything above the state. Two of three seats model the
period's kind as a step parameter and quantify over it, so Rules 5 and 8 are
in the model and unwatched by design (`p1.md:22-29`, `p2.md:29-37`). p3
models no kind at all, and its two logging actions are "a working period under
laytime" and "any period on demurrage" (`p3.md:32-45`). `PROBLEM.md:212` tells
the learner to model Rule 8 whole. p3 didn't, and nothing in the delivery
notices, because an excepted period under laytime is an `Observe` stutter.
That's finding 3 below.

Property strength spread further, and in the direction step 5 §9 predicted.
Instruments spread furthest: two of three built real ones, which is where the
last four rungs also landed.

## Requirement 1, and the conjuncts nobody can grade

This is the sharpest result on the rung, so it gets its own section.

Step 5 §9 said requirement 1 has four conjuncts, that three of them can't fail
against the reference at this instance, and that pair 1's forbidden run is all
that separates a learner who wrote them from one who didn't. It ruled: grade
requirement 1 on the pair, not on the run. p3 shows the ruling isn't enough.

p3's `Req1Action` carries the untendered clause and a second clause keyed on
the post-state, `finished' = TRUE => nothing else moved` (`p3.md:58-64`).
Read the antecedents. A step that withdraws the notice from a tendered,
unfinished state fails the first antecedent (the notice is `TRUE` before) and
fails the second (`finished'` stays `FALSE`). A step that un-finishes a closed
statement fails both the same way. So p3's requirement 1 permits both, and the
statement asks for neither at `PROBLEM.md:178`.

I built the two mutants and ran each requirement alone against each. p3's
`Req1` comes back rc=0 on a spec that withdraws the notice and rc=0 on a spec
that reopens a closed statement. The reference's form comes back rc=13 on
both, reporting `Action property RefReq1 is violated`
[`tlc -workers 1 -deadlock`, four runs, `Allowance = 2, Limit = 2`]. p3 still
passes pair 1, because pair 1 grades the one conjunct p3 kept.

p1 and p2 both wrote `Observe.noticeTendered => Observe'.noticeTendered` and
`Observe.finished => Observe' = Observe` (`p1.md:38-39`, `p2.md:43-44`). p1
measured its own set against the same class of mutant and reports requirement
1 alone catching withdraw, reopen, log-after-close and close-early at rc=13
each (`p1.md:80`). So the gap is p3's and not the rung's.

Two of three wrote the full requirement. One wrote the half the delivery can
see. That's a strength gap of the exact shape step 5 named, and unlike
bonded-store's rung the prediction held here.

## Findings carried forward

**1. Rule 9 at a limit of zero. Two seats found it, and the reference is on
the losing side.** `PROBLEM.md:121-123` says that once the accrued demurrage
reaches the cap there's nothing further to record, so the agent logs no more
periods. Read as written, that fires at the opening when `Limit = 0` and
freezes the laytime drawdown, which the rule's own stated reason contradicts.
`PROBLEM.md:172` puts zero in scope by saying the requirements hold for any
whole-period `Limit`. p1 found it through its instance sweep and took the
reason over the letter, moving its guard to `left > 0 \/ dem < Limit`
(`p1.md:89-93`). p2 found it before its first run and made the same call, then
built `StrictCap.tla` as the rival reading and swept both over
`Allowance, Limit \in 0..3` (`p2.md:97-100`). The frozen reference takes the
letter: its logging guard is `demurrage < Limit`
(`reference/Laytime.tla:122,129`). I ran the reference at
`Allowance = 3, Limit = 0` and it finds 3 distinct states, the allowance never
falling. p1's spec at the same instance finds 9
[`tlc -workers 1 -deadlock`, two runs]. Both readings satisfy all three
requirements at every instance p2 swept, and at the checking instance both
give 11 states, so nothing in the delivery can tell them apart. I'd have step
4 add a sentence saying which reading Rule 9 means. My own read is that the
seats are right and the reference is wrong, but the reference is frozen and
the requirements don't care, so the cheap fix is the prose.

**2. Requirement 1's ungradable conjuncts bit, and the pair doesn't cover
them.** Section above. Step 5 §9's ruling covers the first conjunct and
nothing else, because pair 1 is the only artifact that grades any of them. I
think the grader needs a fourth thing here, either a seeded mutant that
withdraws the notice or an explicit rule that requirement 1 scores per
conjunct. The trace map already forbids seeding on Rule 8's second half
(`author-notes/step4-trace-map.md:81-84`) and says nothing about seeding on
requirement 1, so the mutant route looks open. Whichever way step 7 goes, a
submission that drops three of four conjuncts shouldn't score the same as one
that writes them.

**3. `PROBLEM.md:212` asks for Rule 8 whole and has no teeth.** p3's model
carries no notion of a period's kind, so an excepted period under laytime
doesn't exist in it at all (`p3.md:32-45`). p1 and p2 both modelled the kind
and both built a witness that it's unwatched: p1's `MutFreeRain` drops Rule
8's second half and stays green on all three requirements at 11 states
(`p1.md:84-85`), and p2's `Kindwitness.tla` carries a ghost log and exhibits
two runs reaching the same `Observe` state that differ only in the ghost
(`p2.md:104-108`). The statement is honest about this at 207-213. What the
panel adds is that the instruction to model it anyway is unenforceable, and
one seat in three quietly skipped it with no cost. I'd rather the statement
said the second half is on the learner's honor than left an instruction the
delivery can't back.

**4. The forbidden subscript form showed up, and it was harmless here.** p3
declared requirement 2 as `[][OneMoveAction]_<<laytimeLeft, demurrage>>`
(`p3.md:71`), against the paragraph at `PROBLEM.md:201-205` and the per
requirement line at 187-188. It also wrote every requirement over the bare
variables rather than over `Observe`, against `PROBLEM.md:166`. Neither costs
p3 anything. The narrow subscript exempts steps that leave both counters
standing, and `OneMoveAction` is true for free on those steps, so the two
subscripts agree on every behavior. I checked both against a draws-two mutant
(rc=13 and rc=13) and against a mutant that withdraws the notice while closing
(rc=0 and rc=0) [`tlc -workers 1 -deadlock`, four runs]. And `Observe` is the
identity over p3's four variables, so the bare-variable predicates mean the
same thing. That leaves a grader decision on whether those two sentences are
contracts on the text or on the meaning. bonded-store's step 6 asked for the
same ruling from the other direction, so I'd take it once and apply it to both
rungs.

**5. The D1 reword landed and nothing tested it.** `PROBLEM.md:251-255` now
says a model carrying more state will count higher without being wrong. All
three seats hit 11 on the first run, so no seat was in a position to be
misdirected by the old wording or reassured by the new. The reword is
untested rather than validated, and I'd note it that way rather than count it
as evidence.

**6. No allowed run exercises a close, an excepted period, or the cap**
(`p1.md:109-110`). Nothing in the three pairs checks that the closing step is
producible, and the 11-state count is the only artifact in the delivery that
speaks to it. That's the flip side of the trace map's decision to leave the
opening ungraded. Worth a look at step 7, though I don't think it needs a
fourth pair.

## Recognition

No seat recognized a published problem, so no run is disqualified. All three
named the mechanism, which is measurement.

p1 named it first, on the first read of Rules 6 to 9 and before writing
anything: a budget drained a step at a time, then a monotone counter behind a
one-way switch, capped, with a terminal close (`p1.md:113-116`). It says the
recognition changed nothing beyond picking four variables and no more, which
is worth holding next to the zero representation spread. p2 named it late,
while writing requirement 3, as a one-way budget-then-meter (`p2.md:117-119`).
p3 named it as lease expiration with a two-phase payment model and reached for
real families, maritime chartering, construction, equipment rental
(`p3.md:123-125`).

Naming the domain isn't a leak here. `PROBLEM.md:31-36` is a shipping lesson
on its first page. What matters for the confound is that all three arrived at
the same skeleton, and p1's remark suggests the skeleton is where the four
variables came from.

## Rule 6

Not a first-try clean solve from every seat, so the flag doesn't fire on its
own terms. p3 took three attempts, all three caught by TLC: bracket syntax
inside a formula, a requirement 1 too restrictive to admit legal steps, and
requirement 3 declared as a temporal formula (`p3.md:113-116`). p1 was clean
on the first TLC run and revised once mid-way for a bug TLC never saw, found
by its own instance sweep (`p1.md:88-93`). p2 was clean on the first run with
nothing revised for correctness (`p2.md:93-94`).

The reading that matters is the same one qsl and bonded-store used. Two of
three built real instruments, one read the traces by hand. Recorded, not
fired.

**Step 6 closes GREEN.** The statement stands. Step 7 next, carrying findings
1, 2 and 4 as decisions it has to make rather than notes it can file.
