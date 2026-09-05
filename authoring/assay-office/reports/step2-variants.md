# assay-office step 2, reference verification and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/assay-office/reference/AssayOffice.tla`
and `AssayOffice.cfg`. I didn't write the reference. Rung 4 of batch 2, bead
`tla-h2cg.10`, load vector 1 3 1 1 0 0.

The matrix in section 1 was authored and frozen before I ran TLC once. Section 2
carries the vector check, section 3 the reference's own gate, section 4 what each
variant did, and section 5 the findings. Section 6 is the trace-pair table for the
statement author.

Every variant sits under `authoring/assay-office/reports/step2-variants/` as its own
module with its own cfg. `_generate.py` in that directory states each mutation as a
replacement against the reference text, so the generator is the matrix in executable
form. qsl's step 4 author had to rebuild step 2's variants because they weren't
committed. These are.

This problem is shape B, so the learner reads the spec and writes the properties.
Every caught variant below is candidate material for the violating half of a trace
pair, and section 4 records the trace length so the statement author can pick without
re-running anything.

## 1. The frozen matrix

Two families. Family S mutates the system, meaning the `Init`, the algorithm body, and
the fairness half of `FairSpec`, and leaves all four obligations in the cfg untouched.
Family P mutates a property or the fairness form and asks whether the weakened version
still catches a break the shipped version catches.

Every mutation is stated against the reference text. `_generate.py` carries the same
edits verbatim.

### Family S, system mutations

| id | name | targets | mutation |
|---|---|---|---|
| S01 | strike-untested | item 1 | strike branch: drop `await book[w].verdict = "atStandard"` |
| S02 | deface-at-standard | item 1 | deface branch: guard becomes `book[w].verdict # "none"` |
| S03 | strike-substandard | item 1, no-both | strike branch: guard becomes `= "substandard"` |
| S04 | reassay | item 2, §6.4 | test branch: drop `await book[w].verdict = "none"` |
| S05 | finding-clears | item 2 | extra branch clearing an at-standard finding back to `"none"` |
| S06 | unmark | item 2 | extra branch setting `book[w].struck := FALSE` |
| S07 | undeface | item 2 | extra branch setting `book[w].damaged := FALSE` |
| S08 | deface-deleted | item 3 | remove the deface branch, keep `WF_vars(Deface(o, w))` |
| S09 | fairness-one-ware | item 3 | `\A o \in Officers : WF_vars(Deface(o, CHOOSE w \in Wares : TRUE))` |
| S10 | custody-holder | §6.1 | add `holder`, a take-up and a put-down, and guard defacing on holding |
| S11 | init-tested | Init, §5 note | every ware starts `verdict \|-> "atStandard"` |
| S12 | init-marked | Init | every ware starts `struck \|-> TRUE` with no finding |
| S13 | init-defaced | Init | every ware starts `damaged \|-> TRUE` with no finding |
| S14 | init-substandard | Init | every ware starts `verdict \|-> "substandard"` |
| S15 | fuse-test-deface | §6.13, rule 4 | test writes substandard and defaces in one step, deface branch gone, fairness dropped |
| S16 | fuse-test-strike | §3 licence | test writes at-standard and strikes in one step, strike branch gone |
| S17 | give-back | §6.2 | a `gone` column no `Observe` field reads, plus a branch setting it |
| S18 | lodging-step | §6.8 | a `lodged` set, a lodging branch, every other branch guarded on membership |
| S19 | third-finding | §6.7 | `Findings` gains `"britannia"` |
| S20 | one-defacing-officer | §6.10 | deface branch guarded on `self = CHOOSE o \in Officers : TRUE` |
| S21 | bench-cap | §6.12 | test branch guarded on no ware being pending |
| S22 | duty-to-test | §6.5 | `FairSpec` gains `WF_vars(Test(o, w))` per officer and ware |

### Family P, property and fairness mutations

