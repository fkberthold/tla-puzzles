# floor-malting step 2: reference verification and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/floor-malting/reference/Maltings.tla`
and `Maltings.cfg`. I didn't write the reference. Bead `tla-h2cg.11`, rung 5 of
batch 2.

The matrix in section 1 was authored and frozen before I ran TLC once. Section 2
records the reference's own gate. Section 3 records what each variant did.
Section 4 carries the findings, including the variants nothing caught and why.
Section 5 is the trace-pair table for the statement author.

Downstream this problem is shape A, so the learner writes the state and the
obligations ship with the statement. That changes what family P is for. Under
shape B a weakened property is a learner mistake to grade. Here it's a claim
about how much work each shipped obligation is doing, and a property that can be
weakened without any seeded break escaping is a property carrying nothing.

## 1. The frozen matrix

Two families, in qsl's shape. Family S mutates the system half (the `Init`,
`Next`, action and `Spec` text) and leaves all eight obligations in the cfg
untouched. Family P mutates a property instead, and asks whether the weakened
form still catches a system variant the shipped form catches.

Every mutation is stated against the reference text, so the matrix reads as a
diff without needing the files. The reference's own cfg is used for every run,
so no variant can pass by having its obligations edited.

Item numbers are `DESCRIPTION.md` section 2's must-be-trues. Ambiguity numbers
are section 6's.

### Family S, system mutations

| id | name | targets | mutation |
|---|---|---|---|
| S01 | opening-turned | item 1 | `Init`: `modification = [p \in Pieces \|-> 1]` |
| S02 | opening-off-floor | item 1, amb 3 | `Init`: `stage = [p \in Pieces \|-> "malt"]`, `modification` all `NoCount` |
| S03 | no-ceiling | item 2, rule 3, amb 5 | `Turn`: drop the `modification[p] < UpperMark` guard |
| S04 | kiln-keeps-count | item 2, amb 15 | `Kiln`: `UNCHANGED modification` |
| S05 | throwout-zeroes-count | item 2, amb 15 | `ThrowOut`: `modification' = [modification EXCEPT ![p] = 0]` |
| S06 | floor-swept | item 3 | extra `Next` disjunct turning every eligible floor piece at once |
| S07 | double-turn | item 4 | `Turn`: `@ + 2` |
| S08 | unturned-malt | item 5, early side | `Kiln`: `stage' = [stage EXCEPT ![p] = "malt"]` unconditionally |
| S09 | matted-malt | item 5, late side, rule 2 | `Ready(p) == modification[p] >= LowerMark`, upper bound dropped |
| S10 | back-to-the-floor | item 6, amb 7 | extra `Next` disjunct returning a loss to the floor at 0 |
| S11 | malt-to-loss | item 6 | extra `Next` disjunct regrading `"malt"` to `"loss"` |
| S12 | fairness-dropped | item 7 | `Spec`: drop the `WF_vars` conjunct |
| S13 | fairness-coarse | item 7 | `Spec`: `WF_vars(Next)` in place of the per-piece conjunct |
| S14 | fairness-per-maltster | item 7 | `Spec`: `\A m \in Maltsters : WF_vars(\E p \in Pieces : Turn(m, p) \/ Remove(m, p))` |
| S15 | fairness-on-turning | item 7 | `Spec`: `\A p \in Pieces : WF_vars(\E m \in Maltsters : Turn(m, p))` |
| S16 | fairness-on-kilning | item 7 | `Spec`: `\A p \in Pieces : WF_vars(\E m \in Maltsters : Kiln(m, p))` |
| S17 | no-turning | rule 3 | `Next == \E m \in Maltsters, p \in Pieces : Remove(m, p)` |
| S18 | nothing-happens | vacuity | `Next == UNCHANGED vars` |
| S19 | turn-off-the-floor | item 6 | `Turn`: drop the `stage[p] = "floor"` guard |
| S20 | opening-no-count | item 2, item 1 | `Init`: `modification = [p \in Pieces \|-> NoCount]` |
| S21 | fourth-place | `TypeOK`, rule 1 | `ThrowOut`: `stage' = [stage EXCEPT ![p] = "binned"]` |
| S22 | floor-cleared-at-once | item 3 | extra `Next` disjunct throwing out every floor piece at once |
| S23 | throwout-yields-malt | rule 5, amb 10 | `ThrowOut`: outcome falls out of `Ready(p)`, so it mirrors `Kiln` |
| S24 | one-exit-act | §5 loss fork | `Remove(m, p) == Kiln(m, p)`, `ThrowOut` unreachable |
| S25 | matted-piece-stuck | item 7, rule 5 | `Remove`: add a `modification[p] < UpperMark` guard |

