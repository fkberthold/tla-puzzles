# laytime step 2: reference verification and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/laytime/reference/Laytime.tla` and
`Laytime.cfg`. I didn't write the reference. Rung 2 of batch 2, bead
`tla-h2cg.8`, load vector 2 2 1 0 0 0.

The matrix in section 1 was authored and frozen before I ran TLC once. Section 2
records the reference's own gate and the vector check. Section 3 records what
each variant did. Section 4 carries the findings, including the variants nothing
caught and why. Section 5 is the trace-pair material for the statement author.

This is shape A, so the learner writes the whole spec and its `Observe` from
prose and the reference ships to nobody. The variants are a measurement of the
property set, not learner material. Section 5 still names the shortest violating
run per obligation, because §3.9 wants a violating half per property downstream.

## 1. The frozen matrix

Two families. Family S mutates the system, meaning `Init`, `Next` and the four
actions, and leaves all four obligations in the cfg untouched. Family P mutates
an obligation and asks whether the weakened form still catches a system variant
the shipped form catches.

Each variant is a standalone TLA+ module rather than a mutated PlusCal block.
The reference's translation is what TLC checks, so mutating the translation
directly is the honest diff. Every variant carries `Observe`, `TypeOK`,
`DemurrageWaitsForAllowance`, `OpensOnceClosesOnce` and `OnePeriodOneMove`
verbatim from the reference unless its row says otherwise.

The reference's four `Next` disjuncts are named here for the diffs below.
**Tender** is disjunct 1, **Working** is disjunct 2, **Excepted** is disjunct 3,
and **Close** is disjunct 4.

### Family S, system mutations

| id | name | targets | mutation |
|---|---|---|---|
| S01 | reckoning-before-notice | item 1, Rule 3 | `Working`: drop `noticeTendered` from the guard |
| S02 | notice-withdrawn | item 1, ambiguity 6 | new disjunct: `noticeTendered' = FALSE`, rest unchanged |
| S03 | statement-reopened | item 1, ambiguity 8 | new disjunct: `finished' = FALSE`, rest unchanged |
| S04 | logging-after-close | item 1, Rule 9 | `Working`: drop `~finished` from the guard |
| S05 | two-periods-at-once | item 2, Rule 6 | `Working`: `laytimeLeft' = laytimeLeft - 2` when `laytimeLeft > 1` |
| S06 | the-last-period-splits | item 2, Rule 7 | `Working`: at `laytimeLeft = 1`, set it to 0 and accrue one |
| S07 | demurrage-runs-early | item 3, Rule 7 | `Working`: accrue demurrage instead of drawing down |
| S08 | allowance-refills | item 2, Rule 6, ambiguity 5 | new disjunct: `laytimeLeft' = laytimeLeft + 1` under `Allowance` |
| S09 | demurrage-falls | item 2, Rule 7 | new disjunct: `demurrage' = demurrage - 1` above zero |
| S10 | opens-tendered | Rule 10, ambiguity 10 | `Init`: `noticeTendered = TRUE` |
| S11 | opens-on-demurrage | item 3, Rule 10 | `Init`: `demurrage = 1`, allowance still full |
| S12 | opens-mid-discharge | Rule 10, ambiguity 10 | `Init`: `laytimeLeft = 0` |
| S13 | no-cap | Rule 9, ambiguity 7 | both logging guards: drop `demurrage < Limit` |
| S14 | excepted-runs-free | Rule 8's second half | `Excepted`: never accrue, leave everything unchanged |
| S15 | never-closes | Rule 9, vacuity | drop the `Close` disjunct from `Next` |
| S16 | nothing-but-the-notice | vacuity | `Next` is the `Tender` disjunct alone |
| S17 | notice-re-tendered | item 1, ambiguity 6 | `Tender`: drop `~noticeTendered` from the guard |
| S18 | closes-before-notice | item 1, Rule 9 | `Close`: drop `noticeTendered` from the guard |
| S19 | allowance-runs-negative | `TypeOK`, Rule 6 | `Working`: draw down with no `laytimeLeft > 0` test |
| S20 | the-clock | Rule 2, ambiguity 3 | new disjunct with `Working`'s guard and effect, taken by nobody |

