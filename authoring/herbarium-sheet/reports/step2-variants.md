# herbarium-sheet step 2, reference verification and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/herbarium-sheet/reference/Herbarium.tla`
and `Herbarium.cfg` at commit `738b309`. I didn't write the reference. Bead
`tla-h2cg.12`, rung 6 of batch 2.

The matrix in section 1 was authored and frozen before I ran TLC once. Section 2
records the reference's own gate. Section 3 records what each variant did.
Section 4 carries the findings, including the variants nothing caught and why.
Section 5 is the vector check, and section 6 is the trace shortlist for the
statement author.

Downstream this problem is shape D at representation 2. The learner models the
system from prose, gets handed a green TLC run, and has to say why the green is
worth nothing. Section 4's finding 1 is the measurement that object rests on.

## 1. The frozen matrix

Two families and one shape D object. Family S mutates the system, the `Init`,
`Next`, action and fairness half of the module, and leaves all eight obligations
in the `.cfg` untouched. Family P mutates a property instead and asks whether the
weakened form still catches a system variant the shipped form catches.

Every mutation is stated as an exact text pair in
`reports/step2-variants/generate.py`, which is the matrix in executable form. A
reader checks a row by reading the pair. Each generated module carries the
mutation and nothing else, and all 35 share one config, byte-identical to the
reference's at md5 `cf5ee4b2ccb7db78f1ac022f0e3ee004`.

### Family S, system mutations

| id | name | targets | mutation |
|---|---|---|---|
| S01 | opening-doubted | item 7 | `Init`: `doubted = [s \in Sheets \|-> TRUE]` |
| S02 | opening-slip-seeded | items 7, 1 | `Init`: every sheet opens with one slip stamped 1 |
| S03 | opening-consulted-one | item 7 | `Init`: `consulted = [s \in Sheets \|-> 1]` |
| S04 | opening-accepted-set | items 7, 2 | `Init`: every sheet opens with an accepted name |
| S05 | consult-reads-ahead | item 1, amb 1 | `Consult`: `reading' = [reading EXCEPT ![b][s] = Handling[s]]` |
| S06 | handling-uncapped | item 1, amb 5 | `Consult`: guard becomes `consulted[s] < Handling[s] + 1` |
| S07 | slip-stamp-frozen | item 1 | `File`: the slip is stamped `1` whatever the reading |
| S08 | accepted-not-updated | item 2 | `File`: `accepted' = accepted` |
| S09 | accepted-is-filers-name | item 2 | `File`: `accepted' = [accepted EXCEPT ![s] = n]` |
| S10 | accepted-is-lowest-slip | item 2, amb 3 | `File` takes `BottomName(filed)`, the property keeps `TopName` |
| S11 | slips-replaced | item 3, amb 4 | `File`: `filed == {[name \|-> n, stamp \|-> reading[b][s]]}` |
| S12 | sheet-withdrawn | item 3, amb 2 | extra `Next` disjunct emptying a sheet and clearing its name |
| S13 | consult-without-stamping | item 3, amb 7 | `Consult` bumps the count and leaves `reading` alone |
| S14 | reread-without-consulting | item 3, amb 7 | extra disjunct handing a stamp with no consultation |
| S15 | file-above-the-reading | item 4, amb 6 | `File`: the slip is stamped `consulted[s]` |
| S16 | consultation-cancelled | item 4 | extra disjunct closing a consultation with no filing |
| S17 | file-carbon-copy | item 4 | `File` adds a second slip stamped 1 alongside the real one |
| S18 | file-without-a-reading | item 4, amb 6 | `File`'s guard becomes `consulted[s] > 0` |
| S19 | doubt-clears-on-consult | item 5 | `Consult`: `doubted' = [doubted EXCEPT ![s] = FALSE]` |
| S20 | file-keeps-the-mark | item 6, amb 9 | `File`: `UNCHANGED <<consulted, doubted>>` |
| S21 | doubt-unguarded | item 6, amb 8 | `Doubt`: drop the `reading[b][s] # None` conjunct |
| S22 | fairness-dropped | item 6 | `Spec`: drop the `WF_vars(FileStep(b, s))` conjunct |
| S23 | doubt-needs-an-accepted-name | amb 10 | `Doubt`: add `accepted[s] # None` |
| S24 | name-carries-a-stamp | `TypeOK` | `File`: the slip's `name` field carries the stamp |
| S25 | nothing-happens | vacuity | `Next == UNCHANGED vars` |

