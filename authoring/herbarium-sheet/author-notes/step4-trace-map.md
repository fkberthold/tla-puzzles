# herbarium-sheet step 4, the author-only trace map

Never ships to a learner or to a blind agent. It maps each pair under
`authoring/herbarium-sheet/statement/traces/` to the frozen reference obligation
it witnesses, with the provenance of both halves. Bead `tla-h2cg.12`, rung 6 of
batch 2, shape D at form left open 1.

The learner-visible artifact set is exactly `statement/PROBLEM.md` and the seven
files under `statement/traces/`. No model ships, so there's no learner copy of
the spec, and the shape D object is a formula that sits inside `PROBLEM.md`
rather than a file of its own. Nothing in this file or under `reports/` is
reachable from that set.

## The map

Pair N witnesses requirement N of the statement. The statement's numbering is
`DESCRIPTION.md` section 2's numbering unchanged.

| pair | obligation | variant | rc | violating trace | satisfying half |
|---|---|---|---|---|---|
| 1 | `RecordWellFormed` | S05 | 12 | 2 states | A1, rc=12, 4 states |
| 2 | `AcceptedIsTopSlip` | S08 | 12 | 3 states | A2, rc=12, 5 states |
| 3 | `RecordOnlyGrows` | S13 | 13 | 2 states | A3, rc=12, 3 states |
| 4 | `SlipComesFromAConsultation` | S16 | 13 | 3 states | A4, rc=12, 3 states |
| 5 | `DoubtClearsOnlyOnFiling` | S19 | 13 | 4 states | A5, rc=12, 4 states |
| 6 | `ConsultationIsAnswered` | S22 | 13 | 7 states, then stuttering | A6, rc=12, 5 states |
| 7 | `Opening` | S03 | 13 | initial state | A7, rc=12, 2 states |

`TypeOK` gets no pair. It's the reference author's own typing, declared in the
cfg, and it was never one of the seven stated requirements. The statement says
the learner may declare one of their own and that it doesn't count against the
list of seven.

## Provenance, violating halves

The picks are the step 2 report's section 6 shortlist, taken unchanged. The
frozen modules under `reports/step2-variants/` were copied to a scratch tree and
run there, and nothing under `reports/` was edited.

Each ran through `harness/verdict.sh -t 300` against the frozen `variant.cfg`,
with `-workers 1`. All seven came back on the rc and the obligation section 3's
results table records. The traces in the pair files are parsed straight out of
those runs rather than transcribed, so no state was retyped by hand.

One count differs from step 2, and it's arithmetic rather than a different
trace. Step 2 records S22 at 8 states then stuttering. My run prints seven
states and then `State 8: Stuttering`, so the eighth is the stutter and not an
eighth step. The pair-6 file renders the seven and says under the last one that
nothing more ever happens, which is the honest reading of either count.

