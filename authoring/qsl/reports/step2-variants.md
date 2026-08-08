# qsl step 2 — reference verification and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/qsl/reference/Bureau.tla` and
`Bureau.cfg` at commit `5dba583`. I did not write the reference. Bead
`tla-kstb`.

The matrix in section 1 was authored and frozen before I ran TLC once. Section
2 records the reference's own gate. Section 3 records what each variant did.
Section 4 carries the findings, including the variants nothing caught and why.

Downstream this problem is shape B, so the learner writes the properties and
the statement ships one satisfying and one violating trace per property. Every
caught variant below is candidate material for the violating half, and section
3 records the trace length so the statement author can pick without re-running
anything.

## 1. The frozen matrix

Two families. Family S mutates the system (the `Init`, `Next`, action and
fairness half of the module) and leaves all ten obligations in the `.cfg`
untouched. That is the §5.5 shape: a broken bureau, graded by the properties
the learner is meant to write.

Family P mutates a property instead and asks whether the weakened form still
catches a system variant that the shipped form catches. Shape B puts the
properties in the learner's hands, so a property that passes while missing a
real break is the failure mode this problem grades on. Three probes, no more.

Every mutation below is stated against the reference text, so the matrix reads
as a diff without needing the files.

### Family S — system mutations

| id | name | targets | mutation |
|---|---|---|---|
| S01 | opening-seeded | item 1 | `Init`: `filed = [o \in Operators \|-> ClaimsBy(o)]` |
| S02 | mail-replaces | item 2 | `Mail`: `filed' = [filed EXCEPT ![o] = env]` |
| S03 | mail-allows-self | item 3 | `Mail` draws from `SUBSET [station : Operators, band : Bands]` |
| S04 | mail-carbon-copy | item 4 | extra `Next` disjunct filing one claim into each of two files in one step |
| S05 | credit-ungated | item 5 | `Credit`: drop the `Corroborated(a, c, b)` conjunct |
| S06 | credit-one-sided | item 6 | `Credit`: drop the `![c]` half of the `EXCEPT` |
| S07 | credit-batches-bands | item 7 | `Credit` takes a pair and credits every corroborated band at once |
| S08 | credit-files-its-own-proof | items 4 and 7 | extra disjunct that files the mirror claim and credits the fact in one step |
| S09 | credit-expires | item 8 | extra disjunct removing one credited fact from both sides |
| S10 | fairness-dropped | item 9 | `Spec`: drop `WF_vars(CreditStep)` |
| S11 | credit-self | step-1 flag, item 7's `a # c` | extra disjunct adding `[station \|-> a, band \|-> b]` to `credited[a]` |
| S12 | fairness-one-band | item 9 | `Spec`: `WF_vars` over `Credit(a, c, CHOOSE b \in Bands : TRUE)` only |
| S13 | credit-mirrors-wrong-band | item 6 | `Credit`: the `![c]` half records a band other than `b` |
| S14 | credit-overwrites-register | item 8 | `Credit`: `![a] = {fact}` and `![c] = {fact}`, replacing rather than adding |
| S15 | typeok-station-is-band | `TypeOK` | `Credit` records a band value in the `station` field |
| S16 | mail-empty-envelope | rule 2 | `Mail`: `\E env \in SUBSET ClaimsBy(o)`, keeping the empty envelope |
| S17 | mail-single-claim | rule 2 | `Mail` files one claim per step, never an envelope |
| S18 | credit-once-guard-dropped | rule 4 | `Credit`: drop the `\notin credited[a]` conjunct |
| S19 | credit-one-sided-corroboration | item 5 | `Credit` guards on `[station \|-> c, band \|-> b] \in filed[a]` alone |
| S20 | bureau-never-credits | item 9 | `Next == \E o \in Operators : Mail(o)` |
| S21 | bureau-does-nothing | vacuity | `Next == CreditStep`, so no file ever grows |
| S22 | init-credited-nonempty | items 1 and 5 | `Init`: `credited = [o \in Operators \|-> ClaimsBy(o)]` |

Four of those I expect to come back green, and I want the expectation on the
record before the runs rather than after. S16 and S18 should be uncatchable
because both mutations produce a step that leaves `Observe` unchanged, which
is stuttering and generates no state. `ALTERNATIVES.md` names the empty
envelope as stutter, and the brief names the credited-once guard's
observational vacuity as declared in advance, so a green result at either is a
finding confirmed and not a hole. S17 should be green because no stated item
constrains how many claims an envelope carries. S21 should be green against
the ten obligations and red only under `Gate!NonVacuous`.

