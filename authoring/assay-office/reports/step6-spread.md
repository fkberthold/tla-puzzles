# Step 6: the panel, and the spread read on the argument

## The panel

| seat | model | properties | attempts | instruments |
|---|---|---|---|---|
| p1 | claude-fable-5-1 | 3 | 1 | 14 trace cfgs through an `INSTANCE` harness, 5 single-edit mutants covering every conjunct, the no-fairness control, a narrow-subscript negative control, a no-WF harness control |
| p2 | claude-opus-5 | 3 | 1 | 36 trace runs, one property per cfg, 3 mutants with an isolation argument, the no-fairness control, the subscript trap sprung against a mutant, `WeakFair.tla` refuting its own claim |
| p3 | claude-haiku-4-5 | 3 | 1 | a Python trace parser. No TLC on any run, no mutant, no control |

One instance each, 2026-09-05, isolated directories holding the eight
learner files.

## Verdict: GREEN, under the B-shape reading

Rule 2 for spec-in-hand shapes says property content converges by design,
so the convergence here isn't a leak. It converged hard. All three seats
wrote the same three formulas over the same three `Observe` fields, all
three declared `INVARIANT` plus two `PROPERTY` lines, all three named
`SPECIFICATION FairSpec`, and all three subscripted requirement 2 over the
whole of `Observe`. Three of those four are form 0's hand-over, and the
subscript is the instruction at `PROBLEM.md:145-148`. Step 5 said the
subscript wasn't gradable on this rung and the panel bears that out.

The discrimination landed in the two places left open. The first is the
liveness form, where p3 wrote an implication under `<>` with no leading
always and I measured that it catches nothing on this model. The second is
the instruments, where the gap between the seats is the widest this
pipeline has recorded. p1 built 14 trace cfgs plus five mutants
(`p1.md:55-61,81-85`), p2 built 36 trace runs plus three mutants and then
used one to refute a claim it had already written down
(`p2.md:46-71,95-106`), and p3 ran a Python parser over the trace files and
nothing else (`p3.md:47`).

I think those two are one event rather than two. The seat with no run on
the traces is the seat whose liveness property is wrong, and it reported
the property as correct because the parser gave it the English reading.

## The liveness form at p3, measured

`Prop3` reads `\A w : (Observe.finding[w] = "substandard") => <>(Observe.defaced[w])`
(`p3.md:17`). A temporal formula with no leading `[]` binds at the opening
state alone. `Init` writes every finding as `"none"`, so the antecedent is
false there for every ware, and the implication holds for free on every
behavior of the shipped spec.

Three runs, all `tlc -workers 1`, TLC2 Version 2026.07.31.184830.

- p3's three properties under `SPECIFICATION Spec`: rc=0, 601 generated,
  125 distinct, "No error has been found".
- p3's properties against pair 3's forbidden run: rc=0, 6 states, no error.
- A one-state probe run opening with w1 substandard and whole: rc=13,
  "Temporal property Discharged was violated".

The first two are the failures that matter. The reference set and both
other seats get rc=13 on the no-fairness control (`p1.md:41-44`,
`p2.md:63`), and p1's correct property fails pair 3's forbidden run at
rc=13 through the same harness and the same cfg I used
(`p1/tracelogs/tc-3f.log:31`). So the harness can fail and the cfg is not
the difference. The third run is the locator. The property isn't dead, it
just never gets asked, and moving the antecedent into an always would fix
it in one character group.

For the rest of the trace set p3 is clean. It rejects pairs 1, 2, 4, 5 and
6 at rc=12, 13, 12, 13 and 13, and accepts all six allowed runs at rc=0.
Pair 3 is the only miss, and `p3.md:42` claims that run violates `Prop3`.
That claim is false, and it came out of the channel with no checker in it.

I'd weigh it as the rung working rather than the rung failing. The cell
was built to separate seats on the liveness form and it separated them.
The cost is that nothing the learner is given catches the miss, which is
the finding below.

## Findings carried forward

