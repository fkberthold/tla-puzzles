# river-call step 2 — reference verification and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/river-call/reference/RiverCall.tla` and
`RiverCall.cfg`. I didn't write the reference. Bead `tla-h2cg.9`, rung 3 of batch 2.

The matrix in section 1 was authored and frozen before I ran TLC once. Section 2
records the reference's own gate and the load-vector check. Section 3 records what
each variant did. Section 4 carries the findings, including the variants nothing
caught and why. Section 5 is the trace shortlist for the statement author.

Downstream this problem is shape D at representation 2. The learner models the
system from prose and then diagnoses a handed green run, so the shipped artifact is
a diagnosis object rather than a trace pair. `D01` in the matrix is that object, and
section 3.3 is what step 4 ships.

## 1. The frozen matrix

Two families. Family S mutates the system (the `Init`, the actions, `Next` and
`Spec`) and leaves all four obligations in the `.cfg` untouched. Family P mutates an
obligation instead and asks whether the weakened form still catches a system variant
the shipped form catches.

Every mutation below is stated against the reference text, so the matrix reads as a
diff without needing the files. The modules are committed beside this report under
`step2-variants/`, and each one carries its own `.cfg`.

### Family S — system mutations

| id | name | targets | mutation |
|---|---|---|---|
| S01 | open-ignores-flow | item 1 | `Open`: drop the `Taken(...) =< Flow` conjunct |
| S02 | open-off-by-one | item 1, §6.11 | `Open`: `Taken(...) =< Flow + 1` |
| S03 | init-over-flow | `Init`, item 1 | `Init`: `diverted = [o \in Owners |-> Decree[o]]` |
| S04 | open-above-decree | `TypeOK`, §6.7 | `Open`: `\E n \in (diverted[o] + 1) .. Flow` |
| S05 | open-ignores-calls | item 2 | `Open`: drop the seniority guard |
| S06 | open-checks-juniors | item 2, rule 2 | `Open`: `Senior(o, s) => ~ calling[s]` |
| S07 | open-checks-one-senior | item 2, §6.8 | `Open`: guard restricted to `s = o - 1` |
| S08 | close-raises | item 2, §6.4 | `Close`: `\E n \in 0 .. Decree[o]`, flow-checked |
| S09 | joint-open | item 1, §6.10 | extra `Next` disjunct opening two owners in one step |
| S10 | call-ungated | item 3, §6.5 | `CallOut`: drop the `Short(diverted, o)` conjunct |
| S11 | short-own-draw | item 3, §6.3 | `CallOut`: guard `diverted[o] < Decree[o]` |
| S12 | short-seniors-only | item 3, §6.3 | `CallOut`: guard counts seniors' draw alone |
| S13 | call-back-gated | §6.6 | `CallBack`: add `~ Short(diverted, o)` |
| S14 | curtail | rule 8, §6.2 | extra `Next` disjunct shutting a junior under a call |
| S15 | flow-drifts | rule 1, §6.1 | a `flow` variable, a `Weather` step, `Open` reads it |
| S16 | physical-cap | §6.14 | `Open`: the stream clips a setting it can't deliver |
| S17 | spec-fairness | §6.12 | `Spec`: add `\A o \in Owners : WF_vars(Open(o))` |
| S18 | init-calling-true | `Init`, rule 10 | `Init`: `calling = [o \in Owners |-> TRUE]` |
| S19 | no-open | vacuity | `Next`: drop the `Open` disjunct |
| D01 | flow-6 | §7, the diagnosis object | cfg: `Flow = 6`, the module unchanged |

Eight of those I expect back green, and I want the expectation on the record before
the runs rather than after.

S12, S13, S16 and S17 each make the reference stricter rather than looser. Items 2
and 3 are implications and item 1 is an upper bound, so a mutation that only removes
behavior or lowers a setting has nothing to falsify. Rule 9 says nothing has to
happen, so there's no liveness obligation to notice the missing behavior either.