Seven of those I expect to come back green, and I want the expectation on the
record before the runs rather than after.

S14 is the one the description declares in advance. `Observe` can't see the kind
of a period, and while the allowance stands an excepted period moves no field.
Once it's spent, `Working` already accrues from the same guard, so cutting
`Excepted`'s accrual removes a transition the state graph already has by another
route. DESCRIPTION.md §3 says Rule 8's second half is graded by nothing at all.
This variant is that sentence made runnable.

S17 and S20 are stutters of the same kind. Re-tendering an already tendered
notice changes no field. A clock whose guard and effect match `Working`'s is a
duplicate disjunct, and DESCRIPTION.md §3 already grades Rule 2 as nothing,
because `Observe` shows the statement and not the hand writing it.

S10 and S12 are the opening. DESCRIPTION.md §5 says a fourth must-be-true
pinning `Init` would be a fifth cfg line and would break the rung, so the opening
rides on the model's own `Init` and no obligation watches it. I expect both green.

S15 and S16 should pass all four obligations and fall to the vacuity probes
instead. S16 reaches two states against `Gate!NonVacuous`'s threshold of four.
S15 keeps a healthy space and freezes `finished` at FALSE, which is probe 5's
shape.

### Family P, property mutations

| id | name | mutation | run against |
|---|---|---|---|
| P01 | one-move-wrong-subscript | `OnePeriodOneMove` subscripted `_(Observe.laytimeLeft)` | reference, then S09 |
| P02 | opens-once-wrong-subscript | `OpensOnceClosesOnce` subscripted `_(Observe.noticeTendered)` | reference, then S03 |
| P03 | one-move-no-split-clause | `OnePeriodOneMove`: drop the third conjunct | reference, then S06 |

P01 is §9.5's required wrong-subscript probe. S09 moves `demurrage` and nothing
else, so a rule subscripted on `laytimeLeft` is satisfied by its own stuttering
disjunct and never looks at the step. P02 is the same move on the other property,
against a variant that touches `finished` alone. DESCRIPTION.md §2 warns about
exactly this and names the whole-record subscript as the defense.

P03 asks whether the no-split clause is load-bearing. ALTERNATIVES.md rejects the
one-counter representation because that clause can't fail inside it, so the clause
carries weight in the author's own argument.

There's no kind-3 probe here. This rung is property kind 2, the cfg has no
liveness obligation and `Spec` has no fairness conjunct, so the dropped-fairness
and `WF_vars(Next)` probes have nothing to run against.

There's no shape-D defect either. DESCRIPTION.md stops at section 6 and names no
seeded defect, which is right for shape A. I still run `harness/vacuity.sh` over
the reference and over S14, S15 and S16, because that measurement is what step 4
ships.

### What counts as caught

An invariant catches at rc=12 and an action property at rc=13, per §9.5 step 5
and bead `tla-94n`. rc=124 is `TIMEOUT` and is never read as uncaught. Anything
else gets recorded as itself. A variant caught by `TypeOK` alone is caught for
the wrong reason, and section 3 marks those.

The verdict comes from the exit code and only from the exit code. The obligation
name comes from the log, which is where a name is allowed to come from.

## 2. The reference's own gate

Every run goes through `harness/verdict.sh`, which pins `-workers 1` itself
(`harness/verdict.sh:326`). `Gate.tla` is found through
`JAVA_TOOL_OPTIONS=-DTLA-Library=$WT/harness`, with `$WT` the worktree root.
The module argument is absolute and the config is relative, which is the
combination `harness/vacuity.sh:236-253` measured as the one that resolves
`Gate` from any cwd. My first attempt at check 3 passed the module relative and
came back rc=150 `PARSE_ERROR` on `Cannot find source file for module Gate`, so
that note holds on this build too.

The common form, with `$R` the reference directory:

```
harness/verdict.sh -t 120 --config $R/Laytime.cfg $WT/$R/Laytime.tla [-- ...]
```

| check | extra args | token | rc | wall |
|---|---|---|---|---|
| 1 the full cfg | none | `OK` | 0 | 0.54 s |
| 2 reachable states exist | `-- -inv FALSE` | `SAFETY_VIOLATION` | 12 | 0.54 s |
| 3 the vacuity gate | `-- -postCondition Gate!NonVacuous` | `OK` | 0 | 0.63 s |