### Family P, property mutations

| id | name | mutation | run against |
|---|---|---|---|
| P01 | hands-wrong-subscript | `OnePairOfHands` subscripted `_(Observe.stage)` | reference, then S06 |
| P02 | turning-wrong-subscript | `TurningAddsOne` subscripted `_(Observe.stage)` | reference, then S07 |
| P03 | final-wrong-subscript | `OffTheFloorIsFinal` subscripted `_(Observe.modification)` | reference, then S11 |
| P04 | good-malt-lower-only | `GoodMaltComesFromReady`: drop the `< UpperMark` conjunct | reference, then S09 |
| P05 | count-typed-to-the-marks | `TypeOK` types the count `0..UpperMark`, `CountBelongsToTheFloor` drops its ceiling clause | reference, then S03 |
| P06 | hands-reads-stage-only | `OnePairOfHands` drops both `modification` clauses | reference, then S06 |

P01 through P03 are the wrong-subscript probes §9.5 asks for, one per action
property that can go blind. `DESCRIPTION.md` section 2 states the hazard in
English and names both directions of it, so these measure a stated claim rather
than a guess. P06 is the same escape reached by a different weakening, reading
one field instead of moving the subscript.

P04 and P05 aren't subscript probes. They ask which line grades the late side of
the window, and whether the description's named typing trap is real. Section 3
of the description argues that typing the count `0..UpperMark` makes item 2's
ceiling true by construction. P05 measures it.

### The variants I expect to come back green

On the record before the runs, not read back afterwards.

- **S13, S14, S16.** All three are fairness forms that still clear the floor.
  The description says so for S13 and gives the counting argument. S16 obliges
  more than item 7 asks, which no obligation here can object to.
- **S17.** Every stated obligation survives a floor nobody turns. Only a probe
  that knows `Turn` is supposed to exist can see it, and `Turn` is deleted from
  `Next` rather than guarded false, so it's V2-PLAN §5.3's deletion shape.
- **S18.** `Spec` should admit no behaviour at all, because the `WF` conjunct
  demands a step `Next` forbids. That's §5.3's fourth vacuity vector, and the
  first three probes are blind to it by construction.
- **S23 and S24.** Both are ambiguity 10 wearing different clothes. `Observe`
  can't tell a kilning from a throwing out, so no property over it can.
- **Every P variant against the reference.** A weakening is implied by the form
  it weakens, so the reference satisfies it. A red here would mean I got the
  weakening wrong.
- **P01, P02, P03, P06 against their paired system variant.** The escape is what
  they're built to show.

I expect **S19** to come back as an evaluation failure rather than a verdict.
Turning a piece off the floor reads `NoCount` in an arithmetic comparison, and
`ALTERNATIVES.md` records that TLC aborts on that rather than returning `FALSE`.
An abort is not a catch, and V2-PLAN §5.1 is clear that the evaluation-failure
rows are not violation rows.

`DESCRIPTION.md` has no section 7 and this rung is shape A, so there's no
seeded-defect variant to build.

### What counts as caught

An invariant catches at rc=12 and an action or temporal property at rc=13, per
§9.5 step 5 and bead `tla-94n`. rc=124 is `TIMEOUT` and is never read as
uncaught. Anything else is recorded as itself.

The verdict comes from the exit code and only from the exit code. The obligation
name comes from the log, which is where a name is allowed to come from.

## 2. The reference's own gate

Every run goes through `harness/verdict.sh`, so the verdict is the raw exit code
and nothing reads TLC's stdout. `Gate.tla` is found through
`JAVA_TOOL_OPTIONS="-DTLA-Library=$WT/harness"` with the module passed as an
absolute path, which is the combination `harness/vacuity.sh:238-252` records as
the one that works. A relative module path searches the cwd instead and ignores
`TLA-Library`, so the first postcondition run came back `PARSE_ERROR` at rc=150
on a `Gate.tla` that was sitting right there. Worth knowing before you debug it.