The `amb` numbers are §6's resolved ambiguities. Amb 11 is covered by S01 to S04,
and amb 12, one sheet per specimen, has no mutation because the sheet set is the
domain of every field and there's nowhere to record a duplicate.

Four of those I expect to come back green, and I want the expectation on the
record before the runs rather than after. S23 is a tightening rather than a break.
It removes behaviors, and no obligation in the set asks that a doubt be possible,
so nothing can see it. S25 should pass all eight obligations and fail only the
vacuity gate. S24 is the `TypeOK` probe, and being caught by `TypeOK` is what it's
for rather than a wrong-reason catch.

### The shape D object

`D01`, mark-comes-off-freely, is §7's hidden model. An extra `Next` disjunct
`Clear(s)` takes a doubtful mark off with nothing else changing, which is the
model §7 describes a learner building when they miss rule 6. It's the system the
shipped green run is about.

### Family P, property mutations

| id | name | mutation | run against |
|---|---|---|---|
| P01 | doubt-rule-wrong-subscript | `DoubtClearsOnlyOnFiling` subscripted `_(Observe.slips)` | reference |
| P01D01 | the-shipped-green | P01 on top of D01 | the hidden model |
| P02 | comes-from-wrong-subscript | `SlipComesFromAConsultation` subscripted `_(Observe.slips)` | reference |
| P02S16 | comes-from-blind-to-a-cancel | P02 on top of S16 | the cancel variant |
| P03 | only-grows-wrong-subscript | `RecordOnlyGrows` subscripted `_(Observe.consulted)` | reference |
| P03S11 | only-grows-blind-to-a-replacement | P03 on top of S11 | the replacing variant |
| P04 | fairness-single-existential | `WF_vars(\E b, s : FileStep(b, s))` | reference |
| P05 | fairness-per-botanist | `\A b : WF_vars(\E s : FileStep(b, s))` | reference |
| P06 | fairness-on-next | `WF_vars(Next)` | reference |

P01 is the seeded defect of §7, and P01D01 is the run the learner is handed. I
expect both green, and P01D01's green is the whole downstream object.

P02 and P03 are the same wrong-subscript move on the other two action properties.
I expect both to escape their paired system variant, since a cancel leaves
`Observe.slips` alone and a filing leaves `Observe.consulted` alone.

P04 to P06 are the fairness forms. `ALTERNATIVES.md` records the author measuring
the first two as probes M9 and M10 and finding both green, and says a
fairness-weakening seed won't be caught at this instance. I expect to reproduce
that. S22, dropping the conjunct outright, is the one that should go red.

### What counts as caught

An invariant catches a variant at rc=12 and an action or temporal property at
rc=13, per §5.1 and bead `tla-94n`. rc=124 is `TIMEOUT` and is never read as
uncaught. Anything else gets recorded as itself. The verdict comes from the exit
code and only from the exit code. The obligation name comes from the log, which
is where a name is allowed to come from.

## 2. The reference's own gate

Every run goes through `harness/verdict.sh`, so the verdict is the raw exit code
and nothing reads TLC's stdout. `Gate.tla` is found through
`JAVA_TOOL_OPTIONS="-DTLA-Library=$WT/harness"` with the module passed as an
absolute path. The absolute form is load-bearing. My first attempt at check 3
passed a relative module path and got `PARSE_ERROR` rc=150,
`Cannot find source file for module Gate`, because TLC searches the CWD for
auxiliary modules only when the main module arrives relative. `vacuity.sh:240-251`
carries the same note.