S14 and S15 should be uncatchable at the interface. `Observe` shows the stretch and
not the hands on it, which is what §3 of the description says about rule 8, and a
`Weather` step leaves both fields alone, so it stutters out of both action
properties.

S18 should be green because no obligation constrains the opening. Section 2 of the
description turned down a fourth must-be-true pinning it, on the grounds that the
shipped spec's own `Init` fixes it. A variant that moves the `Init` walks straight
through that gap.

S19 should pass all four obligations and fail only `Gate!NonVacuous`.

D01 should pass all four and be caught by `harness/vacuity.sh`, which is the whole
point of the seed. `ALTERNATIVES.md` records 27 distinct states and
`VACUOUS_DEAD_ACTION` naming `CallOut`, measured by the reference author. I'm
re-measuring rather than citing it.

### Family P — property mutations

| id | name | mutation | run against |
|---|---|---|---|
| P01 | opens-subscript-diverted | item 2 subscripted `_(Observe.diverted)` | reference, then S05 |
| P02 | honest-subscript-diverted | item 3 subscripted `_(Observe.diverted)` | reference, then S10 |
| P03 | honest-subscript-calling | item 3 subscripted `_(Observe.calling)` | reference, then S10 |
| P04 | opens-one-senior | item 2 restricted to `s = o - 1` | reference, then S07 |

P02 is the wrong-subscript probe the brief asks for. A `CallOut` step leaves
`diverted` alone, so `[][...]_(Observe.diverted)` is satisfied by its own stuttering
disjunct and item 3 stops seeing the one action it exists to catch. I expect S10 to
walk through it at rc=0.

P01 and P03 are the controls, and I think both stay caught. Item 2's antecedent
already requires `diverted` to move, so narrowing the subscript to that field takes
nothing away. Item 3 under `_(Observe.calling)` keeps the field the action does
move. The description warns about the subscript in general terms, and P01 and P03
measure how far the warning actually reaches.

P04 asks what happens when the learner writes the same partial order into the
property that S07 writes into the system. I expect the pair to agree at rc=0, which
would say the obligation can't defend an order it doesn't state.

### What counts as caught

An invariant catches a variant at rc=12 and an action property at rc=13, per §9.5
step 5 and bead `tla-94n`. rc=124 is `TIMEOUT` and is never read as uncaught.
Anything else gets recorded as itself. The verdict is the exit code and only the
exit code. The obligation's name comes from the log, which is where a name is
allowed to come from.

A variant caught by `TypeOK` alone is caught for the wrong reason unless `TypeOK` is
what it targets. S04 targets `TypeOK`, so a `TypeOK` catch there is the result. Any
other variant reported against `TypeOK` gets flagged.

## 2. The reference's own gate

Every run below goes through `harness/verdict.sh`, so the verdict is the raw exit
code and nothing reads TLC's stdout. `Gate.tla` is found through
`JAVA_TOOL_OPTIONS="-DTLA-Library=$WT/harness"`, with `$WT` the worktree root.

```
verdict.sh -t 300 --config $REF/RiverCall.cfg $REF/RiverCall.tla
    OK                     rc=0     0.8s
verdict.sh -t 300 --config $REF/RiverCall.cfg $REF/RiverCall.tla -- -inv FALSE
    SAFETY_VIOLATION       rc=12    0.5s
verdict.sh -t 300 --config $ABS/RiverCall.cfg -p Gate!NonVacuous $ABS/RiverCall.tla
    OK                     rc=0     0.7s
```

The third command needs the module and the config as absolute paths. With the
module given relatively, TLC searches the cwd for `Gate` and not `TLA-Library`, and
the run comes back `PARSE_ERROR` at rc=150. `harness/vacuity.sh:236-253` records the
same trap from the other side, and it cost me one run to rediscover it. Worth a line
in `verdict.sh`'s own header, I think, since the option that needs the absolute form
is the one `verdict.sh` offers.

Counts, from the plain run: 757 states generated, 136 distinct, depth 8. Wall time
over three consecutive runs was 0.8s, 0.9s and 0.8s, nearly all of it JVM startup.
TLC's own line reads `Finished in 00s`.