`$REF` below is `authoring/floor-malting/reference/`.

```
harness/verdict.sh -t 300 -c $REF/Maltings.cfg $REF/Maltings.tla
    OK                    rc=0     0.8 s
harness/verdict.sh -t 300 -c $REF/Maltings.cfg $REF/Maltings.tla -- -inv FALSE
    SAFETY_VIOLATION      rc=12    0.4 s
harness/verdict.sh -t 300 -c $REF/Maltings.cfg -p Gate!NonVacuous $REF/Maltings.tla
    OK                    rc=0     0.9 s
```

Counts, from the plain run: **2,377 states generated, 216 distinct**, depth 10,
3 branches of temporal properties. `DESCRIPTION.md` section 4 computed 216 by
hand as six records per piece cubed, and called it the count rather than a
ceiling on it. The count is 216, so the arithmetic was right.

Action coverage, from the same run's `-coverage 1` table. The predicate is
`total == 0`, not `distinct == 0`.

| action | distinct : total |
|---|---|
| `Init` | 1 : 1 |
| `Turn` | 129 : 666 |
| `Kiln` | 86 : 882 |
| `ThrowOut` | 0 : 882 |

No action sits at zero total, so nothing here is dead. `ThrowOut` at `0 : 882`
is the case the plan warns about, and it isn't a PlusCal `Terminating` row. It's
an action that fires 882 times and discovers nothing new, because every state it
reaches is already reached by a `Kiln` of a green piece. That's ambiguity 10
showing up in the coverage numbers, and finding 2 picks it up.

The vacuity suite over the reference, with a floor of 216 and the three action
names the description's rules require:

```
harness/vacuity.sh -c $REF/Maltings.cfg -n 216 \
    --expect-actions Turn,Kiln,ThrowOut --observe Observe $REF/Maltings.tla
    NON_VACUOUS           rc=0
```

All five probes pass. The space holds at least 216 distinct states, an
`INVARIANT` is configured, `Spec` admits a behaviour, every expected action
reached the coverage block, and both fields of `Observe` take more than one
value. Read finding 4 before you copy that `--expect-actions` list forward.

### The vector, read off the artifact

The rung block carries **2 3 2 1 0 0**. Read from `Maltings.tla` and
`Maltings.cfg`, that's what's there.

- **representation 2.** `VARIABLES stage, modification`, and `Observe` is the
  identity over them field for field. No third variable, no history variable, no
  `pc`. The module is plain TLA+, so there's no process set to carry one.
- **property kind 3.** `TheFloorGetsCleared` is a `~>`, and `Spec` carries weak
  fairness per piece on `Remove`. That's a named step, not `WF_vars(Next)`. One
  nuance, and it's the description's own choice rather than a slip: the conjunct
  is per piece, not per party. The parties here are the maltsters, and no
  maltster is named under `WF` at all. Finding 6 is about what that costs.
- **property count 2.** Two `INVARIANTS` lines and six `PROPERTIES` lines, eight
  in all, which is band 2's five to nine.
- **step sources 1.** One kind of party, several of them, quantified over
  `Maltsters` in `Next`. No clock and no unprompted step.
- **state space 0.** 0.8 s wall and 216 distinct, against band 0's one second
  and 1,000 states.

The sixth level is form left open, which is read from the statement, and there's
no statement yet. Nothing to check.

## 3. Results

Every variant ran with the same command, changing only the module path:

```
harness/verdict.sh -t 300 -c $REF/Maltings.cfg $VAR/<id>.tla
```

The reference's own cfg is used throughout, so no variant passed by having its
obligations edited. The obligation name is read out of the log. The verdict is
the exit code alone.

### Family S