### Family P — property mutations

| id | name | mutation | run against |
|---|---|---|---|
| P01 | comes-whole-wrong-subscript | `CreditComesWhole` subscripted `_(Observe.filed)` | reference, then S07 |
| P02 | only-grow-wrong-subscript | `FilesOnlyGrow` subscripted `_(Observe.credited)` | reference, then S02 |
| P03 | comes-whole-no-a-not-c | `CreditComesWhole`: drop the `a # c` conjunct | reference, then S11 |

P01 and P02 test the step-1 flag about `Observe`-primed action properties going
vacuous under a wrong subscript. A credit step leaves `filed` alone, so
`[][P]_(Observe.filed)` is satisfied by its own stuttering disjunct on every
credit step, and the obligation stops seeing the action it was written for.
P02 is the same move one variable over.

P03 tests the other step-1 flag. `ALTERNATIVES.md` argues the `a # c` conjunct
keeps a self-credit from satisfying `CreditComesWhole` through a collapsed
witness, and concedes that `CreditIsCorroborated` would catch such a step
anyway. P03 measures which of those two claims the harness can see.

### What counts as caught

An invariant catches a variant at rc=12 and an action or temporal property at
rc=13, per §9.5 step 5 and bead `tla-94n`. rc=124 is `TIMEOUT` and is never
read as uncaught. Anything else gets recorded as itself.

For each variant I also name the obligation TLC reported. The verdict comes
from the exit code and only from the exit code. The name comes from the log,
which is where a name is allowed to come from.

## 2. The reference's own gate

Every run below goes through `harness/verdict.sh`, so the verdict is the raw
exit code and nothing reads TLC's stdout. `Gate.tla` is found through
`JAVA_TOOL_OPTIONS="-DTLA-Library=$WT/harness"`, with `$WT` the worktree root.
Module and config paths are absolute, per the `tla-sn0h` note in `verdict.sh`.

```
harness/verdict.sh -t 300 -c $REF/Bureau.cfg $REF/Bureau.tla
    OK                     rc=0     78 s
harness/verdict.sh -t 300 -c $REF/Bureau.cfg $REF/Bureau.tla -- -inv FALSE
    SAFETY_VIOLATION       rc=12     0 s
harness/verdict.sh -t 300 -c $REF/Bureau.cfg -p Gate!NonVacuous $REF/Bureau.tla
    OK                     rc=0     92 s
```

The third command was run again after an interrupted session, to check that
nothing here rests on a cached number. `OK`, rc=0, 77 s.

Counts, from the plain run: 740,626 states generated, 15,625 distinct, depth
10, and 18 branches of temporal properties. Those match what step 1 recorded
at `5dba583`.

Action coverage, from the same run's final table. The check is `total == 0`,
not `distinct == 0`.

| action | distinct : total |
|---|---|
| `Init` | 1 : 1 |
| `Mail` | 4,095 : 703,665 |
| `Credit` | 11,529 : 37,524 |

No action sits at zero. Both halves of the next-state relation fire.

## 3. Results

Each variant ran with the same command, changing only the two paths:

```
harness/verdict.sh -t 300 -c $VAR/<id>/Bureau.cfg $VAR/<id>/Bureau.tla
```

All 29 configs (the reference plus 28 variants) hash to
`8e11a0900599db7666c5e761d0d7dae1`, so every variant met the shipped
obligations unchanged. Any variant returning rc=0 was then run a second time
with `-p Gate!NonVacuous`.

The obligation column is read out of the log, which is where a name is allowed
to come from. The verdict is the exit code alone.

### Family S