Check 2's injected invariant came back as `__DebuggerExpr__1788592367413`, which
is the auto-generated name §5.3 says never to pattern-match. I read the rc.

**Check 4, action coverage.** `verdict.sh` passes `-coverage 1` on every run, so
the block below is from check 1's own log. The predicate is `total == 0`, never
`distinct == 0`.

| disjunct | source lines | distinct : total |
|---|---|---|
| `Init` | 113 | 1 : 1 |
| Tender | 119 to 121 | 1 : 1 |
| Working | 122 to 128 | 4 : 4 |
| Excepted | 129 to 134 | **0 : 4** |
| Close | 135 to 137 | 5 : 5 |

No action sits at zero total, so check 4 passes. The Excepted row is the reason
§5.3 states the predicate the way it does. That branch fires four times and finds
nothing new, because every state it reaches is one Working already reached.
Reading `distinct == 0` here would have failed a healthy reference. Finding 1
picks this up, because it's also why S14 is invisible.

**Check 5, the vacuity probes.** All five pass over the reference:

```
harness/vacuity.sh -n 11 --observe Observe $WT/$R/Laytime.tla
    NON_VACUOUS   rc=0
```

The state space is non-empty at 11 distinct, an `INVARIANT` is configured, `Spec`
admits a behaviour, every action `Next` mentions fired, and every field of
`Observe` takes more than one value. The same command at `-n 4`, which is
`Gate.tla`'s own threshold, also returns `NON_VACUOUS` at rc=0.

I passed no `--expect-actions`. The reference's four disjuncts are anonymous
disjuncts of `Next` rather than named actions, so there are no names to hand the
probe. That leaves the deletion shape of `tla-hf39` unlooked-for on this problem,
and the report says so rather than letting a run that didn't look read like a run
that looked.

**Check 6, the counts.** From check 1's run at `-workers 1`: **15 states
generated, 11 distinct states found**, depth 7, average outdegree 1 with a
maximum of 2. Wall time **0.54 s**. The 11 matches DESCRIPTION.md §4's estimate
of about 11 exactly, which nobody had run before now.

### The vector check

I'm this rung's first gate on the vector, read from the artifact.

| dimension | level | read from |
|---|---|---|
| representation | 2 | `Laytime.tla:75` lists the four `Observe` fields and nothing else. No `pc` |
| property kind | 2 | two `[][A]_Observe` properties. No `<>`, no `~>`, no `WF_`, no `SF_` |
| property count | 1 | four obligation lines, `Laytime.cfg:7-11`. Band 1 is two to four |
| step sources | 0 | one unnamed PlusCal process, the ship's agent. No clock disjunct |
| state space | 0 | 0.54 s, 11 distinct, 15 generated |

All five match the rung's `2 2 1 0 0 0`. `Spec == Init /\ [][Next]_vars`
(`Laytime.tla:139`) carries no fairness conjunct, which is what kind 2 needs and
what Rule 11 and ambiguity 12 both call for.

## 3. Results

Every variant ran under the same form as check 1, changing only the two paths.
All 26 cfgs are the reference cfg verbatim, so every variant met the shipped
obligations unchanged.

The obligation name is read out of the log. The verdict is the exit code alone.
Trace length is the count of `State N:` blocks TLC printed, and an invariant
broken at the opening prints the state with no such block.

### Family S