```
./harness/verdict.sh -t 300 --config $REF/Herbarium.cfg $REF/Herbarium.tla
    OK                     rc=0
./harness/verdict.sh -t 300 --config $REF/Herbarium.cfg $REF/Herbarium.tla -- -inv FALSE
    SAFETY_VIOLATION       rc=12
./harness/verdict.sh -t 300 --config $REF/Herbarium.cfg -p 'Gate!NonVacuous' $REF/Herbarium.tla
    OK                     rc=0
./harness/vacuity.sh -c $REF/Herbarium.cfg -n 100 -t 120 --observe Observe \
    --expect-actions Consult,File,Doubt $REF/Herbarium.tla
    NON_VACUOUS            rc=0
```

All five vacuity probes report clean: a state space of at least 100 distinct
states, an `INVARIANT` configured, a `Spec` that admits a behavior, every expected
action reaching the coverage block, and every field of `Observe` taking more than
one value.

Counts, from the plain run: 1,103 states generated, 259 distinct, and the complete
state graph search is 7 deep. The author's §4 arithmetic guessed 259 and nobody had
run it. It's 259.

Wall time over three consecutive runs was 0.97 s, 0.99 s and 0.96 s, measured
around `verdict.sh` and so carrying JVM startup. TLC's own figure in the log is
`Finished in 00s`.

Action coverage, from the same run's final table. The check is `total == 0`, not
`distinct == 0`. There's no PlusCal `Terminating` row here, because the reference
isn't PlusCal.

| action | distinct : total |
|---|---|
| `Init` | 1 : 1 |
| `Consult` | 26 : 216 |
| `File` | 88 : 784 |
| `Doubt` | 144 : 194 |

No action sits at zero. All three fire.

## 3. Results

Each variant ran with the same command, changing only the module path:

```
./harness/verdict.sh -t 300 --config $VAR/variant.cfg $VAR/<id>.tla
```

Every variant that came back rc=0 was then run through `vacuity.sh` with the same
flags as the reference.

### Family S and the shape D object

| id | token | rc | obligation reported | trace |
|---|---|---|---|---|
| S01 | `LIVENESS_VIOLATION` | 13 | `Opening`, by source location (finding 3) | initial state |
| S02 | `SAFETY_VIOLATION` | 12 | `RecordWellFormed` | initial state |
| S03 | `LIVENESS_VIOLATION` | 13 | `Opening`, by source location | initial state |
| S04 | `SAFETY_VIOLATION` | 12 | `AcceptedIsTopSlip` | initial state |
| S05 | `SAFETY_VIOLATION` | 12 | `RecordWellFormed` | 2 states |
| S06 | `SAFETY_VIOLATION` | 12 | `RecordWellFormed` | 3 states |
| S07 | `LIVENESS_VIOLATION` | 13 | `SlipComesFromAConsultation` (finding 2) | 5 states |
| S08 | `SAFETY_VIOLATION` | 12 | `AcceptedIsTopSlip` | 3 states |
| S09 | `SAFETY_VIOLATION` | 12 | `AcceptedIsTopSlip` | 5 states |
| S10 | `SAFETY_VIOLATION` | 12 | `AcceptedIsTopSlip` | 5 states |
| S11 | `LIVENESS_VIOLATION` | 13 | `RecordOnlyGrows` | 5 states |
| S12 | `LIVENESS_VIOLATION` | 13 | `RecordOnlyGrows` | 4 states |
| S13 | `LIVENESS_VIOLATION` | 13 | `RecordOnlyGrows` | 2 states |
| S14 | `LIVENESS_VIOLATION` | 13 | `RecordOnlyGrows` | 3 states |
| S15 | `LIVENESS_VIOLATION` | 13 | `SlipComesFromAConsultation` | 4 states |
| S16 | `LIVENESS_VIOLATION` | 13 | `SlipComesFromAConsultation` | 3 states |
| S17 | `LIVENESS_VIOLATION` | 13 | `SlipComesFromAConsultation` | 4 states |
| S18 | `LIVENESS_VIOLATION` | 13 | `SlipComesFromAConsultation` | 3 states |
| S19 | `LIVENESS_VIOLATION` | 13 | `DoubtClearsOnlyOnFiling` | 4 states |
| S20 | `LIVENESS_VIOLATION` | 13 | `ConsultationIsAnswered` | 9 states, then stuttering |
| S21 | `LIVENESS_VIOLATION` | 13 | `ConsultationIsAnswered` | 10 states, then stuttering |
| S22 | `LIVENESS_VIOLATION` | 13 | `ConsultationIsAnswered` | 8 states, then stuttering |
| S23 | `OK` | 0 | none, and `vacuity.sh` also rc=0 | uncaught |
| S24 | `SAFETY_VIOLATION` | 12 | `TypeOK` | 3 states |
| S25 | `OK` | 0 | `vacuity.sh` at `VACUOUS_EMPTY_SPACE` rc=3 | 1 distinct state |
| D01 | `LIVENESS_VIOLATION` | 13 | `DoubtClearsOnlyOnFiling` | 4 states |

