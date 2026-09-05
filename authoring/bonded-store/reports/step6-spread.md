# Step 6: the panel, and the spread read on the argument

## The panel

| seat | model | properties | attempts | instruments |
|---|---|---|---|---|
| p1 | claude-fable-5-1 | 3 | 1 formula attempt, 2 TLC runs | 10-run trace replay built by `check/mk-trace.sh`, each run checked against each property separately (30 runs), non-vacuity read off distinct-state count against trace length, one mutant for the subscript warning |
| p2 | claude-opus-5 | 3 | 1 | the same 30-run replay matrix through `INSTANCE Reqs` with a re-extract diff, 8 system-half mutants including a pristine control, an over-constraint control for the read of requirement 2 as an obligation, the subscript probe on `m6` |
| p3 | claude-haiku-4-5 | 3 | 2 | one green TLC run on the shipped spec, trace attribution written out by hand in `p3-verify_traces.md`, no per-property matrix and no mutant |

One instance each, 2026-09-05, isolated directories holding the seven learner
files by name.

## Verdict: GREEN, under the B-shape reading

Rule 2 for spec-in-hand shapes says property content converges by design, so
convergence is not the leak signal here. It converged hard. All three seats
shipped three properties, one invariant and two action properties, all three
green on the shipped spec at 145 states generated and 64 distinct
(`p1.md:42-44`, `p2.md:51-52`, `p3.md:42-46`), and all three reject all five
forbidden runs. Nobody wrote a weaker form of anything.

The discrimination lives where the cell says it should, in the kind decisions
and the instruments under them.

Requirement 2 came back in three materially different encodings. p1 wrote two
guarded implications whose antecedents each require the lot's own place to
change, so standing still is permitted by the shape of the antecedent
(`p1.md:10-16`). p2 wrote successor sets that name the stutter in the
consequent, and said in a comment why the arm has to permit it
(`p2.md:17-25`). p3 wrote a top-level disjunction with `place[l] = place'[l]`
as its own arm and no restriction on the pre-state, which makes its
requirement 2 strictly stronger than the rule asks: it also freezes the place
of a released or moved-on lot, doing part of requirement 3's work
(`p3.md:14-19`). Three seats, three readings of one rule, all sound on the
oracle. That is the modeling choice the statement leaves open, and it did open.

The instruments spread further than the kinds. p2 built eight mutants of the
system half and ran each against each property alone, with `m0-pristine` as the
control that says the scaffolding can go green rather than only red
(`p2.md:65-71`). p1 built a ten-run replay harness and checked every run against
every property, so its table reports every property a run breaks rather than
the first one TLC hits (`p1.md:48-55`). p3 ran TLC once and wrote its
attributions out by reading (`p3.md:42-46` against `verify_traces.md`). Under
the split in rule 1, all three reached the conclusions and two of three built a
check that establishes them.

Not all-fail, so requirement 3 of the spread rule doesn't fire. Not identical
with the same instruments, so it isn't signposted. Converged on content,
divergent in kinds and instruments, which is the target.

## The pair 5 attribution, checked

p3 attributes pair 5's rejection to `OutStaysOut`, its requirement 3
(`p3.md:70-73`). That's wrong, and the way it's wrong is worth the space.

`OutStaysOut` guards on the pre-state place being released or moved on. Pair
5's forbidden run has three states, and the step that does the damage takes l1
from in store to moved on and pays its duty in the same step
(`statement/traces/pair-5.md`, forbidden block). At that step the pre-state
place is `inStore`, so the guard never arms. What rejects the run is
requirement 1, at state 3, where l1 is moved on with duty paid.

I replayed p3's own three formulas against that run, transcribed over `Observe`
and checked one property per run. `DutyPaidIffReleased` rc=12, "Invariant
DutyPaidIffReleased is violated", 3 distinct states.
`TheWayInAndTwoWaysOut` rc=0. `OutStaysOut` rc=0, "No error has been found", 3
distinct states, so the run was walked and not skipped. p1's matrix reports the
same split from a separate harness, R1 rc=12 with R2 and R3 both 0
(`p1.md:67`), and so does p2's (`p2.md:63`). Three independent readings agree
against p3's.

The source of p3's error is visible in its working file, kept here as
`step6-panel/p3-verify_traces.md`. It describes pair 5 as a step from
`place="movedOn"` to `place'="movedOn"` with duty going from unpaid to paid,
which is a four-state run that isn't in the file
(`p3-verify_traces.md:51-53`). p3 split one compound step into two.
`PROBLEM.md:148-149` already names
pair 5 as one of requirement 1's two pairs, so the statement says out loud what
p3 read past.

p3's property set is still right about the run, because its requirement 1
rejects it and `PROBLEM.md:146-147` licenses exactly that. The answer stands.
The argument for it doesn't.

The same seat reports pair 4 as rejected by `OutStaysOut` alone
(`p3.md:65-68`). Both of its action properties reject it: replaying pair 4's
forbidden run against p3's formulas gives `TheWayInAndTwoWaysOut` rc=13 and
`OutStaysOut` rc=13. Two attribution errors in the same direction say p3 read
the pairs rather than running them, which is what its instruments column
already says.

## Findings carried forward