| id | token | rc | obligation reported | trace |
|---|---|---|---|---|
| S01 | `LIVENESS_VIOLATION` | 13 | `OpensOnceClosesOnce` | 2 states |
| S02 | `LIVENESS_VIOLATION` | 13 | `OpensOnceClosesOnce` | 3 states |
| S03 | `LIVENESS_VIOLATION` | 13 | `OpensOnceClosesOnce` | 4 states |
| S04 | `LIVENESS_VIOLATION` | 13 | `OpensOnceClosesOnce` | 4 states |
| S05 | `LIVENESS_VIOLATION` | 13 | `OnePeriodOneMove` | 3 states |
| S06 | `LIVENESS_VIOLATION` | 13 | `OnePeriodOneMove` | 4 states |
| S07 | `SAFETY_VIOLATION` | 12 | `DemurrageWaitsForAllowance` | 3 states |
| S08 | `LIVENESS_VIOLATION` | 13 | `OnePeriodOneMove` | 4 states |
| S09 | `LIVENESS_VIOLATION` | 13 | `OnePeriodOneMove` | 6 states |
| S10 | `OK` | 0 | none | uncaught |
| S11 | `SAFETY_VIOLATION` | 12 | `DemurrageWaitsForAllowance` | initial state |
| S12 | `OK` | 0 | none | uncaught |
| S13 | `SAFETY_VIOLATION` | 12 | `TypeOK` only, see finding 4 | 7 states |
| S14 | `OK` | 0 | none | uncaught |
| S15 | `OK` | 0 | none | uncaught |
| S16 | `OK` | 0 | none | uncaught |
| S17 | `OK` | 0 | none | uncaught |
| S18 | `LIVENESS_VIOLATION` | 13 | `OpensOnceClosesOnce` | 2 states |
| S19 | `SAFETY_VIOLATION` | 12 | `TypeOK` only, see finding 4 | 5 states |
| S20 | `OK` | 0 | none | uncaught |

13 of 20 caught by an obligation. No run hit rc=124, so nothing here is a
timeout wearing a pass. The seven that came back rc=0 are the seven the frozen
matrix named in advance, by id and not by count. I want that on the record as a
prediction that held rather than a result read backwards.

### The seven, against the vacuity probes

The obligations aren't the whole gate, so each uncaught variant went through
`harness/vacuity.sh` twice, once at the reference's own count and once at
`Gate.tla`'s threshold of 4.

| id | at `-n 11` | rc | at `-n 4` | rc | distinct |
|---|---|---|---|---|---|
| S10 | `VACUOUS_EMPTY_SPACE` | 3 | `VACUOUS_DEAD_ACTION` | 5 | 10 |
| S12 | `VACUOUS_EMPTY_SPACE` | 3 | `VACUOUS_FROZEN_OBSERVE` | 8 | 7 |
| S14 | `NON_VACUOUS` | 0 | `NON_VACUOUS` | 0 | 11 |
| S15 | `VACUOUS_EMPTY_SPACE` | 3 | `VACUOUS_FROZEN_OBSERVE` | 8 | 6 |
| S16 | `VACUOUS_EMPTY_SPACE` | 3 | `VACUOUS_EMPTY_SPACE` | 3 | 2 |
| S17 | `NON_VACUOUS` | 0 | `NON_VACUOUS` | 0 | 11 |
| S20 | `NON_VACUOUS` | 0 | `NON_VACUOUS` | 0 | 11 |

Four of the seven fall to a probe. Three survive everything the harness has, and
findings 1 and 2 name why.

### Family P

Each pair runs the mutated obligation against the reference system first, then
against the system variant the shipped form catches.

| id | token | rc | the variant alone |
|---|---|---|---|
| P01 | `OK` | 0 | reference, so rc=0 is right |
| P01S09 | `OK` | 0 | S09 alone is rc=13 |
| P02 | `OK` | 0 | reference, so rc=0 is right |
| P02S03 | `OK` | 0 | S03 alone is rc=13 |
| P03 | `OK` | 0 | reference, so rc=0 is right |
| P03S06 | `OK` | 0 | S06 alone is rc=13 |

All three escapes reproduce. Findings 5 and 6 say what each one costs.

## 4. Findings

The gate is green. Three variants stayed uncaught with nothing to catch them,
each with a named structural cause, and §9.5b's rule is that a structural
uncatchable is a finding rather than a failure. I don't think this wants a repair
pass, and finding 1 is why. No property over this interface closes any of the
three.

### 1. Rule 8's second half is invisible, and the state graph proves it

S14 is the description's own declaration made runnable. `Excepted` never accrues,
so a period the charter excuses runs free after the allowance is spent, which is
the rule of the trade broken outright.