Action coverage, from the same run. The check is `total == 0`, not `distinct == 0`.

| action | distinct : total |
|---|---|
| `Init` | 1 : 1 |
| `Open` | 25 : 168 |
| `Close` | 42 : 288 |
| `CallOut` | 68 : 96 |
| `CallBack` | 0 : 204 |

No action sits at zero total. `CallBack` at `0 : 204` is the row the §5.1 warning is
about. It fired 204 times and discovered nothing new, which is right, because taking
a call back always lands on a state some other route already reached.

`harness/vacuity.sh` over the reference, at a candidate floor of 100:

```
vacuity.sh -t 300 -c $ABS/RiverCall.cfg -n 100 \
    --expect-actions Open,Close,CallOut,CallBack --observe Observe $ABS/RiverCall.tla
    NON_VACUOUS            rc=0
```

All five probes pass. The state space clears 100, an `INVARIANT` is configured,
`Spec` admits a behavior, every expected action reached the coverage block, and both
fields of `Observe` take more than one value.

### The load vector, read from the artifact

I'm this rung's first gate on the vector, so here's each dimension against
`RiverCall.cfg` and `RiverCall.tla`.

| dimension | claimed | measured | verdict |
|---|---|---|---|
| representation | 2 | variables are `diverted, calling`, no `pc` | holds |
| property kind | 2 | two `[][...]_Observe`, no `<>`, no `~>`, no `WF` | holds |
| property count | 1 | 4 obligation lines in the cfg | holds |
| step sources | 1 | one process set over `Owners`, no clock | holds |
| state space | 0 | 136 distinct, 0.8s wall | holds |

Property count: `RiverCall.cfg:6-11` carries `TypeOK` and `FlowHolds` under
`INVARIANTS`, then `NobodyOpensAgainstACall` and `ACallIsHonest` under `PROPERTIES`.
Four lines, which is band 1.

Property kind: both step rules are subscripted `_Observe`, at `RiverCall.tla:75` and
`RiverCall.tla:80`. `Spec == Init /\ [][Next]_vars` at `RiverCall.tla:62` carries no
fairness conjunct, and the module holds no `<>` and no `~>`.

Representation: `VARIABLES diverted, calling` at `RiverCall.tla:12` against
`Observe == [diverted |-> diverted, calling |-> calling]` at `RiverCall.tla:16`. The
two match field for field, and nothing in the module mentions `pc`.

The statement author can cite 136 distinct states, 757 generated and a sub-second run
in `VECTOR.md` without re-running anything.

## 3. Results

Each variant ran with the same command, changing only the two paths:

```
verdict.sh -t 300 --config $VAR/<id>.cfg $VAR/<id>.tla
```

Every variant cfg is the reference cfg byte for byte, except `D01`, which changes
`Flow = 3` to `Flow = 6` and nothing else. So each family S variant met the shipped
obligations unchanged. Any variant returning rc=0 was then run a second time with
`-p Gate!NonVacuous`.

### 3.1 Family S

| id | token | rc | obligation reported | trace | distinct |
|---|---|---|---|---|---|
| S01 | `SAFETY_VIOLATION` | 12 | `FlowHolds` | 3 states | 13 |
| S02 | `SAFETY_VIOLATION` | 12 | `FlowHolds` | 3 states | 13 |
| S03 | `SAFETY_VIOLATION` | 12 | `FlowHolds` | initial state | n/a |
| S04 | `SAFETY_VIOLATION` | 12 | `TypeOK` | 2 states | 4 |
| S05 | `LIVENESS_VIOLATION` | 13 | `NobodyOpensAgainstACall` | 4 states | 33 |
| S06 | `LIVENESS_VIOLATION` | 13 | `NobodyOpensAgainstACall` | 4 states | 33 |
| S07 | `LIVENESS_VIOLATION` | 13 | `NobodyOpensAgainstACall` | 4 states | 43 |
| S08 | `LIVENESS_VIOLATION` | 13 | `NobodyOpensAgainstACall` | 4 states | 35 |
| S09 | `SAFETY_VIOLATION` | 12 | `FlowHolds` | 2 states | 11 |
| S10 | `LIVENESS_VIOLATION` | 13 | `ACallIsHonest` | 2 states | 8 |
| S11 | `LIVENESS_VIOLATION` | 13 | `ACallIsHonest` | 2 states | 8 |
| S12 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | uncaught | 62 |
| S13 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | uncaught | 136 |
| S14 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | uncaught | 136 |
| S15 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | uncaught | 544 |
| S16 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | uncaught | 136 |
| S17 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | uncaught | 136 |
| S18 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | uncaught | 136 |
| S19 | `OK` | 0 | `Gate!NonVacuous` at rc=10 | 1 state | 1 |
| D01 | `OK` | 0 | none, `Gate!NonVacuous` also rc=0 | see 3.3 | 27 |