`Opening` still arrives as a source location rather than a name, which is step
2's finding 3. S03 reports `Property line 97, col 14 to line 97, col 37 of
module S03 is violated by the initial state`, and line 97 is
`/\ Observe.consulted[s] = 0`. That's the third reading of the same TLC
behaviour across three problems, so I'd now treat it as how TLC handles a
`PROPERTIES` state predicate rather than as a quirk.

## Provenance, satisfying halves

Each satisfying half mirrors its violating twin: the same opening, the same
botanists moving, and the lawful outcome where the twin has the unlawful one.
Pair 3's twin bumps a sheet's count without handing anybody the stamp, so the
mirror hands it over and then hands the next one to the other botanist. Pair 4's
twin closes a consultation with nothing filed, so the mirror files. Pair 6's
twin leaves two consultations open forever, so the mirror answers both.

Then machine-validated against the frozen reference by a trace-forcing scratch
module, `A1` to `A7`. Each extends the reference, forces the exact `Observe`
sequence, conjoins `Init` at the opening and `Next` on every step, and carries
an invariant that's false only once the whole sequence has been walked. So rc=12
means the run is a real behaviour of the reference, and rc=0 means some step of
it isn't a `Next` step. Seven of seven came back rc=12 at the full length, and
A2's counterexample shows the step counter reaching 5, its own length.

The validator can fail. A control trace, `WC`, puts a slip on a sheet in the
same step that first raises the count, with nobody holding a consultation, and
comes back rc=0 with no counterexample at all. Without that control the seven
passes would only say the module compiled.

Two things to know if these are ever regenerated. The botanist and name model
values can't be written into a module that only sees them through
`Botanists = {b1, b2}` in the cfg, because a model value isn't an operator. The
validator declares `CONSTANTS b1, b2, n1, n2` and the cfg assigns each to
itself, the same trick the reference uses for `None`.

And the generator that writes the validators is not the renderer that writes the
pairs. Importing one from the other put sixteen validator files straight into
`statement/traces/`, where they'd have shipped a working copy of the reference to
the learner. The boundary grep didn't catch it either, because a `.tla` file
carrying no forbidden word reads clean. What caught it was reading the staged file
list before committing. Keep the two steps apart, and read what you staged.

Traces render the five `Observe` fields and nothing else. No action name, no
formula, no obligation name, and the variants' own action names (`Cancel`) never
appear.

## Requirement 1's distinctness clause has no isolating trace, and pair 1 says so

Step 2's finding 2 measured this and I'm carrying it forward rather than
working around it. Requirement 1 has four clauses, and nothing in the frozen
matrix reaches a state with two slips on one sheet at the same stamp. S07 was
authored for it and gets caught two steps earlier by
`SlipComesFromAConsultation` instead.

So pair 1 witnesses the range clause: S05 hands a botanist the stamp
`Handling[s]` on a consultation that only brought the count to 1, and the
reading sits outside `1..consulted`. A learner whose requirement 1 covers the
range and the allowance but not distinctness passes pair 1. The mutation that
would isolate distinctness is step 2's prediction and nobody has run it.

That's a gap in the oracle rather than in the property set, and I'd rather the
grader knew than have it read pair 1 as covering the whole requirement.

## The withheld subscript, and why requirement 3 carries it

Form left open 1 wants one action property's subscript in the learner's hands.
Three requirements are action properties here. Requirement 5 can't be the one,
because it's the shape D object and ships with its subscript already chosen.
That leaves requirements 3 and 4, and the pick is 3.

Step 2's finding 5 is why. It measured the wrong-subscript move on both.
`RecordOnlyGrows` under `_(Observe.consulted)` goes blind to every filing, and
P03S11 then passes the whole set at rc=0 over 245 distinct states with a filing
that replaces the sheet's slips. Nothing else notices. `SlipComesFromAConsultation`
under `_(Observe.slips)` does go blind to a cancelled consultation, and P02S16
was caught anyway at rc=13 by `ConsultationIsAnswered`, over a sheet whose
allowance is spent and whose mark nobody can ever take off.

So requirement 3 is the one place on this problem where a wrong subscript is
graded by the property it belongs to. Withholding requirement 4's subscript
would withhold a decision the cfg doesn't measure. That's the same reasoning
estate-notice used at its requirement 4, and it reached the same shape of
answer from its own measurement.

## The shape D object, and what it costs the trace set

Requirement 5 ships as a formula subscripted `_(Observe.slips)`. Pair 5's
forbidden run is S19, a mark coming off on a consultation with no slip filed,
which is exactly the class of step the shipped subscript can't see.

I want that tension named rather than left for a reader to find. The pair puts
the critical behaviour in front of the learner, and the statement tells them
every forbidden run must break at least one requirement. It doesn't hand over
the diagnosis, because TLC never shows them that run. Their model rules it out,
so the green run is green, and checking the shipped formula against pair 5 by
hand is the reading section 7 of `DESCRIPTION.md` wants. My read is that this
makes the object fair rather than giving it away, and it's the reason S19 rather
than D01 is pair 5's violating half.

## Notes for step 5 and the grader

- Requirement 3's subscript is the one deliberate hole. A learner who subscripts
  it on `Observe.slips` still catches S13, since a filing does move the slips, so
  a wrong-but-not-blind answer is possible here and shouldn't be marked the same
  as a blind one.
- Requirement 6 has three ways to be wrong and only one of them is the formula.
  Dropping the fairness conjunct breaks it, and step 2's finding 6 measured that
  every weakening of the form passes at this instance, including
  `WF_vars(Next)`. The handling allowance caps consultations, so every behaviour
  is finite and no botanist can starve another out. A grader can't read the
  fairness target off a green run here.
- Pair 1 covers the range clause and not distinctness. See above.
- The statement gives 259 distinct states under the narrowest state shape and
  says larger counts aren't wrong by themselves. Don't grade on the number.
- S23, the tightening that requires an accepted name before a sheet can be
  doubted, is uncatchable by any property over `Observe`. A learner who reads
  rule 6 that way passes everything. Step 2's finding 7 has the argument.