| id | name | mutation | run against |
|---|---|---|---|
| P01 | grows-subscript-finding | `TheRecordOnlyGrows` subscripted `_(Observe.finding)` | reference, then S06 |
| P02 | grows-subscript-marked | `TheRecordOnlyGrows` subscripted `_(Observe.marked)` | reference, then S05 |
| P03 | fairness-dropped | `FairSpec == Spec /\ TRUE` | reference |
| P04 | fairness-wf-next | `FairSpec == Spec /\ WF_vars(Next)` | reference |
| P05 | fairness-officer-disjunction | `FairSpec == Spec /\ \A o \in Officers : WF_vars(officer(o))` | reference |
| P06 | marks-one-sided | `MarksFollowTheFinding` drops the `defaced` clause | reference, then S02 |

P01 and P02 are the wrong-subscript probes §9.5 asks for. A step that clears a mark
leaves `Observe.finding` alone, so under `_(Observe.finding)` the property is satisfied
by its own stuttering disjunct and stops seeing the action it was written for. P02 is
the same move one field over.

P03 through P05 are the fairness forms. P03 must come back rc=13, since item 3 is true
only because `FairSpec` carries the conjunct. P04 and P05 are the two coarser forms
`ALTERNATIVES.md` declines, and I'm reporting them either way.

P06 asks whether the strengthening the author made over the screener's sketch is
load-bearing. The screener proposed "no ware both struck and defaced" and the author
widened it to tie both facts to the finding.

### What I expect to come back green, said in advance

Eleven of the 22 system variants, and I want the prediction on the record before the
runs rather than after.

S11 and S15 are the two the description names in section 5's note for the variant pass,
so those are declared holes rather than discoveries. S11 starts every ware tested, and
item 1 is vacuous on an unmarked undefaced ware. S15 fuses the test and the defacing,
which deletes the state where the duty exists and is unmet, so item 3 holds with no
fairness at all. S16 is the fusion section 3 licenses, and it should be green for the
same reason with a state fewer.

S14 starts every ware substandard, which is the S11 hole with the liveness switched on.
The fairness conjunct still discharges each ware, so I expect green.

S17, S18, S20, S21 and S22 all change the system in a way `Observe` can't read. A
`gone` column, a lodging step, an officer restriction and a bench cap are each
invisible through the three fields, and a second fairness conjunct only removes
behaviours. S19 widens `Findings`, which the type invariant reads through
`Observe.finding \in [Wares -> Findings]`, so widening the set widens the invariant
with it.

S08 is the one I'm least sure of. Deleting the deface branch leaves
`WF_vars(Deface(o, w))` demanding a step `Next` forbids, which is §5.3's fourth vacuity
vector. My read is that `FairSpec` stays satisfiable, because behaviours where no ware
is ever found substandard exist and `Deface` is never enabled in them. If that's right
the run is rc=0 and the four obligations hold over a restricted set of behaviours. I'd
rather be wrong here than assume it.

On the P side I expect P04 and P05 green, and that would contradict `ALTERNATIVES.md`.
The author's argument against the coarse forms is that an officer could test wares
forever while a substandard ware sits whole. `Wares` is finite and every action here is
monotone, so no behaviour tests forever. If the coarse forms hold, the author's reason
doesn't apply at this instance even though the choice is still the right one.

### What counts as caught

An invariant catches a variant at rc=12 and an action or temporal property at rc=13,
per §9.5 step 5 and bead `tla-94n`. rc=124 is `TIMEOUT` and is never read as uncaught.
A variant caught by `TypeOK` alone is caught for the wrong reason and gets said so.

The verdict comes from the exit code and only from the exit code. The obligation name
comes from the log, which is where a name is allowed to come from.

## 2. The vector check

I'm the rung's first gate on the vector, read from the artifact. All six place where
the rung block says they should.