| id | token | rc | obligation reported | distinct | trace |
|---|---|---|---|---|---|
| S01 | `LIVENESS_VIOLATION` | 13 | `S01` line 69, by source location | n/a | initial state |
| S02 | `LIVENESS_VIOLATION` | 13 | `S02` line 68, by source location | n/a | initial state |
| S03 | `SAFETY_VIOLATION` | 12 | `CountBelongsToTheFloor` | 61 | 5 states |
| S04 | `SAFETY_VIOLATION` | 12 | `CountBelongsToTheFloor` | 3 | 2 states |
| S05 | `SAFETY_VIOLATION` | 12 | `CountBelongsToTheFloor` | 4 | 2 states |
| S06 | `LIVENESS_VIOLATION` | 13 | `OnePairOfHands` | 4 | 2 states |
| S07 | `LIVENESS_VIOLATION` | 13 | `TurningAddsOne` | 2 | 2 states |
| S08 | `LIVENESS_VIOLATION` | 13 | `GoodMaltComesFromReady` | 3 | 2 states |
| S09 | `LIVENESS_VIOLATION` | 13 | `GoodMaltComesFromReady` | 60 | 5 states |
| S10 | `LIVENESS_VIOLATION` | 13 | `OffTheFloorIsFinal` | 13 | 3 states |
| S11 | `LIVENESS_VIOLATION` | 13 | `OffTheFloorIsFinal` | 30 | 4 states |
| S12 | `LIVENESS_VIOLATION` | 13 | `TheFloorGetsCleared` | 216 | 6 states, then stuttering |
| S13 | `OK` | 0 | none | 216 | uncaught, predicted |
| S14 | `OK` | 0 | none | 216 | uncaught, predicted |
| S15 | `LIVENESS_VIOLATION` | 13 | `TheFloorGetsCleared` | 216 | 7 states, then stuttering |
| S16 | `OK` | 0 | none | 216 | uncaught, predicted |
| S17 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | 8 | uncaught, predicted |
| S18 | `OK` | 0 | `Gate!NonVacuous` at rc=10 | 1 | 1 state |
| S19 | `TLC_EXCEPTION` | 255 | evaluation failure, finding 8 | 13 | not a verdict |
| S20 | `SAFETY_VIOLATION` | 12 | `CountBelongsToTheFloor` | n/a | initial state |
| S21 | `SAFETY_VIOLATION` | 12 | `TypeOK` | 4 | 2 states |
| S22 | `LIVENESS_VIOLATION` | 13 | `OnePairOfHands` | 4 | 2 states |
| S23 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | 216 | uncaught, predicted |
| S24 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | 216 | uncaught, predicted |
| S25 | `LIVENESS_VIOLATION` | 13 | `TheFloorGetsCleared` | 216 | 7 states, then stuttering |

The trace column counts real states. A liveness row excludes the `Stuttering`
line TLC prints last, so S12's six states are six real states and then the
behavior stops moving.

19 of 25 caught, 18 by an obligation and S18 by the vacuity gate. No run hit
rc=124, so nothing here is a timeout wearing a pass. The six that came back rc=0
are six of the seven the frozen matrix named in advance. S18 is the seventh, and
I named the wrong instrument for it. Finding 7.

### Family P

| id | token | rc | obligation reported |
|---|---|---|---|
| P01ref | `OK` | 0 | none |
| P01s06 | `OK` | 0 | none, and S06 alone is rc=13 |
| P02ref | `OK` | 0 | none |
| P02s07 | `SAFETY_VIOLATION` | 12 | `CountBelongsToTheFloor`, 3 states |
| P03ref | `OK` | 0 | none |
| P03s11 | `OK` | 0 | none, and S11 alone is rc=13 |
| P04ref | `OK` | 0 | none |
| P04s09 | `OK` | 0 | none, and S09 alone is rc=13 |
| P05ref | `OK` | 0 | none |
| P05s03 | `SAFETY_VIOLATION` | 12 | `TypeOK`, 5 states |
| P06ref | `OK` | 0 | none |
| P06s06 | `OK` | 0 | none, and S06 alone is rc=13 |

Every rc=0 row above was run again under `-p Gate!NonVacuous` and came back rc=0.

### The vacuity suite over the green system variants

Run with `-n 216 --expect-actions Turn,Kiln,ThrowOut --observe Observe`.

| id | token | rc |
|---|---|---|
| S13, S14, S16, S23 | `NON_VACUOUS` | 0 |
| S17 | `VACUOUS_EMPTY_SPACE`, 8 states against 216 | 3 |
| S18 | `VACUOUS_EMPTY_SPACE`, 1 state against 216 | 3 |
| S24 | `VACUOUS_DEAD_ACTION`, `ThrowOut` has no coverage row | 5 |