11 of 19 caught by an obligation, and S19 by the vacuity gate. No run hit rc=124, so
nothing here is a timeout wearing a pass. TLC names an action property in the log as
`Action property <name> is violated`, so every rc=13 row above carries a name rather
than a source location.

The eight rc=0 rows are the eight the frozen matrix named in advance, and D01 is the
ninth prediction. I want that on the record as a prediction that held rather than a
result read backwards.

`S04` is the only variant reported against `TypeOK`, and `TypeOK` is what it targets.
Nothing here was caught for the wrong reason.

### 3.2 Family P

| id | token | rc | obligation reported |
|---|---|---|---|
| P01 | `OK` | 0 | none, against the reference |
| P02 | `OK` | 0 | none, against the reference |
| P03 | `OK` | 0 | none, against the reference |
| P04 | `OK` | 0 | none, against the reference |
| P01S05 | `LIVENESS_VIOLATION` | 13 | `NobodyOpensAgainstACall`, 4 states |
| P02S10 | `OK` | 0 | none, and S10 alone is rc=13 |
| P03S10 | `LIVENESS_VIOLATION` | 13 | `ACallIsHonest`, 2 states |
| P04S07 | `OK` | 0 | none, and S07 alone is rc=13 |

### 3.3 D01, the diagnosis object

This is what step 4 ships, so it gets its own measurements rather than a table row.

The run TLC gives back:

```
verdict.sh -t 300 --config $VAR/D01.cfg $VAR/D01.tla
    OK                     rc=0
163 states generated, 27 distinct states found, 0 states left on queue.
```

27 distinct against the reference's 136, on an instance that differs by one constant.
27 is also every combination of three settings drawn from 0, 1 and 2, so `FlowHolds`
excluded nothing at all on this run.

Coverage, from the same run:

| action | distinct : total |
|---|---|
| `Init` | 1 : 1 |
| `Open` | 26 : 81 |
| `Close` | 0 : 81 |
| `CallOut` | 0 : 0 |
| `CallBack` | 0 : 0 |

Two rows at `0 : 0`, which is the `total == 0` predicate matching twice.

Where each obligation stands on the run. The split matters, because a probe reports
the two halves differently and the statement author needs to know which signal points
where.

| obligation | passes on | evidence |
|---|---|---|
| `TypeOK` | its own terms | the only obligation doing work |
| `FlowHolds` | never binds | 27 of 27 type-legal states are flow-legal |
| `NobodyOpensAgainstACall` | its consequent | `Open` fired 81 times, `calling` never moved |
| `ACallIsHonest` | its antecedent | `CallOut` at `0 : 0`, so no call ever goes out |

`harness/vacuity.sh` catches it three separate ways, and which one you get depends on
the flags:

```
vacuity.sh -n 100 --expect-actions Open,Close,CallOut,CallBack --observe Observe
    VACUOUS_EMPTY_SPACE    rc=3    27 distinct against a floor of 100
vacuity.sh -n 27
    VACUOUS_DEAD_ACTION    rc=5    names CallOut and CallBack
vacuity.sh -n 4 --no-dead-actions --observe Observe
    VACUOUS_FROZEN_OBSERVE rc=8    calling is <<FALSE, FALSE, FALSE>> in all 27
```