**1. Pair 5's compound step is the price of choosing S03, and one seat in three
paid it.** Step 5 preferred S03 over S01 because every step of it changes
`place`, so it reads as a keeper's mistake in an ordinary run
(`step5-leakage.md` §7). The cost is that the offending step does two things at
once, moving the lot on and paying its duty, and a reader can take that as two
steps with the payment landing after the move. p3 did. I don't think this asks
for a rewrite, since the pair does the job it was added for and p1 and p2 both
read it correctly. I'd record it as a known misread and let step 7 decide
whether the grader wants a written attribution at all.

**2. The strength gap the grading split predicted didn't appear.** Section 5 of
the step 5 report named three things no pair can grade: requirement 1's second
direction before pair 5 landed, requirement 3's duty clause, and the `place`
subscript. All three seats wrote the full biconditional, both clauses of
requirement 3, and subscripted over the whole of `Observe`. The ungradable
residue didn't bite at rung 1. My read is that `PROBLEM.md:100-140` labels the
kind, the shape and the subscript outright, so there was less room to weaken
than the split assumed, which is the same thing the step 5 screen flagged at
Q2. Three seats is thin evidence and I'd hold the split as written rather than
loosen it on this.

**3. The subscript warning is now measured rather than argued.** p1 and p2 each
built the mutant the warning describes, independently and by different routes.
p1's `MutUnpay` un-pays a released lot with place unchanged, and
`[][OutStaysOut]_place` passes it at rc=0 where `[][OutStaysOut]_Observe`
returns 13 (`p1.md:72-76`). p2's `m6` pays a moved-on lot later with place
unchanged, and `[][OutStaysOut]_(Observe.place)` returns 0 where the whole-record
subscript returns 13 (`p2.md:72-74`). Step 5 argued for keeping the warning on
the grounds that no pair can replace it. Two of three seats confirmed the hazard
is real by construction, and the argument for keeping it is stronger for it.

**4. Requirement 2 reads as an obligation to move, and the statement never says
otherwise.** p2 named this as the trap it expected and built the control:
`work/naive-req2/` holds the reading where a not-yet-entered lot must move, and
against the shipped spec it comes back rc=13 because one lot sits still while
another acts (`p2.md:80-83`). The subscript warning at `PROBLEM.md:124-127`
points at the neighbouring hazard, not this one. So the mistake costs a run
rather than a wrong answer, which is the healthy kind. I'd still take one
sentence in the statement saying each arm has to permit the lot to stand still,
because the grading split should know whether it's grading a trap the learner's
own run catches or one it doesn't.

**5. The interface sentence needs a ruling on text against meaning.**
`PROBLEM.md:94` says to state every property over `Observe`, and that grading
reads `Observe` and nothing else. p1 and p2 wrote every predicate over
`Observe.place` and `Observe.dutyPaid`. p3 wrote its predicates over the bare
`place` and `dutyPaid` variables and put only the subscript over `Observe`
(`p3.md:9`, `:14-19`, `:24-28`). Here the two are the same thing, because
`Observe == [place |-> place, dutyPaid |-> dutyPaid]`, so nothing p3 wrote is
unsound. Whether the sentence is a contract on the text or on the meaning is a
grader decision, and I'd rather step 7 make it than the first grader who meets
a submission like p3's.

**6. Three statement observations from p2, worth absorbing at whatever step
owns them.** `Places` is defined in the module and used by nothing, which
invites `place[l] \in Places` as a fourth property nobody asked for
(`p2.md:102-103`), and that repeats note N1 from step 5. The block labelled the
translation carries no `pc` variable, so it isn't what PlusCal emits for a
`while (TRUE)` under a label, while the `chksum` comment still says it is
(`p2.md:105-107`). The traces write "not entered" and "in store" and "moved on"
where the module writes `notEntered`, `inStore` and `movedOn`, and nothing
states that mapping (`p2.md:110-111`). p1 raised the same class of gap on
requirement 2's undefined "moves", and showed both readings give the same
verdicts on the traces (`p1.md:101-104`).

## Recognition

No seat recognized a published problem, so no run is disqualified. All three
recognized the mechanism and reported it, which is measurement rather than
disqualification.

p1 named a per-item one-way lifecycle on the first read of `PROBLEM.md`, around
rule 5, with one entry state, one middle state, two absorbing terminals and a
flag pinned to which terminal was reached (`p1.md:114-118`). p2 named a
per-entity one-way status ledger, also reading rule 5 and before opening the
module, and said outright that the customs framing, `Observe` as the graded
interface and this three-requirement split are not something it had seen
(`p2.md:116-119`). p3 named the domain, a customs bonded warehouse, from the
words "bonded store", "duty" and "lot", and the same one-way ledger under it
(`p3.md:97-102`).

Naming the domain isn't a leak here. The domain is the statement's own subject
and it's on the first page. What matters for the confound is that all three
seats arrived at the same skeleton before writing anything, so no seat was
working from a different starting position than its neighbours.

## Rule 6

Not a first-try clean solve from every seat. p3 took two attempts, the first
declaring bare action predicates under `PROPERTY` without the temporal wrapper,
which TLC caught with a message p3 says named the problem (`p3.md:76-81`). p1's
two TLC runs were one formula attempt: its first run failed rc=151 because the
property block sat outside the module's closing line, and no formula changed
between the runs (`p1.md:80-87`). p2 was one attempt (`p2.md:78`).

So the flag reads against instruments the way qsl's did, and it reads the same
way: two of three built real ones. Recorded, not fired.

**Step 6 closes GREEN.** The statement stands. Step 7 next, carrying findings 1,
4 and 5 as decisions it has to make rather than notes it can file.