Three isolating runs, because a floor of 216 masks which instrument would
otherwise have fired:

```
vacuity.sh -n 4   --expect-actions Turn,Kiln,ThrowOut --observe Observe S17.tla
    VACUOUS_DEAD_ACTION   rc=5    Turn has no coverage row
vacuity.sh -n 4   --expect-actions Turn,Kiln,ThrowOut --observe Observe S18.tla
    VACUOUS_EMPTY_SPACE   rc=3    1 state against 4
vacuity.sh -n 216 --observe Observe S24.tla
    NON_VACUOUS           rc=0
```

## 4. Findings

The gate is green. Seven variants stayed uncaught by the eight obligations, and
every one has a named cause. Four of them aren't breaks at all. I don't think
this needs a §9.5b repair, and findings 3 and 6 are why.

### 1. Every obligation in the cfg has an arrow

Eight lines in the cfg, eight variants that catch them, each at the channel
§9.5 step 5 predicts. The two invariants come back at rc=12 and the six
properties at rc=13. Nothing is caught by `TypeOK` standing in for a rule it
doesn't state, and the one variant `TypeOK` does catch (S21, a fourth place
value) is the one aimed at it.

Section 5 has the shortest trace per obligation.

### 2. `ThrowOut` discovers nothing, and that's the design working

`ThrowOut` fires 882 times and finds 0 new states. A kilning of a green piece
and a throwing out of the same piece land on the same record, so the second
action can only re-reach what the first already reached. `DESCRIPTION.md`
section 3 says `Observe` can't tell them apart, and here that claim is a number
rather than an argument.

This is also the sharpest live case for the `total == 0` predicate over
`distinct == 0`. Read the wrong column and the reference itself reports a dead
action.

### 3. S23 and S24 are structurally uncatchable, and they're the same finding

S23 gives a throwing out the same outcome rule as a kilning, which breaks
Rule 5's claim that a throwing out is always a loss. S24 deletes `ThrowOut`
altogether and routes `Remove` through the kiln. Both come back rc=0 against all
eight obligations, both at 216 distinct states, both `NON_VACUOUS`.

Neither is a hole in the property set. `Observe` carries where a piece went and
not how it got there, so no property over `Observe` can separate the two exits.
The description says this twice, in section 3 and again at ambiguity 10, and
predicts a reviewer will hunt for the missing property. Consider it hunted.

S24 also reaches the reference's exact 216 states, which says the two-act and
one-act models are indistinguishable on the state graph as well as on the
obligations. Section 5's loss fork is a real fork.

### 4. `--expect-actions` is a representation decision, and mine was wrong

S24 came back `VACUOUS_DEAD_ACTION` at rc=5 only because my probe list named
`ThrowOut`. Drop the list and the same module is `NON_VACUOUS` at rc=0.

That matters downstream, because S24 is a model `DESCRIPTION.md` section 5
permits outright. A grading run that passes `--expect-actions
Turn,Kiln,ThrowOut` refuses a correct submission, and refuses it with a message
telling the learner to put `ThrowOut` back into `Next`. Step 4 should pass
`--expect-actions Turn` and nothing else, or pass no list at all.

`Turn` is safe to demand, because S17 shows the obligations alone can't see a
floor nobody turns. `Kiln` and `ThrowOut` aren't, because the description says
the exit is the learner's to shape.

### 5. Item 5's late-side conjunct is load-bearing

P04 drops `< UpperMark` from `GoodMaltComesFromReady`, and S09 then escapes at
rc=0. S09 is a matted piece coming out of the kiln as good malt, and with the
conjunct dropped nothing in the cfg objects.

That's worth stating against qsl's finding 3, where the analogous defensive
conjunct turned out not to be carrying anything. Here it is. The description
argued for replacing the sketch's "kilned below the lower mark is a loss" with a
rule grading both marks at once, on the grounds that the late side is half of
why the domain was picked. The measurement backs the change.

### 6. Four fairness forms, and the obligations reject only one

| variant | form | rc |
|---|---|---|
| reference | per piece, on `Remove` | 0 |
| S13 | `WF_vars(Next)` | 0 |
| S14 | per maltster, on any act of that maltster | 0 |
| S16 | per piece, on the kilning alone | 0 |
| S12 | none | 13 |
| S15 | per piece, on the turning alone | 13 |