**1. The grading split's requirement 3 row overstates what pair 3 covers.**
Step 5 wrote that pair 3's forbidden run covers requirement 3 in full
(`step5-leakage.md`, section 5). Measured, it covers requirement 3 for a
formula that binds at every state, and says nothing about one that binds
at the opening. A learner who writes p3's form passes TLC on the shipped
spec at rc=0, passes five of six pair hand-checks, and gets no signal at
all on the sixth unless they run it. I'd add a shape row to the grading
split rather than a seventh pair. The row is cheap and it covers the
family, and a bare `<>` is only one member of it. The pair would work, and
my probe measured that it works, but a forbidden run opening with a
finding already written reads as a legal state of the office. Pair 1's
opening is visibly wrong and this one wouldn't be, so I suspect it would
cost more confusion than it buys.

**2. Neither quantifier in the fairness conjunct is load-bearing, and the
statement points at both.** Step 5 filed the officer half as N2. p1 reached
it independently and called the officer index decorative (`p1.md:102-105`).
p2 reached the same place, then wrote down that the ware quantifier _was_
load-bearing, built `WeakFair.tla` to prove it, and got refuted at rc=0
over 125 distinct states (`p2.md:95-106`). Defacing is one-shot per ware
and `Wares` is finite, so the coarse conjunct forces the same behaviors.
`PROBLEM.md:162` sends the learner to read what the obligation is
quantified over, and the honest answer is now "nothing that does any work".
That's a reference finding rather than a statement defect, and it belongs
on the record before somebody re-derives it a third time.

**3. Two seats asked for a stated convention on what follows a finite
run.** p2 said requirement 3 can't be pinned by a trace until you know what
comes after the last state, and that `PROBLEM.md` says so for pair 3's
forbidden run alone (`p2.md:108-112`). p1 reached it from the other
direction by building `tc-3a-nowf`, which drops WF from its replay harness
and turns three allowed runs into false rejections (`p1.md:65-72`). p2 hit
the same bug for real before catching it (`p2.md:75-82`). qsl's step 6
carried this as its finding 2 on a different problem, so that's two rungs
asking for the same sentence. I'd write it into `PROBLEM.md`'s trace
section.

**4. The trace map's "breaks its own requirement alone" claims don't hold
for pairs 2 and 6.** p2 ran one property per cfg and recorded requirement 3
firing on both (`p2.md:48-54`). Both runs end on a substandard finding that
was never defaced, so under the stutter-forever reading they fail the
discharge rule as well. p1 didn't see it, because TLC names the first
violation and exits, and p1 ran all three properties in one cfg
(`p1/tracelogs/tc-2f.log:29`, `tc-6f.log:29`, both naming
`RecordOnlyGrows`). That's an instrument-design difference producing a
measurement difference, which is what rule 1 is for.
`author-notes/step4-trace-map.md:134-136,145-147` should be corrected.

**5. Requirement 1's third sentence divided the seats and both readings are
right.** p1 wrote the redundant `~(marked /\ defaced)` conjunct and said in
the same breath that it follows from the two above it (`p1.md:33-34`). p2
left it out with the argument for why (`p2.md:23-25`). The grader should
take either. Step 5's D1, the `marked`-clause-only weakening, is closed by
pair 4 and no seat went near it.

**6. TLC's liveness line prints a number the statement doesn't publish.**
p1 flagged that the run prints "375 total distinct states" before the
summary's 125, being 125 states across three property branches
(`p1.md:105-107`). My own runs print the same line. `PROBLEM.md:200`
publishes 125 as the tamper check, so a learner reading top to bottom meets
the wrong number first. One clause in that line would settle it.

## Recognition

No seat recognized a published problem. All three named the mechanism, and
each named it before or during property design rather than after. p1 called
it a write-once record with monotone flags and one liveness obligation
discharged by weak fairness (`p1.md:111-115`). p2 called it a monotone
per-item record with the standard stability and discharge obligations over
it (`p2.md:114-119`). p3 called it fairness-driven liveness over persistent
state (`p3.md:63`). Recorded, and no run is disqualified.

## Rule 6

All three first-try clean on the shipped spec, which on this shape says
little on its own. The flag reads against the instruments, and there it
fires for one seat. p1 and p2 built checks that could have failed and
watched them fail. p3 built none, and the one property it got wrong is the
one no parser could have told it about.

**Step 6 closes GREEN.** Statement stands. One row to the grading split,
one sentence to `PROBLEM.md`'s trace section, and a correction to the trace
map. Step 7 next.