S14 comes back rc=0 on all four obligations, `NON_VACUOUS` at both floors, and
**15 states generated, 11 distinct, depth 7, average outdegree 1 with a maximum
of 2**. Those are the reference's own numbers, every one of them. The coverage
block agrees field for field: the mutated disjunct reports `0:4` in S14 and `0:4`
in the reference.

So the two models have the same `Observe` state graph, and I don't think that's
close. `Working` already accrues from an identical guard once `laytimeLeft` hits
zero, so the transition S14 removes is one the graph reaches by another route.
Nothing linear-time can separate them, because there's nothing to separate.

The dead-action probe can't help either, and the `0:4` row is the reason. Total
is 4, not 0, so the branch fires and the predicate has nothing to match. §5.3
warns that `distinct == 0` would be the wrong predicate, and this is that warning
with a real spec behind it. Read `distinct == 0` and you'd fail the reference.

DESCRIPTION.md §3 says the kind of a period stays out of `Observe` "at the cost of
leaving that half of Rule 8 unenforced", and calls it graded by nothing at all.
That's exactly what the numbers say. My read is that this is a sound trade at
representation 2 rather than a hole to fix, because the only repair is a fifth
`Observe` field carrying the kind, and DESCRIPTION.md §5 rules a fifth variable
out as breaking the rung.

Two things follow downstream. The seeded-bug set for this problem must not use
Rule 8's second half, because a seeded bug nothing detects grades every
submission the same. And the statement shouldn't lean on Rule 8 as a thing the
learner will be marked on, since half of it isn't.

### 2. Step sources are invisible too, and so is a repeated notice

S20 adds a clock. A disjunct with `Working`'s guard and `Working`'s effect, taken
by nobody, which is ambiguity 3's rejected alternative written into the model.
It comes back rc=0 at 11 distinct with 19 generated, so the four extra generated
states all fold into states that already exist.

That's DESCRIPTION.md §3's Rule 2 row measured. `Observe` shows the statement and
not the hand writing it, so no field and no formula over those fields can say who
took a step. I don't think any addition to the operator changes this, since a
step's author isn't a fact about the page.

S17 re-tenders an already tendered notice, at 11 distinct with 25 generated.
Setting a flag that's already set changes no field, so the step stutters and
`[][A]_Observe` is satisfied by its own stuttering disjunct. Ambiguity 6 is
protected against withdrawal, which S02 catches at 3 states, and not against
repetition, which nothing catches. I'd call that the right split rather than a
gap, because a re-tender that changes nothing costs nothing.

### 3. The opening rides on `Init`, and the floor decides what happens next

S10 opens with the notice already tendered and S12 opens with the allowance spent.
Both pass all four obligations, which is what DESCRIPTION.md §5 predicts. A
fourth must-be-true pinning `Init` would be a fifth cfg line and would move
property count to band 2, so the opening is deliberately ungraded.

What catches them is the vacuity layer, and which probe fires depends on the
floor. At `-n 4` the diagnosis is right in both cases. S10 is `VACUOUS_DEAD_ACTION`
because `Tender`'s guard `~noticeTendered` is never true, so that disjunct sits
at zero total. S12 is `VACUOUS_FROZEN_OBSERVE` because `laytimeLeft` holds 0 in
every reachable state.

At `-n 11` both report `VACUOUS_EMPTY_SPACE` instead, because probe 1 runs first
and 10 and 7 are both under 11. The catch is still a catch, and the diagnosis is
worse.

That's a real problem for whoever sets this problem's floor, and it's sharper here
than `tla-dk7w` anticipated. The reference has 11 reachable states. A floor set at
11 leaves no room at all between the real model and a model one state short, so
any honest variation reads as a transcription. A floor set low enough to be safe
is a floor a transcription clears. I'd set it at 4 and lean on the frozen-observe
and dead-action probes, which are the ones that actually diagnose these two. That's
the statement author's call and not mine, so I'll flag it rather than pick.

### 4. Two variants are caught by `TypeOK` alone, which is the wrong reason

S13 drops the demurrage cap from both logging guards, and S19 draws the allowance
down with no `laytimeLeft > 0` test. Both come back rc=12 against `TypeOK` and
against nothing else.