S13 is the "a maltster acts" form the description discusses, and here it's
literally `WF_vars(Next)`, because every step in this system is a maltster's.
The description's counting argument holds: Rule 3 caps the turnings, so only
finitely many acts can be turnings and the rest take a piece off the floor. S14
is the same argument run one maltster at a time.

So the shipped obligations can't insist on the per-piece form. The reason for
preferring it is that it names a step the reader can point at, which is a
pedagogical reason and not a gradeable one. This problem is shape A, so the
learner writes `Spec` and picks the fairness. A grader that wanted the per-piece
form would have to say so in the statement, and I don't think it should. Three
correct answers are three correct answers.

S15 is the useful negative. Fairness on the turning alone leaves a piece sitting
at `UpperMark` on the floor forever, and item 7 catches it at 7 states and a
stutter. So the conjunct has to name the removal, and that much is graded.

### 7. S18 is caught, and I named the wrong probe for it

I predicted `Spec` would come back unsatisfiable and that the first three
vacuity probes would be blind to it, per V2-PLAN §5.3's fourth vector. `Spec` is
unsatisfiable, and the probes aren't blind. `Next == UNCHANGED vars` collapses
the space to one state, so `Gate!NonVacuous` fires at rc=10 and
`VACUOUS_EMPTY_SPACE` fires at rc=3, both well before the temporal probe runs.

The prediction was about the wrong mutation. §5.3's fourth vector drops one
action and keeps the rest, so the space stays healthy. Mine dropped all of them.
I'd want a variant that drops a single action while keeping the `WF` conjunct on
it before claiming anything measured about that vector here, and I didn't build
one. That's a gap in the matrix, and I'd rather record it as one than dress up
what I did measure.

### 8. A turning off the floor aborts, and a tutor must not call it a violation

S19 drops the floor guard on the turning, so a maltster can turn a piece that's
already gone to the kiln. The count of an off-floor piece is `NoCount`, and
TLC's answer is `The first argument of < should be an integer`, at rc=255
`TLC_EXCEPTION` after 13 states.

That's an evaluation failure, and V2-PLAN §5.1 is clear that those aren't
violation rows. `OffTheFloorIsFinal` would have caught the behavior. It never
got the chance, because the abort happens in the next-state relation before any
property is evaluated.

`ALTERNATIVES.md` predicted this shape, and predicted it for a different reason.
The author was arguing about the marker's encoding, not about a dropped guard.
The prediction covers both. It's the arithmetic that aborts, and it doesn't care
which side put a marker into it.

Downstream this is a live failure mode for shape A. The learner writes the step
rules, and a learner who forgets a guard gets rc=255 rather than a violation. A
tutor reading that as "your property was violated" would be making the exact
false statement §5.1 exists to stop.

### 9. Two of three wrong-subscript probes escape, and the third is masked

`OnePairOfHands` subscripted on the stage field goes blind to S06's floor-wide
sweep, which changes no stage. `OffTheFloorIsFinal` subscripted on the count
field goes blind to S11's regrading of malt to loss, which changes no count.
Both come back rc=0, and both system variants are rc=13 under the shipped
subscript.

P06 reaches the same escape a different way. It leaves the subscript alone and
narrows the property to read the stage field only. S06 escapes that too. So the
hazard isn't really about the subscript. It's about a property that reads less
of `Observe` than the rule it states.

P02 is the one that doesn't reproduce. `TurningAddsOne` subscripted on the stage
field does go blind to S07's double turn, and S07 is then caught anyway at rc=12
by `CountBelongsToTheFloor`, because turning by two overshoots `UpperMark` and
lands at 4. The coverage is incidental. A learner with the wrong subscript
passes S07 for a reason that has nothing to do with the property they got wrong.
Same shape as qsl's finding 8, one problem over.

### 10. The typing trap is real, and it moves the catch to `TypeOK`

P05 types the count `0..UpperMark` and drops item 2's ceiling clause, which is
the tidier-looking model the description warns against. The reference still
passes at rc=0. S03, a turning with no ceiling guard, is still caught at rc=12,
by `TypeOK` rather than by `CountBelongsToTheFloor`.