The dead-action report names both `CallOut` and `CallBack`, with the last expression
each one still reached. `ALTERNATIVES.md` predicted both names and it's right.

## 4. Findings

The gate is green. Eight variants stayed uncaught, each one predicted in advance with
a named structural cause, and none of the eight is a hole a §9.5b repair could close.
Finding 1 is the argument for that.

### 1. Every uncaught variant is a strengthening or an interface blind spot

The eight split two ways, and neither way is answerable by adding a property.

S12, S13, S16 and S17 make the reference stricter. S12 counts only seniors' draw when
it decides shortness, which turns out to imply the shipped `Short` rather than
contradict it. S13 refuses to let an owner take a call back while still short. S16
lets the stream clip a setting it can't deliver. S17 adds weak fairness on `Open`. All
four remove behaviors, and no obligation here can be violated by a behavior that
doesn't happen. S17 doesn't even move the state graph: 757 generated and 136 distinct,
which is the reference's own pair to the state.

S14 and S15 are invisible at the interface. S14 adds a watermaster who shuts a
junior's gate under a call, and every step it adds lowers a setting, which item 2's
antecedent doesn't reach and item 1 can't mind. S15 gives the stream a `flow` variable
and a `Weather` step. That step leaves both `Observe` fields alone, so it stutters out
of both action properties, and `FlowHolds` reads the constant. §3 of the description
already says `Observe` shows the stretch and not the hands on it. Both results are
that sentence measured.

S18 walks through a gap the description named and accepted. It opens with every call
standing, and nothing in the cfg constrains the opening. Section 2 turned down a
fourth must-be-true pinning it, because the shipped `Init` fixes it. That reasoning
holds only while the `Init` is the shipped one, which is exactly what a learner's
model doesn't have to be. Under shape D the learner writes their own `Init`, so I'd
call this the one uncaught variant worth a second look before the problem ships.

A repairer could close S18 with a fifth cfg line, something like an implied init
`Opening == Observe.calling = [o \in Owners |-> FALSE]`. I'm not recommending it.
Five lines pushes property count from band 1 to band 2 and breaks the rung, which §5
of the description already worked out. My read is that S18 is a real gap in the graded
set, and the right answer is to leave it open at this rung and say so downstream.

### 2. The reference reaches every legal state, and §4's estimate is one word wrong

Section 4 of the description computes at most 136 states passing the type invariant
and the flow rule, then says "fewer are reachable, since a call needs a short owner
behind it". Measured, all 136 are reachable.

The reason the caveat doesn't bite: a call needs a short owner at the moment it goes
out, and nothing keeps it standing once the water moves. So an owner calls while
short, then the gates move underneath the call, and every combination of settings
pairs with every combination of calls. S18 is the same fact from another angle. It
starts at a state the reference already reaches, and comes back at 757 and 136,
identical to the reference.

The arithmetic itself is right, and 136 is worth citing in `VECTOR.md`. Only the
"fewer" is wrong.

### 3. The wrong-subscript hazard reproduces, on exactly one of the two step rules

P02S10 is the sharpest result here. S10 drops the `Short` guard from `CallOut` and is
caught at rc=13 by `ACallIsHonest` in 2 states. The same system mutation, with
`ACallIsHonest` subscripted `_(Observe.diverted)` instead of `_Observe`, comes back
rc=0 over the full 136 states. A `CallOut` step leaves `diverted` alone, so the
property is satisfied by its own stuttering disjunct and never sees the action it was
written for.

The control runs say the hazard is narrower than the general warning reads. P01S05
narrows item 2's subscript the same way and S05 is still caught, at rc=13 in 4 states,
because item 2's antecedent already requires `diverted` to move. P03S10 subscripts
item 3 on `Observe.calling`, the field the action does move, and S10 is caught again
at rc=13 in 2 states.