| dimension | level | read from |
|---|---|---|
| representation | 1 | a complete spec ships in PlusCal c-syntax, and the learner writes no state |
| property kind | 3 | `SubstandardIsDefaced` carries `~>`, and `FairSpec` carries a fairness conjunct |
| property count | 1 | four cfg lines, two `INVARIANTS` and two `PROPERTIES` |
| step sources | 1 | one process set, `process (officer \in Officers)`, and no clock action |
| state space | 0 | 125 distinct states, TLC's own clock at 00s to 01s |
| form left open | 0 | not mine to place, and I didn't |

Four notes on how those were read.

The count is `TypeOK` and `MarksFollowTheFinding` under `INVARIANTS`, then
`TheRecordOnlyGrows` and `SubstandardIsDefaced` under `PROPERTIES`
(`reference/AssayOffice.cfg:6-11`). Four sits in band 1, which is two to four.

Kind 3 needs the fairness conjunct on a named step per party, and it's there:
`\A o \in Officers, w \in Wares : WF_vars(Deface(o, w))` at
`reference/AssayOffice.tla:126`. That's neither `WF_vars(Next)` nor a disjunction of
one officer's actions, so the two forms the rubric rules out are both absent. Section 5
measures what those two forms would have done.

Representation stays at 1 rather than 2, because the spec's one variable is `book` and
the `Observe` fields are `finding`, `marked` and `defaced`
(`reference/AssayOffice.tla:62` against `:67-70`). The description's section 5 asked for
exactly that separation and the author delivered it.

The obligations sit in the PlusCal `define` block, so they arrive as named operators the
statement author can strip before shipping the module (`reference/AssayOffice.tla:9-37`).

## 3. The reference's own gate

Every run goes through `harness/verdict.sh`, so the verdict is the raw exit code and
nothing reads TLC's stdout. The module is passed absolute and `Gate.tla` is found
through `TLA-Library`, which is the combination `harness/vacuity.sh:238-253` measured as
working from any cwd. A relative module path plus `-postCondition` gave rc=150
`PARSE_ERROR` on `Cannot find source file for module Gate`, which is that note
reproducing.

```
verdict.sh -t 300 <ref>/AssayOffice.tla
    OK                    rc=0    0.66s to 1.26s wall
verdict.sh -t 300 <ref>/AssayOffice.tla -- -inv FALSE
    SAFETY_VIOLATION      rc=12   0.72s wall
verdict.sh -t 300 -p Gate!NonVacuous <ref>/AssayOffice.tla
    OK                    rc=0    0.66s wall
```

Counts, from the plain run: 601 states generated, 125 distinct, depth 7, 3 branches of
temporal properties. TLC's own clock reads `Finished in 00s` on the postcondition run
and `01s` on the first. The wall figures above include JVM start, so the 125 and the
601 are the numbers to cite and the wall time is the looser bound.

125 is the count the description's section 4 predicted from the arithmetic, five live
records per ware at three wares. That's a prediction from the author that held, which I
think is worth saying, because it means the state space is understood rather than
merely measured.

### Coverage

`-coverage 1` is in verdict.sh's canonical invocation, so every run above carries it.
TLC prints one row per disjunct of `officer`, keyed by source range. The check is
`total == 0`, not `distinct == 0`.

| disjunct | source range | distinct : total |
|---|---|---|
| `Init` | 98 | 1 : 1 |
| test | 103,23 to 105,65 | 62 : 324 |
| strike | 106,23 to 108,65 | 31 : 150 |
| deface | 109,23 to 111,66 | 31 : 156 |

No disjunct sits at zero total. There's no PlusCal `Terminating` row at all, because the
algorithm is a `while (TRUE)` with no termination label, so quiescence arrives as
deadlock rather than as termination. That's what `CHECK_DEADLOCK FALSE` in the cfg is
for, and it's the handling the description's quiescence note asked the author to choose.

### Vacuity probes

`harness/vacuity.sh --min-states 125` over the reference, at rc=0:

| probe | verdict |
|---|---|
| non-empty state space | at least 125 distinct states |
| invariant configured | an `INVARIANT` is configured |
| `Spec` satisfiable | admits at least one behaviour |
| dead actions | every action `Next` mentions fired |
| dead actions, named | `--expect-actions officer` reached the coverage block |