| id | token | rc | obligation reported | trace |
|---|---|---|---|---|
| S01 | `LIVENESS_VIOLATION` | 13 | `Opening`, by source location (see finding 5) | initial state |
| S02 | `LIVENESS_VIOLATION` | 13 | `FilesOnlyGrow` | 3 states |
| S03 | `SAFETY_VIOLATION` | 12 | `FilesWellFormed` | 2 states |
| S04 | `LIVENESS_VIOLATION` | 13 | `OneEnvelopeAtATime` | 2 states |
| S05 | `SAFETY_VIOLATION` | 12 | `CreditIsCorroborated` | 2 states |
| S06 | `SAFETY_VIOLATION` | 12 | `CreditIsMutual` | 4 states |
| S07 | `LIVENESS_VIOLATION` | 13 | `CreditComesWhole` | 4 states |
| S08 | `LIVENESS_VIOLATION` | 13 | `OneEnvelopeAtATime` | 3 states |
| S09 | `LIVENESS_VIOLATION` | 13 | `CreditComesWhole` | 5 states |
| S10 | `LIVENESS_VIOLATION` | 13 | `BureauKeepsUp` | 5 states, then stuttering |
| S11 | `SAFETY_VIOLATION` | 12 | `CreditIsCorroborated` | 2 states |
| S12 | `LIVENESS_VIOLATION` | 13 | `BureauKeepsUp` | 5 states, then stuttering |
| S13 | `SAFETY_VIOLATION` | 12 | `CreditIsCorroborated` | 4 states |
| S14 | `LIVENESS_VIOLATION` | 13 | `CreditComesWhole` | 5 states |
| S15 | `SAFETY_VIOLATION` | 12 | `TypeOK` | 4 states |
| S16 | `OK` | 0 | none, and `Gate!NonVacuous` also rc=0 | uncaught |
| S17 | `OK` | 0 | none, and `Gate!NonVacuous` also rc=0 | uncaught |
| S18 | `OK` | 0 | none, and `Gate!NonVacuous` also rc=0 | uncaught |
| S19 | `SAFETY_VIOLATION` | 12 | `CreditIsCorroborated` | 3 states |
| S20 | `LIVENESS_VIOLATION` | 13 | `BureauKeepsUp` | 5 states, then stuttering |
| S21 | `OK` | 0 | `Gate!NonVacuous` at rc=10 | 1 state |
| S22 | `SAFETY_VIOLATION` | 12 | `CreditIsCorroborated` | initial state |

19 of 22 caught, 18 of them by an obligation and S21 by the vacuity gate. No
run hit rc=124, so nothing here is a timeout wearing a pass.

The four variants that came back rc=0 are the four the frozen matrix named in
advance. I want that on the record as a prediction that held, not as a result
read backwards.

### Family P

| id | token | rc | obligation reported |
|---|---|---|---|
| P01ref | `OK` | 0 | none |
| P01s07 | `OK` | 0 | none, and S07 alone is rc=13 |
| P02ref | `OK` | 0 | none |
| P02s02 | `LIVENESS_VIOLATION` | 13 | `BureauKeepsUp` |
| P03ref | `OK` | 0 | none |
| P03s11 | `SAFETY_VIOLATION` | 12 | `CreditIsCorroborated` |

## 4. Findings

The gate is green. Three variants stayed uncaught, each with a named
structural cause, and §6's rule is that an uncatchable variant with a named
cause is a finding rather than a failure. I don't think this needs a §9.5b
repair, and finding 1 is why: no property change can close any of the three.

### 1. The three uncaught variants are all structurally uncatchable

S16 and S18 were declared in advance, S16 by `ALTERNATIVES.md` and S18 by the
brief. Both hold up, and the state counts say why. Each comes back at 15,625
distinct states, the reference's own count. S16 adds 46,875 generated states
and S18 adds 37,500, and every one of them folds into a state that already
exists. Both mutations add self-loops and nothing else, so under `Observe`
there is nothing to see.

S17 was not declared, and it's the one I'd carry forward. Single-claim mail
reaches the same 15,625 states in 225,001 generated, so the two mailing
disciplines are indistinguishable state by state. No property in the shipped
set can catch it, and I don't think any linear-time property can: "an envelope
of two claims is possible" is a claim about a behavior existing, and a safety
or liveness property constrains the behaviors that do exist. It's invisible to
the state count as well, since the count is identical. Only a check over the
step relation would see it.

That lands where the bead's carried note already pointed, at Rule 2's envelope
permission wanting a carrier declaration on the next description pass. The gap
is in the handoff's list of must-be-trues, not in the reference.

### 2. `CreditIsPermanent` has no independent arrow

Item 8 is implied by item 7. Any step that loses credit changes `credited`, so
`CreditComesWhole` applies, and its consequent forces `credited'[o]` to be a
superset of `credited[o]` for every operator. The implication is one line.

The measurement agrees. S09 and S14 were both authored to break item 8, and
both were reported against `CreditComesWhole`. Nothing in the matrix was
caught by `CreditIsPermanent`.