24 of 26 caught by an obligation, S25 by the vacuity gate, and S23 uncaught. No
run hit rc=124, so nothing here is a timeout wearing a pass. The two greens are
the two the frozen matrix named in advance, and I want that on the record as a
prediction that held rather than a result read backwards.

Every liveness counterexample ends in `Stuttering` rather than a back-edge. The
description's §2 says item 6's violating trace is a finite prefix, and that's the
shape all four have.

### Family P

| id | token | rc | obligation reported | distinct states |
|---|---|---|---|---|
| P01 | `OK` | 0 | none | 259 |
| P01D01 | `OK` | 0 | none | 259 |
| P02 | `OK` | 0 | none | 259 |
| P02S16 | `LIVENESS_VIOLATION` | 13 | `ConsultationIsAnswered` (finding 5) | 459 |
| P03 | `OK` | 0 | none | 259 |
| P03S11 | `OK` | 0 | none | 245 |
| P04 | `OK` | 0 | none | 259 |
| P05 | `OK` | 0 | none | 259 |
| P06 | `OK` | 0 | none | 259 |

`vacuity.sh` returns `NON_VACUOUS` rc=0 on all nine, and on D01.

## 4. Findings

The gate is green. Nine variants stayed uncaught, and every one has a named
structural cause. I don't think this needs a §9.5b repair. The property set is
sound, and the two things I'd change sit in the description and in the trace
shortlist rather than in the spec.

### 1. The shipped green, measured

This is what step 4 ships, so it gets the four cells rather than a sentence. The
system axis is the reference against D01, the hidden model where a mark comes off
on any step. The property axis is `DoubtClearsOnlyOnFiling` subscripted over the
whole of `Observe` against the same rule subscripted over `Observe.slips`.

| | correct model | hidden model (D01) |
|---|---|---|
| rule over `Observe` | rc=0 | rc=13, 4 states |
| rule over `Observe.slips` | rc=0 (P01) | rc=0 (P01D01) |

Three greens and one red, and the red is the only cell that grades anything. §7's
account holds exactly: a `Clear` step leaves `slips` untouched, so it's a stutter
for the subscripted formula, and the rule is true on it without being looked at.

The sharper result is the state counts. D01 reaches 259 distinct states in 1,275
generated. The reference reaches 259 distinct in 1,103. The hidden model is
state-for-state identical to the correct one, and the 172 extra generated states
all fold into states that already exist. So nothing that reads a state count can
tell the two models apart, and `vacuity.sh` returns `NON_VACUOUS` rc=0 on
P01D01 with all five probes clean.

I'd put that in the statement author's hands as the thing that makes the object
fair. The learner isn't being asked to notice a suspicious number. There is no
suspicious number. The only way in is to know which steps clear a mark and then
read which of them the subscript lets through, which is the reading §7 says it
wants.

### 2. Nothing in the matrix isolates item 1's distinctness clause

S07 stamps every slip at 1, and I authored it to reach a state with two slips at
one stamp carrying different names. It never gets there. TLC reports
`SlipComesFromAConsultation` at 5 states instead, and the trace says why: at state
5 `b2` files `n1` at stamp 1, which is already on the sheet, so `slips` doesn't
change while `b2`'s consultation closes. That trips item 4's way-out clause, and
it trips it two steps before the two-name state is reachable.