So the rule is about which field the action touches, not about record altitude in
general. `ALTERNATIVES.md` says both step rules take the whole record, and that's the
right instruction. The measurement says only one of the two would actually break
without it. I'd keep the whole record on both anyway, since a learner who reasons
per-property here gets it right by luck.

### 4. The property can't defend an order it doesn't state

P04S07 pairs the partial-order system mutation with the same partial order written
into item 2, and the pair comes back rc=0 over all 136 states. S07 alone is caught at
rc=13 in 4 states.

That isn't a defect in the reference, and I don't think it's fixable. It's what shape
D costs: the learner writes the model, and at the rungs above this one the properties
too. A learner who misreads seniority the same way twice passes. What catches it is
the register being a constant the statement fixes, not anything in the obligation set.

### 5. `vacuity.sh`'s verdict on D01 depends on `--min-states`, and that's load-bearing

`ALTERNATIVES.md` records `VACUOUS_DEAD_ACTION` at rc=5 on the flow-6 seed. That's
what I measured at `-n 27` and at `-n 4`. At `-n 100` the same seed comes back
`VACUOUS_EMPTY_SPACE` at rc=3 instead, because the state-space probe runs first and
27 is under the floor.

Both verdicts are correct and they name different things. The floor says the run is
too small, and the dead-action probe says which action died. §5.3 makes the floor
mandatory and per-problem, and nobody has set one for this problem yet. Whoever sets
it should know that a floor anywhere above 27 masks the dead-action report on the very
seed this problem ships.

I'd set the floor at 100. It's under the reference's 136 with room for a learner's
model to differ, and it's over D01's 27 by enough that a transcribed trace can't clear
it. The cost is the masking above, and the answer to that is that step 4 keeps the
harness away from the learner anyway.

Worth noting that S12 also lands under a floor of 100, at 62 distinct. It passes every
obligation and passes `Gate!NonVacuous` at the placeholder threshold of 4. So the
per-problem floor is the only instrument in the harness that would flag it, which is
another argument for setting one.

### 6. The frozen-field probe reads `calling` cleanly here

Bead `tla-ooxx` is open against `vacuity.sh`'s frozen-`Observe` probe, which reads
only single-line `PrintT` values. `Observe.calling` renders as
`<<FALSE, FALSE, FALSE>>` on this instance, which fits one line, so the probe reports
correctly and D01 comes back `VACUOUS_FROZEN_OBSERVE` at rc=8. That's a fact about
three owners rather than about the bug being gone. A larger `Owners` would test it.

### 7. `Gate!NonVacuous` needs the absolute-path form of `verdict.sh`

Recorded in section 2 and repeated here because it cost a run.
`verdict.sh -p Gate!NonVacuous` with a relative module path exits 150 `PARSE_ERROR`,
and the same command with both paths absolute exits 0. `verdict.sh`'s header explains
why it leaves the module path alone, and `vacuity.sh:236-253` carries the measurement.
Neither says it where a caller reaching for `-p` will read it.

## 5. For the statement author

Shape D ships a diagnosis object rather than trace pairs, so this section is a
shortlist rather than a delivery. Section 3.3 is what step 4 actually needs.

The shortest caught variant per obligation, should a later step want one:

| obligation | variant | trace |
|---|---|---|
| `TypeOK` | S04, a gate opening past its own decree | 2 states |
| `FlowHolds` | S03, an opening already over the flow | initial state |
| `FlowHolds` | S09, two owners opening in one step | 2 states |
| `NobodyOpensAgainstACall` | S05, `Open` with no seniority guard | 4 states |
| `ACallIsHonest` | S10, `CallOut` with no shortness guard | 2 states |

There's no liveness obligation in this cfg, so no violating half here is a lasso.
Every trace above ends on a finite prefix.

S09 is the better pick for `FlowHolds` over S03, since S03 violates in the initial
state and a reader has nothing to walk. S05 is the pick for item 2 over S06, S07 and
S08, which all take 4 states and reach it by a stranger route. S10 is the pick for
item 3 over S11, which is the same length but asks the reader to hold two readings of
shortness at once.