This matters downstream. Shape B ships one violating trace per property, and
item 8's violating trace will always violate item 7 too. Say so in the
statement, or a learner who writes only item 7 looks wrong when they aren't.

### 3. The `a # c` conjunct is defensive, not load-bearing

P03s11 drops the conjunct and S11 is still caught, at rc=12 by
`CreditIsCorroborated`. That's what `ALTERNATIVES.md` predicted, so the
author's reasoning holds.

I went looking for a variant that would exercise the conjunct on its own and
couldn't build one. A collapsed witness needs a self-claim on file, and
`FilesWellFormed` forbids that, so any variant reaching the collapse trips an
earlier obligation first. Keep the conjunct if you like the step obligation
standing alone, which is the author's stated reason. Just don't expect the
harness to defend it.

### 4. Item 6's subtle break routes to item 5

S13 mirrors the credit onto the wrong band, and it came back against
`CreditIsCorroborated` rather than `CreditIsMutual`. The wrong-band entry has
no corroboration behind it, and the invariant that notices sits earlier in the
config. So S13 is not usable as an item-6 trace. S06 is, at 4 states.

### 5. Item 1's arrow arrives as a source location

S01 reported `Property line 47, col 12 to line 47, col 32 of module Bureau is
violated by the initial state`. TLC splits a `PROPERTIES` state predicate per
top-level conjunct into implied inits, and names the location rather than
`Opening`. Step 1 measured the same split, and this is the second reading.

A tutor that reports the obligation by name has no name to report here. Worth
knowing before something downstream tries.

### 6. A pre-loaded register routes to item 5, not item 1

S22 starts `credited` non-empty and was reported against
`CreditIsCorroborated` at the initial state. The invariant beats the implied
init. So item 1 gets its own arrow only when the opening is well formed and
non-empty, which is S01.

### 7. The wrong-subscript hazard reproduces, and it's the sharpest result here

S07 alone is caught at rc=13 by `CreditComesWhole`. The same system mutation,
with `CreditComesWhole` subscripted `_(Observe.filed)` instead of `_Observe`,
comes back rc=0. A credit step leaves `filed` alone, so the property is
satisfied by its own stuttering disjunct and never looks at the action it was
written for.

Under shape B the learner writes that subscript. This is a live failure mode
for the problem, not a hypothetical, and step 1 flagged it before I ran
anything.

### 8. P02 didn't reproduce the escape, and the reason is worth keeping

`FilesOnlyGrow` under `_(Observe.credited)` does go blind to mail steps. S02
was then caught anyway, at rc=13 by `BureauKeepsUp`, over a 7-state lasso. A
file that shrinks can lose its corroboration, and the leads-to still wants the
credit.

The coverage is incidental. A learner whose `FilesOnlyGrow` carries the wrong
subscript still passes S02, and passes for a reason that has nothing to do
with the property they got wrong. I'd treat a green run on a single variant as
weak evidence about a single property, in this problem more than most.

### 9. S21 is the vacuity gate earning its place

A bureau with no mail step passes all ten obligations at rc=0 and fails
`Gate!NonVacuous` at rc=10. One distinct state against a threshold of 4, and
every obligation is vacuously true over it. It's the only variant here that
the postcondition alone catches, which is the argument for running the gate on
every grading run rather than only on the reference.

The threshold of 4 is `Gate.tla`'s placeholder. At 15,625 the reference clears
it by a wide margin, so a per-problem threshold is worth setting later. Not
mine to set here.

### 10. Trace candidates for the shape-B statement

One violating trace per stated item, all well under 12 states. Satisfying
traces come from the reference, which is green.

| item | variant | trace |
|---|---|---|
| 1 the opening | S01 | initial state |
| 2 files only grow | S02 | 3 states |
| 3 files are well formed | S03 | 2 states |
| 4 one envelope at a time | S04 | 2 states |
| 5 credit is corroborated | S19 | 3 states |
| 6 credit is mutual | S06 | 4 states |
| 7 credit comes whole | S07 | 4 states |
| 8 credit is permanent | S09 | 5 states, and see finding 2 |
| 9 the bureau keeps up | S10 | 5 states, then stuttering |

S19 is the pick for item 5 over S05, which violates at 2 states by crediting
with no claims at all. S19 credits on one operator's word, which is the
mistake a person would make. Same for S07 over S08 at item 7, and for S09 over
S14 at item 8.