So `RecordWellFormed` is caught by S05 on its range clause and by S06 on its
handling cap, and the distinctness clause has no variant of its own. The
description's §2 claims the isolating trace is "two slips on one sheet carrying
different names and both stamped 2", and I couldn't reach it from the frozen set.

The matrix doesn't move, so this is a note for step 4 rather than a row. The
mutation that would isolate it adds a `slips[s] \cup {rec} # slips[s]` conjunct to
S07's `File`, which forbids the no-change filing and leaves the second name as the
only route. I'd expect rc=12 on `RecordWellFormed` at 6 states. That's a
prediction, not a measurement, and whoever wants the trace should run it.

### 3. `Opening` arrives as a source location, not a name

S01 reports `Property line 99, col 14 to line 99, col 39 of module S01 is violated
by the initial state`, and line 99 is `/\ Observe.doubted[s] = FALSE`. S03 reports
line 97, which is `/\ Observe.consulted[s] = 0`. TLC splits a `PROPERTIES` state
predicate per top-level conjunct into implied inits and names the location.

qsl's step 2 measured the same split on `Bureau`, and this is the second reading
on a different problem, so I'd now treat it as how TLC behaves rather than as a
quirk of one module. A tutor that reports the obligation by name has no name to
report here.

### 4. The invariants beat `Opening` at the opening

S02 seeds a slip and reports `RecordWellFormed`. S04 seeds an accepted name and
reports `AcceptedIsTopSlip`. Both were authored against item 7 and neither reaches
it, because TLC checks the invariants against the initial state before the implied
inits.

So `Opening` gets its own arrow only when the seeded opening is well formed in
every other respect, which is S01 and S03. That's the same routing qsl found at
its S22, and it's worth the statement author knowing before they pick a trace.

### 5. The wrong subscript escapes, and one escape gets covered by accident

P01 and P01D01 are finding 1. P03S11 is the same move on item 3 and it holds all
the way: `RecordOnlyGrows` under `_(Observe.consulted)` goes blind to every filing,
and the replacing filing then passes the whole set at rc=0 over 245 distinct
states. Nothing else notices a slip leaving a sheet. Item 4 sees one slip appear
and a consultation close, which is all it asks, and item 2 sees an accepted name
that agrees with the one slip that's left.

P02S16 is the exception and it's the interesting one. `SlipComesFromAConsultation`
under `_(Observe.slips)` does go blind to a cancel, and S16 was then caught anyway,
at rc=13 by `ConsultationIsAnswered` over 9 states. Cancelling a consultation on a
doubted sheet whose handling allowance is spent leaves a mark nobody can ever take
off, because both `File` and `Doubt` need an open consultation and no further
consultation is possible.

That coverage is incidental. It has nothing to do with the property the learner got
wrong. qsl's step 2 found the same shape at its P02, so I'd treat a green run on a
single variant as weak evidence about a single property, in this family of problems
more than most.

### 6. The fairness form is uncatchable at this instance, all three ways

S22 drops the conjunct and goes red at rc=13. P04, P05 and P06 weaken it and all
three return rc=0 over the reference's own 259 states.

`ALTERNATIVES.md` predicted the first two and gave the mechanism: the handling
allowance caps consultations, so every behavior has finitely many filings in it and
no botanist can file forever to starve another one out. P06 extends that. Once
every behavior is finite, `WF_vars(Next)` drains the system to quiescence and
closes every consultation on the way, so even fairness on the whole next-state
relation delivers item 6 here.

The author flagged this on the way out and the flag holds. A seeded defect that
weakens the fairness form won't be caught at 2 sheets and 2 botanists. Only
dropping the conjunct shows up. The repair isn't a property change, it's a bigger
instance, and a bigger instance costs this rung its state-space band. I'd leave it
and record the limit, which is what the author did.