I set the floor at 125, the measured count, so any state loss trips it. The per-problem
floor is central's to set and I'm not setting it here. A floor of 4 passes too.

`--observe Observe` returns `VACUOUS_FROZEN_OBSERVE` at rc=8, reporting `finding` frozen
at all-`"none"` across 125 states while `marked` and `defaced` each take 8 values. That's
the false alarm bead `tla-ooxx` describes. TLC wraps the long `finding` record over two
lines and the probe's awk reads single-line values only, so it sees the initial value and
nothing after it.

I checked field motion myself rather than take the brief's word for it. A probe module
asserting `\A w \in Wares : Observe.finding[w] = "none"` as an `INVARIANT` comes back
`SAFETY_VIOLATION` at rc=12, which is the §5.4 idiom reading "it moves". So `finding`
moves and the alarm is false on this reference.

## 4. Results

Every variant ran through the same command, changing only the module path:

```
verdict.sh -t 300 --log <log> --trace <json> <variants>/<id>.tla
```

Any variant returning rc=0 was run again with `-p Gate!NonVacuous`, and every one of
those came back `OK` at rc=0. The obligation column is read out of the log. The verdict
is the exit code alone.

### Family S

| id | token | rc | obligation reported | trace | distinct |
|---|---|---|---|---|---|
| S01 | `SAFETY_VIOLATION` | 12 | `MarksFollowTheFinding` | 2 states | 4 |
| S02 | `SAFETY_VIOLATION` | 12 | `MarksFollowTheFinding` | 3 states | 9 |
| S03 | `SAFETY_VIOLATION` | 12 | `MarksFollowTheFinding` | 3 states | 12 |
| S04 | `LIVENESS_VIOLATION` | 13 | `TheRecordOnlyGrows`, action property | 3 states | 7 |
| S05 | `LIVENESS_VIOLATION` | 13 | `TheRecordOnlyGrows`, action property | 3 states | 8 |
| S06 | `LIVENESS_VIOLATION` | 13 | `TheRecordOnlyGrows`, action property | 4 states | 25 |
| S07 | `LIVENESS_VIOLATION` | 13 | `TheRecordOnlyGrows`, action property | 4 states | 37 |
| S08 | `OK` | 0 | none, gate rc=0 | uncaught | 64 |
| S09 | `LIVENESS_VIOLATION` | 13 | `SubstandardIsDefaced`, temporal | 6 states then stutter | 125 |
| S10 | `LIVENESS_VIOLATION` | 13 | `SubstandardIsDefaced`, temporal | 10 states, back to 7 | 3,375 |
| S11 | `OK` | 0 | none, gate rc=0 | uncaught | 8 |
| S12 | `SAFETY_VIOLATION` | 12 | `MarksFollowTheFinding` | initial state | n/a |
| S13 | `SAFETY_VIOLATION` | 12 | `MarksFollowTheFinding` | initial state | n/a |
| S14 | `OK` | 0 | none, gate rc=0 | uncaught | 8 |
| S15 | `OK` | 0 | none, gate rc=0 | uncaught | 64 |
| S16 | `OK` | 0 | none, gate rc=0 | uncaught | 64 |
| S17 | `OK` | 0 | none, gate rc=0 | uncaught | 1,000 |
| S18 | `OK` | 0 | none, gate rc=0 | uncaught | 216 |
| S19 | `OK` | 0 | none, gate rc=0 | uncaught | 216 |
| S20 | `OK` | 0 | none, gate rc=0 | uncaught | 125 |
| S21 | `OK` | 0 | none, gate rc=0 | uncaught | 81 |
| S22 | `OK` | 0 | none, gate rc=0 | uncaught | 125 |

11 of 22 caught. Nothing hit rc=124, so no timeout is wearing a pass here.