So the trap doesn't cost the catch. It costs the obligation. Item 2's ceiling
becomes true by construction, the learner writes it and it grades nothing, and
the arrow that fires belongs to the type invariant the learner was never asked
to produce. The description called this "TRUE in a costume", and that's the
right name for it.

### 11. Item 1 arrives as a source location, and a broken opening can beat it

S01 reports `Property line 69, col 12 to line 69, col 38 of module S01 is
violated by the initial state`, with no operator name. TLC splits a `PROPERTIES`
state predicate into implied inits per conjunct, so `Opening` never appears.
That's qsl's finding 5 reproducing on a second problem, which I'd now treat as
how TLC behaves rather than as a quirk of one module.

S02 breaks the stage half of the same opening and lands one line up, at line 68.
So the two conjuncts get separate arrows, which is useful if a tutor wants to
say which half of the opening is wrong.

S20 is the other half of qsl's finding 6. An `Init` with every piece on the
floor carrying the none marker breaks both `Opening` and
`CountBelongsToTheFloor`, and the invariant wins at rc=12. So item 1 gets its
own arrow only when the opening is otherwise well formed, which is S01 and S02.

### 12. A per-problem state floor of 216, and why the placeholder doesn't hold

S17 removes the turning entirely and reaches 8 distinct states. It passes all
eight obligations at rc=0 and passes `Gate!NonVacuous` at rc=0, because 8 clears
the placeholder threshold of 4. Only a floor set for this problem catches it,
and at 216 it comes back rc=3.

I'd set the floor at 216. The reasoning, and it's reasoning rather than
measurement: section 5's forks either leave the count alone or raise it. A
partition of `Pieces` into three named sets is isomorphic to the status
function, and a sequence of identical turnings is determined by its length, so
both land on 216. A stored gone-over flag adds a variable and can only add
states. I don't see a legitimate model of this instance that reaches fewer than
216, and a transcription of a published trace reaches far fewer.

That's a recommendation and not a decision. Setting the shipped floor is
central's, per the `tla-dk7w` note.

### 13. One trace length moved, and then held

S12's counterexample counted 7 real states on the first pass of the batch and 6
on the six passes after, five of them at five different fingerprint seeds. I
can't reproduce the 7 and I'm not going to claim I know what it was.

Worth a line because the statement author is about to publish one of these
traces, and a liveness counterexample is picked out of a strongly connected
component rather than computed. I'd re-run before publishing rather than trust
the number in the table above.

## 5. For the statement author

The shortest caught variant per obligation, with its trace length. These are the
violating halves of §3.9's trace pairs. Satisfying halves come from the
reference, which is green.

| obligation | channel | variant | trace |
|---|---|---|---|
| `TypeOK` | rc=12 | S21 | 2 states |
| `CountBelongsToTheFloor` | rc=12 | S04 | 2 states |
| `Opening` | rc=13 | S01 | initial state |
| `OnePairOfHands` | rc=13 | S06 | 2 states |
| `TurningAddsOne` | rc=13 | S07 | 2 states |
| `GoodMaltComesFromReady` | rc=13 | S08 | 2 states |
| `OffTheFloorIsFinal` | rc=13 | S10 | 3 states |
| `TheFloorGetsCleared` | rc=13 | S12 | 6 states, then a stutter |

Four picks are worth a line each.

`CountBelongsToTheFloor` gets S04, a kilning that keeps the count, over S20,
which breaks the same rule in the initial state. S20's opening breaks `Opening`
too, and finding 11 says the invariant beats it, so a reader can't tell which
rule the trace is about. S04 is one step and one rule.

`Opening` gets S01, the whole floor turned once, and its arrow is a source
location rather than a name. If the statement names obligations, this one has no
name to give. S02 is the same shape on the stage field if that's the half you
want to show.

`OffTheFloorIsFinal` gets S10, a thrown-out piece coming back to the floor,
which is the description's own item 6 trace. S11 regrades malt to loss at 4
states and shows the same rule one step later.

`TheFloorGetsCleared` is the liveness one, so its violating half is a lasso. S12
drops fairness entirely: two pieces get kilned, the third gets turned to
`UpperMark` and lies there, and the behavior stutters forever with it down.
That's the trace `DESCRIPTION.md` section 2 asks for. S25, a floor where a
matted piece can never be removed, is the same ending reached by a system defect
rather than by missing fairness, at 7 states.