### 7. S23 is structurally uncatchable, and S25 is the vacuity gate earning its place

S23 adds `accepted[s] # None` to `Doubt`, which is §6's ambiguity 10 resolved the
other way. It returns rc=0 over 155 distinct states, down from 259. No property in
the set can catch it, and I don't think any safety or liveness property over
`Observe` could. The mutation removes behaviors, and "a bare sheet can be marked
doubtful" is a claim that a behavior exists. Only an existence check over the step
relation would see it.

S25 replaces `Next` with `UNCHANGED vars`. All eight obligations pass at rc=0 over
one distinct state, and `vacuity.sh` reports `VACUOUS_EMPTY_SPACE` at rc=3 against
a floor of 100. It's the only variant here the obligations can't touch and the gate
can, which is the argument for running the gate on every grading run rather than
only on the reference.

### 8. §5 of the description asks for two things that can't both hold

`DESCRIPTION.md` §5 says the reference ships as PlusCal in the c-syntax dialect,
and four paragraphs later says the reference carries five variables and they're the
five `Observe` fields, with a sixth taking the rung from representation 2 to 3.
PlusCal generates `pc`, so those conflict.

The author shipped raw TLA+ with five variables and no `pc`, which is the reading
the rung's vector needs. I think that's the right call and the description should
carry the correction rather than the next author rediscovering it. This is a
finding about the handoff, not about the reference.

## 5. The vector check

Read off the artifact, per §2.5. The rung block declares 2 3 2 1 0 1.

- **Property count 2.** Eight obligation lines in the cfg, three `INVARIANTS` and
  five `PROPERTIES`. Band 2 is five to nine.
- **Property kind 3.** `ConsultationIsAnswered` carries two `~>` obligations at
  `Herbarium.tla:136` and `:138`. `Spec` carries one fairness conjunct at `:66`,
  `\A b \in Botanists, s \in Sheets : WF_vars(FileStep(b, s))`, a named step per
  botanist and sheet. It isn't `WF_vars(Next)` and it isn't a disjunction of one
  party's actions.
- **Representation 2.** `VARIABLES slips, consulted, reading, accepted, doubted`
  at `:9`, exactly the five `Observe` fields and nothing else. No `pc` anywhere in
  the module and no `algorithm` block.
- **Step sources 1.** All three `Next` disjuncts are `\E b \in Botanists, s \in
  Sheets`. One party kind, no clock action, no action belonging to anything else.
- **State space 0.** 259 distinct and 1,103 generated with `-workers 1`, and
  0.96 to 0.99 s wall over three runs. Under a second and under 1,000.

Form 1 isn't gateable here. It's a claim about what the statement gives the
learner, and the reference is the artifact the statement gets built from.

The vector holds on all five axes I can read.

## 6. For the statement author

The shortest caught variant per obligation, with its trace length. These are the
violating halves of step 4's trace pairs, and the satisfying halves come from the
reference, which is green.

| obligation | variant | rc | trace |
|---|---|---|---|
| `TypeOK` | S24 | 12 | 3 states |
| `RecordWellFormed` | S05 | 12 | 2 states, and see finding 2 |
| `AcceptedIsTopSlip` | S08 | 12 | 3 states |
| `Opening` | S03 | 13 | initial state, and see finding 3 |
| `RecordOnlyGrows` | S13 | 13 | 2 states |
| `SlipComesFromAConsultation` | S16 | 13 | 3 states |
| `DoubtClearsOnlyOnFiling` | S19 | 13 | 4 states |
| `ConsultationIsAnswered` | S22 | 13 | 8 states, then stuttering |

S16 is the pick for item 4 over S18 at the same length, because a cancelled
consultation is a thing a person would build and filing with no consultation at all
reads as a typo. S05 is the pick for item 1 over S06, which needs a third state.
S19 is the pick for item 5 over D01 at the same length, because D01 is the shape D
object and shouldn't do double duty as a published trace.

Item 6's violating half is a finite prefix ending in a stutter rather than a lasso,
which is what §2 said to expect. Say so in the statement, or the trace reads as
truncated.