The 11 that came back rc=0 are the 11 the frozen matrix named in advance, and the
S08 reading I said I was least sure of held. I want that on the record as a prediction
that stood rather than a result read backwards.

### Family P

| id | token | rc | obligation reported | trace |
|---|---|---|---|---|
| P01 | `OK` | 0 | none | reference stays green |
| P01S06 | `OK` | 0 | none, and S06 alone is rc=13 | escape |
| P02 | `OK` | 0 | none | reference stays green |
| P02S05 | `OK` | 0 | none, and S05 alone is rc=13 | escape |
| P03 | `LIVENESS_VIOLATION` | 13 | `SubstandardIsDefaced`, temporal | 6 states then stutter |
| P04 | `OK` | 0 | none | see finding 4 |
| P05 | `OK` | 0 | none | see finding 4 |
| P06 | `OK` | 0 | none | reference stays green |
| P06S02 | `OK` | 0 | none, and S02 alone is rc=12 | escape |

### Vacuity over the uncaught variants

`harness/vacuity.sh -q --min-states 4` over each variant that returned rc=0:

| id | verdict | rc |
|---|---|---|
| S11 | `VACUOUS_DEAD_ACTION` | 5 |
| S14 | `VACUOUS_DEAD_ACTION` | 5 |
| S08, S15 to S22 | `NON_VACUOUS` | 0 |
| P01S06, P02S05, P04, P05, P06S02 | `NON_VACUOUS` | 0 |
| P01, P02, P06 | `PROBE_INCONCLUSIVE` | 6 |

The three rc=6 rows are an artifact of how I packaged the variants, not a property of
them. P01, P02 and P06 `EXTENDS AssayOffice`, and the base module lives in
`reference/` rather than beside them. `vacuity.sh` builds its satisfiability probe as a
generated wrapper and sets `TLA-Library` to its own scratch, `harness/` and the module's
directory, which drops any inherited value because the JVM takes the last `-D`. Copied
into a directory holding `AssayOffice.tla`, all three come back `NON_VACUOUS` at rc=0.
Their `verdict.sh` runs, which are the gate, never had the problem, because there the
main module is the variant itself.

## 5. Findings

The gate is green. Eleven system variants stayed uncaught and every one has a named
cause. Two of those causes turned out to be weaker than the description thought, and
that's finding 2.

### 1. Nine of the eleven uncaught variants are structurally uncatchable

S15 to S22, plus S08, break nothing the interface can see, and I don't think any
property over `Observe` closes any of them.

S15 and S16 are the two fusions. Both delete a state rather than add a behaviour. S15
writes the substandard finding and defaces in one motion, so the state where the duty
exists and is unmet never arises, and item 3 is true with the fairness conjunct gone.
The state count says it plainly: 64 against the reference's 125, which is four live
records per ware instead of five. That's the description's section 3 note reproducing
under measurement, and it's the reason Rule 4 has to keep the finding and the act apart.

S17 and S18 add state the operator doesn't read. S17's `gone` column doubles the space to
1,000 and changes no `Observe` field, so every such step satisfies
`[][...]_Observe` through its own stuttering disjunct. S18's lodging step is the same
shape at 216. Both are the §6.2 and §6.8 answers holding up.

S19 widens `Findings` to four values and stays green because `TypeOK` reads
`Observe.finding \in [Wares -> Findings]`. Widening the set widens the invariant with it.
A type invariant written against a literal set would have caught this, and I'd not
recommend that change, because `Findings` is the spec's own definition and the learner
never writes it.

S20 and S21 remove behaviours rather than add them. An officer restriction and a bench
cap can't break a safety property, and neither breaks the liveness because the defacing
step stays reachable. S22 is the same in the fairness half.