`TypeOK` is the reference author's cfg line and not a learner requirement
(DESCRIPTION.md §2). So for a learner who writes the three stated must-be-trues
and no type invariant, both of these pass. S13 is Rule 9's cap and S19 is Rule
6's floor, and neither has an arrow of its own in the stated set.

I don't think this wants a repair either. DESCRIPTION.md §3 already routes both
rules through the type invariant's ranges in its sufficiency walk, and names
§5.2's under-approximation as the learner-side carrier: a model whose counters
leave the reference's ranges reaches `Observe` states the reference can't. Worth
knowing that the shipped set leans on that carrier for two rules, though.

### 5. The wrong-subscript hazard reproduces on both action properties

S09 takes accrued demurrage back and is caught at rc=13 by `OnePeriodOneMove`
over a 6-state trace. The same system with `OnePeriodOneMove` subscripted
`_(Observe.laytimeLeft)` comes back rc=0. A rebate step leaves `laytimeLeft`
alone, so the property is satisfied by its own stuttering disjunct and never
looks at the step it was written for.

S03 reopens a closed statement and is caught at rc=13 by `OpensOnceClosesOnce`
over a 4-state trace. The same system with that property subscripted
`_(Observe.noticeTendered)` comes back rc=0, for the same reason one field over.

DESCRIPTION.md §2 tells the author to subscript both rules over the whole of
`Observe`, and both halves of that instruction are load-bearing. This is shape A,
so the learner writes the subscript with no spec to copy from. I'd treat it as
the live failure mode for this problem.

### 6. The no-split clause is load-bearing, and P03 is the proof

ALTERNATIVES.md rejects the one-counter representation because must-be-true 2's
third clause can't fail inside it. That argument holds, and P03 measures it from
the other side.

S06 makes the period that spends the last of the allowance also accrue one, which
is Rule 7's no-split clause broken. It's caught at rc=13 by `OnePeriodOneMove`
over 4 states. Drop the third conjunct and the same system passes at rc=0, so
nothing else in the set notices.

The post-state is `laytimeLeft = 0` with `demurrage = 1`, which
`DemurrageWaitsForAllowance` allows and the first two conjuncts allow. The clause
is the only thing watching that step. My read is this is the sharpest single
argument in the shipped set for keeping all three conjuncts together in one
property.

### 7. What I couldn't build a variant for

Ambiguity 4, whole periods, has no mutation at this representation. Fractional
periods need the counters to leave `Nat`, which breaks `TypeOK` before it says
anything about the no-split clause. Ambiguities 9 and 11, the excepted list and
one cargo, are vocabulary and scope rather than model behaviour.

Ambiguity 5, no despatch, folds into S08. Giving allowance back for finishing
early is the same step as putting allowance back, and `OnePeriodOneMove` catches
it at 4 states.

## 5. For the statement author

One violating run per obligation, shortest first, all well under 8 states. The
satisfying half comes from the reference, which is green at rc=0.

| obligation | variant | what breaks | trace |
|---|---|---|---|
| `TypeOK` | S19 | the allowance runs past zero to -1 | 5 states |
| `DemurrageWaitsForAllowance` | S11 | opens with demurrage against a full allowance | initial state |
| `OpensOnceClosesOnce` | S01 | the allowance falls from 2 to 1, notice untendered on both sides | 2 states |
| `OnePeriodOneMove` | S05 | the allowance falls from 2 to 0 in one step | 3 states |

S01 and S05 land on DESCRIPTION.md §2's own predictions word for word, which is
worth knowing before anything downstream re-derives them.

S18 is the alternative pick for `OpensOnceClosesOnce`, also at 2 states, and it
closes the statement before the notice is tendered. S01 is the better teaching
trace, because a reckoning that starts early is the mistake a person would make.
S11 is the pick for `DemurrageWaitsForAllowance` over S07 at 3 states, because a
single state is the shortest counterexample there is.

There's no liveness obligation here, so no violating half is a lasso and none of
these traces ends in a stutter. Every one is a finite prefix.

One caution for the trace pairs. S13 and S19 are the only variants that break
`TypeOK`, and `TypeOK` is the reference author's line rather than a learner
requirement. If the statement ships a trace pair per learner-facing rule, that's
three pairs and not four.