S08 is the interesting one. Deleting the deface branch leaves `WF_vars(Deface(o, w))`
demanding a step `Next` forbids, so every behaviour that finds a ware substandard is
excluded from `FairSpec`. The state graph still has all 64 states, including substandard
undefaced ones, but the temporal obligations are checked over the surviving behaviours
only, and among those no ware is ever substandard. `vacuity.sh` reports `NON_VACUOUS`,
so §5.3's fourth vector doesn't fire either, because `FairSpec` does admit behaviours.
That's a narrower version of the same trap, and worth knowing about: fairness can empty
out an obligation without emptying out the spec.

### 2. The two Init holes ARE catchable, and the description says they aren't

This is the finding I'd carry forward. The description's section 5 note for the variant
pass says an `Init` that starts a ware already tested is "green under all three items and
the type invariant", and calls it a mutant nobody can catch. The first half is right and
the second half isn't.

S11 and S14 both come back `VACUOUS_DEAD_ACTION` at rc=5. On S11 the probe names two
dead disjuncts, the test branch on `book[w].verdict = "none"` evaluated 48 times and
never true, and the deface branch on `= "substandard"` the same. S14 is the mirror.

So the hole is real at the obligation layer and closed at the harness layer. I think
that's worth a line in the description rather than a repair, because §5.3's dead-action
probe runs on every grading run anyway and the cfg stays at four lines. The §0b review
that filed this as D6 was right to file it, and the answer turns out to be "the probe
catches it", not "nothing does".

I'd not read this as covering every opening mutation. It catches an `Init` that makes an
action unreachable, which is what these two do. An opening that seeds one ware out of
three would leave every branch live, and I'd expect that one to stay green. I haven't
run it.

### 3. `TypeOK` never fired, and no variant reached it

Nothing in the matrix was caught by the type invariant. That's not a gap in the matrix,
it's a fact about the representation. `book` is a function into a record of three fields
and `Observe` projects it field by field, so a variant would have to write a value
outside `Findings` or outside `BOOLEAN` to break the type. Every mutation that does that
is a mutation of the spec's own `Findings` definition, which is S19, and S19 widens the
invariant along with the set.

Downstream this matters for the trace pairs. `TypeOK` has no violating half in this
matrix, and §3.9 wants one per property. The description already says the type invariant
is the author's and never something the learner writes, so I'd read the four cfg lines as
three graded obligations plus a scaffold. Section 6 lists three pairs for that reason.

### 4. Both coarse fairness forms hold here, so the author's reason doesn't apply

`ALTERNATIVES.md` declines `WF_vars(Next)` and the per-officer disjunction, and gives one
reason: an officer who tests wares forever satisfies the coarse form while a substandard
ware sits whole. P04 and P05 both come back rc=0, so no such behaviour exists at this
instance.

The mechanism is that every action here is monotone. A test writes a finding once, a
strike and a defacing each flip a flag once, and `Wares` is finite. So nothing runs
forever, every behaviour reaches quiescence, and at quiescence no substandard ware is
undefaced. The coarse forms drag the system to quiescence just as the fine one does.

I'd keep the fine form anyway, and the author's second reason is the one that carries it:
this is the rung where fairness first appears, and the fine form is the one that stays
right when the system stops being monotone. What I'd change is the stated reason. The
description's section 2 says the coarse form "happens to work here" and then says the
weak-fairness-on-a-disjunction form "obliges none of them, so an officer who tests wares
forever satisfies it". The first clause is measured true and the second is measured
false at this instance. I'd cut the second and keep the first.

That's a note on the description, not a defect in the reference. The reference is correct
either way.

### 5. The wrong-subscript hazard reproduces, on both fields

P01S06 and P02S05 both escape. S06 clears a mark and is caught at rc=13 by
`TheRecordOnlyGrows`. The same system, with the property subscripted
`_(Observe.finding)`, comes back rc=0, because a mark-clearing step leaves `finding`
alone and the property is satisfied by its own stuttering disjunct. P02S05 is the mirror:
a finding-clearing step leaves `marked` alone.

Under shape B the learner writes that subscript, and the description's section 2 tells
the statement author to say the subscript is the whole of `Observe`. This measurement is
why that sentence has to survive into the statement.

Neither escape is rescued by another obligation, which is where this differs from qsl.
qsl's P02 escape was caught incidentally by a leads-to. Here the liveness only watches
`defaced`, so a wrong subscript on item 2 is a clean pass on a broken store.

### 6. The one-sided item 1 misses a whole institution

P06S02 escapes. S02 lets an officer deface a ware the office found at standard, and the
shipped `MarksFollowTheFinding` catches it at rc=12 in 3 states. Drop the `defaced`
clause, which is the screener's original "no ware both struck and defaced", and the run
goes to rc=0 over 343 distinct states.

The state count is the tell. S02 alone stops at 9 distinct because the invariant fires
early. Under the one-sided form the search runs to completion, so this isn't a truncated
run passing by accident.

So the author's widening over the screener's sketch is load-bearing, not defensive. That
answers the question §5's "what I changed from the screener's sketch" raised, and the
answer is that the weak form leaves a ware found at standard destroyable with nothing
watching.

### 7. Item 2 catches four different breaks and item 1 catches four

Both graded safety obligations have several arrows, which is a good sign for a shape B
problem where the learner has to invent them.

`TheRecordOnlyGrows` fires on S04, S05, S06 and S07, which are a rewritten finding, a
cleared finding, an erased mark and an undone defacing. That's all three fields plus the
re-assay case, so the "whole record" widening the author made over the screener's
"finding once recorded never changes" is load-bearing too.

`MarksFollowTheFinding` fires on S01, S02, S03, S12 and S13. S03 is the no-both case,
and it arrives through the same invariant rather than through a separate one, which is
what the author predicted when they folded no-both into item 1.

### 8. S10 is the only variant whose counterexample is a real lasso

Every other liveness catch here ends in a stutter. S10 adds a holder, so the officers
can take a ware up and put it down forever while a substandard ware sits whole, and TLC
reports 10 states and `Back to state 7`.

That's §6.1 measured. Putting the defacing behind a holder breaks item 3, and it breaks
it through a cycle rather than through a halt. If a later rung wants a lasso
counterexample to teach with, this is the shape, and it costs 3,375 states.

## 6. For the statement author

One violating trace per graded obligation. Satisfying traces come from the reference,
which is green at rc=0.

| obligation | variant | trace | shape |
|---|---|---|---|
| item 1, marks follow the finding | S12 | initial state | a ware struck with no finding |
| item 2, the record only grows | S04 | 3 states | a finding rewritten |
| item 3, substandard is discharged | P03 | 6 states then stutter | fairness dropped |

Three notes on those picks.

S12 is the description's own shape for item 1, which section 2 states as "an untested
ware carrying the hallmark". It violates at the initial state, so the trace is one state
long. If a step trace reads better in the statement, S01 is 2 states and shows the strike
happening.

S04 is the re-assay, which is the mistake a person would make. S05 clears a finding
instead and is the same length. Either works, and I'd take S04 because rewriting a
finding is a thing an office might plausibly do and clearing one isn't.

Item 3's violating half is a lasso, and P03 is the pick. The trace runs six real states
and then State 7 reads `Stuttering`, so the violation is that nothing more happens, ever.
The description already says that last clause has to be spelled out in the statement,
because the prefix on its own is an ordinary run. S09 is the same length with the
fairness narrowed to one ware rather than dropped, and S10 is the cycle version at 10
states if a stutter reads as an anticlimax.

`TypeOK` gets no row, per finding 3.

## 7. What a repairer would do, if anyone asks

Nothing, on my read. The gate is green and every uncaught variant has a named cause, so
§9.5b isn't triggered. I'd not send this to a repairer.

For the record, the one repair that would close a real hole is a fourth cfg line pinning
the opening, and §0b already priced it: five cfg lines takes property count from band 1
to band 2, which is a second new high at a rung whose one new high is meant to be the
fairness. Clause (b') of the ramp rule allows one. So the repair isn't available here,
and finding 2 says the dead-action probe covers the two openings that matter anyway.
