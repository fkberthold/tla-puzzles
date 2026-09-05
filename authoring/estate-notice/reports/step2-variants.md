# estate-notice step 2, the reference gate and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/estate-notice/reference/EstateNotice.tla`
and `EstateNotice.cfg` at commit `76ed6a9`. I didn't write the reference. Bead
`tla-h2cg.13`, rung 7 of batch 2, vector `2 3 2 2 0 1`.

The matrix in section 1 was authored, written to disk and frozen before I ran
TLC once. Section 2 is the vector check, which this rung asks for first. Section
3 is the reference's own gate. Section 4 records what each variant did. Section
5 carries the findings, including the seven nothing caught. Section 6 is the
trace table the statement author wants.

Downstream this problem is shape A, so the learner writes the whole model from
prose. That makes family S the load-bearing half: a broken store is what a
learner hands in, and the property set is what has to notice.

## 1. The frozen matrix

Two families, as qsl has them. Family S mutates the system half of the module,
meaning `Init`, `Next`, the actions and the fairness, and leaves all eight
obligations in the `.cfg` alone. Family P mutates a property and asks whether
the weakened form still catches a system variant the shipped form catches.

Every variant is the reference text with one literal replacement applied. The
generator refuses to write a variant whose anchor isn't found exactly once, so a
mutation that silently does nothing can't reach the matrix. All 36 came back
with zero anchor failures.

Each variant ships as its own module under `step2-variants/<id>.tla` with a copy
of the reference cfg beside it. Every cfg is byte-identical to the reference's,
so every variant met the shipped obligations unchanged.

### Family S, system mutations

| id | name | targets | mutation |
|---|---|---|---|
| S01 | distribute-with-lodged | item 1 | `Distribute`: drop the `\A c : ~Unsettled(c)` conjunct |
| S02 | distribute-while-open | item 1 | `Distribute`: drop the `notice = "closed"` guard |
| S03 | lodge-after-close | item 2 | `Lodge`: drop the `notice = "open"` guard |
| S04 | admit-without-lodging | item 2 | extra disjunct taking a creditor from none to admitted |
| S05 | withdraw-claim | item 3 | extra disjunct taking a lodged claim back to none |
| S06 | admitted-turns-rejected | item 4 | `Decide` guards on `{"lodged", "admitted"}` |
| S07 | reopen-notice | item 5 | extra disjunct taking a closed notice back to open |
| S08 | clawback | item 6 | extra disjunct setting `distributed'` false |
| S09 | next-drops-distribute | item 7 | `Next`: drop the `Distribute` disjunct, keep its `WF` |
| S10 | no-close-fairness | item 7 | `Spec`: drop `WF_vars(Close)` |
| S11 | no-decide-fairness | item 7 | `Spec`: drop the `DecideStep` conjunct |
| S12 | no-pay-fairness | item 7 | `Spec`: drop the `Pay` conjunct |
| S13 | no-distribute-fairness | item 7 | `Spec`: drop `WF_vars(Distribute)` |
| S14 | standing-out-of-band | `TypeOK` | extra disjunct writing a seventh standing |
| S15 | relodge-after-reject | ambiguity 4 | `Lodge` guards on `{"none", "rejected"}` |
| S16 | sweep-at-close | ambiguity 5 | `Close` puts every unlodged creditor out of time |
| S17 | admit-and-pay-in-one | ambiguity 7 | extra disjunct taking lodged straight to paid |
| S18 | decide-only-after-close | ambiguity 8 | `Decide` gains a `notice = "closed"` guard |
| S19 | decide-two-at-once | ambiguity 9 | extra disjunct deciding two creditors in one step |
| S20 | distribute-twice | ambiguity 10 | `Distribute`: drop the `distributed = FALSE` guard |
| S21 | creditor-fairness | ambiguity 12 | `Spec` gains `\A c : WF_vars(Lodge(c))` |
| S22 | comeforward-barred-after-distribution | Rule 8 | `ComeForward` gains a `distributed = FALSE` guard |
| S23 | pay-unadmitted | Rule 6 | `Pay` guards on `{"lodged", "admitted"}` |
| S24 | comeforward-while-open | Rule 4 | `ComeForward` guards on `notice = "open"` |
| S25 | init-all-lodged | `Init`, Rule 1 | `Init`: every creditor starts lodged |
| S26 | init-notice-closed | `Init`, Rule 2 | `Init`: the notice starts closed |
| S27 | init-distributed | `Init`, Rule 7 | `Init`: the residue has already gone |
| S28 | a-creditor-closes-the-notice | who acts | `Close` takes a creditor parameter |

### Family P, property mutations

| id | mutation | run against |
|---|---|---|
| P01 | item 2 subscripted `_(Observe.notice)` | reference |
| P01S03 | the same, over S03 | S03 |
| P02 | item 5 subscripted `_(Observe.standing)` | reference |
| P02S07 | the same, over S07 | S07 |
| P03 | `Spec`: all four fairness conjuncts dropped | reference |
| P04 | `Spec`: `WF_vars(Next)` in place of the four | reference |
| P05 | item 4 subscripted `_(Observe.distributed)` | reference |
| P05S06 | the same, over S06 | S06 |

Shape D's seeded-defect variant has no counterpart here. `DESCRIPTION.md` runs
to six sections and this rung is shape A, so there's no section 7 naming one.

### What I expected to come back green, said in advance

Nine of the 36, and I want the prediction on the record before the runs rather
than after.

S18, S21 and S22 are restrictions. Each removes behaviours and adds none, and a
safety or liveness obligation constrains the behaviours that exist. S20 is a
stutter, since a second distribution leaves every variable where it was. S28 is
the interface blindness `DESCRIPTION.md` §3 names in as many words, so its
counts should match the reference's. S09 should go vacuous rather than caught,
because `WF_vars(Distribute)` then demands a step `Next` forbids.

S19 is the one the rung asks about by name, and §3 of the description says
nothing grades it. P04 is the blanket-fairness claim §5 makes, and if the
description is right it comes back green.

I also expected S25 and S26 to come back green, on the reasoning that no
obligation constrains the opening. I was wrong about both, and finding 2 is why.

## 2. The vector check

I'm this rung's first gate on the vector, read from the artifact. All six hold.

| dimension | claimed | read from the artifact |
|---|---|---|
| representation | 2 | variables are `standing`, `notice`, `distributed`, exactly the `Observe` fields, and no `pc` |
| property kind | 3 | `<>Observe.distributed` present, and `Spec` carries four `WF` conjuncts on named steps |
| property count | 2 | 2 `INVARIANTS` lines plus 6 `PROPERTIES` lines is 8, inside the five-to-nine band |
| step sources | 2 | executor and creditors, two kinds, no clock action and no unprompted step |
| state space | 0 | 77 distinct, 138 generated, 0.53 s wall |
| form left open | 1 | not mine to read from the reference, since it's set by the statement |

On property kind, the fairness is four named conjuncts and not `WF_vars(Next)`,
and none of the four is a disjunction of one party's actions. On step sources,
the reference is plain TLA+ with no processes, so the party kinds show up as
which actions each party owns. The executor has `Close`, `Decide`, `Pay` and
`Distribute`. The creditors have `Lodge` and `ComeForward`.

The state-space numbers are what the statement author cites in `VECTOR.md`. 77
distinct is the number `DESCRIPTION.md` §4 works out by hand, to the state.

## 3. The reference's own gate

Every run goes through `harness/verdict.sh`, so the verdict is the raw exit code
and nothing reads TLC's stdout. Module and config paths are absolute, and
`Gate.tla` is found through `JAVA_TOOL_OPTIONS="-DTLA-Library=$WT/harness"`.

```
harness/verdict.sh -t 120 --config $REF/EstateNotice.cfg $REF/EstateNotice.tla
    OK                   rc=0    0.53 s
harness/verdict.sh ... $REF/EstateNotice.tla -- -inv FALSE
    SAFETY_VIOLATION     rc=12   0.48 s
harness/verdict.sh ... -p Gate!NonVacuous $REF/EstateNotice.tla
    OK                   rc=0    0.62 s
harness/vacuity.sh -c $REF/EstateNotice.cfg -n 4 -t 120 \
    --expect-actions Lodge,ComeForward,Close,Decide,Pay,Distribute \
    --observe Observe $REF/EstateNotice.tla
    NON_VACUOUS          rc=0
```

The `-inv FALSE` run reports `Invariant __DebuggerExpr__1788592406469 is
violated by the initial state`, which is §5.3's auto-generated name and never
something to match on.

All five vacuity probes pass. The state space is non-empty, an `INVARIANT` is
configured, `Spec` admits at least one behaviour, every expected action reached
the coverage block, and every field of `Observe` takes more than one value.

Counts, from the plain run: 138 states generated, 77 distinct, complete graph
depth 9, average outdegree 1 with a maximum of 5. TLC reports `Finished in 00s`.
The 0.53 s above is the whole `verdict.sh` invocation including JVM startup, so
it's the pessimistic reading and it still clears space 0 by a wide margin.

Action coverage, from the same run's final table. The check is `total == 0`, not
`distinct == 0`.

| action | distinct : total |
|---|---|
| `Init` | 1 : 1 |
| `Lodge` | 3 : 10 |
| `ComeForward` | 8 : 20 |
| `Close` | 4 : 25 |
| `Decide` | 28 : 44 |
| `Pay` | 20 : 22 |
| `Distribute` | 13 : 16 |

No action sits at zero. Every disjunct of `Next` fires.

## 4. Results

Each variant ran under the same command with only the two paths changing:

```
harness/verdict.sh -t 120 --config $VAR/<id>.cfg $VAR/<id>.tla
```

The obligation column is read out of the log, which is where a name is allowed
to come from. The verdict is the exit code alone. An invariant catches at rc=12
and an action or temporal property at rc=13, per §9.5 step 5 and bead `tla-94n`.
No run hit rc=124, so nothing here is a timeout wearing a pass.

### Family S

| id | token | rc | obligation reported | trace |
|---|---|---|---|---|
| S01 | `SAFETY_VIOLATION` | 12 | `SheDistributesOnlyWhenClear` | 4 states |
| S02 | `SAFETY_VIOLATION` | 12 | `SheDistributesOnlyWhenClear` | 2 states |
| S03 | `LIVENESS_VIOLATION` | 13 | `ClaimsStartWithTheCreditor` | 3 states |
| S04 | `LIVENESS_VIOLATION` | 13 | `ClaimsStartWithTheCreditor` | 2 states |
| S05 | `LIVENESS_VIOLATION` | 13 | `ALodgedClaimEndsInHerDecision` | 3 states |
| S06 | `LIVENESS_VIOLATION` | 13 | `ADecisionStands` | 4 states |
| S07 | `LIVENESS_VIOLATION` | 13 | `TheNoticeNeverReopens` | 3 states |
| S08 | `LIVENESS_VIOLATION` | 13 | `TheDistributionIsNeverUndone` | 4 states |
| S09 | `OK` | 0 | none, and `vacuity.sh` at rc=7 | uncaught by the cfg |
| S10 | `LIVENESS_VIOLATION` | 13 | `TheEstateIsEventuallyDistributed` | 7 states, then stuttering |
| S11 | `LIVENESS_VIOLATION` | 13 | `TheEstateIsEventuallyDistributed` | 5 states, then stuttering |
| S12 | `LIVENESS_VIOLATION` | 13 | `TheEstateIsEventuallyDistributed` | 7 states, then stuttering |
| S13 | `LIVENESS_VIOLATION` | 13 | `TheEstateIsEventuallyDistributed` | 9 states, then stuttering |
| S14 | `SAFETY_VIOLATION` | 12 | `TypeOK` | 2 states |
| S15 | `LIVENESS_VIOLATION` | 13 | `ADecisionStands` | 4 states |
| S16 | `LIVENESS_VIOLATION` | 13 | `ClaimsStartWithTheCreditor` | 2 states |
| S17 | `LIVENESS_VIOLATION` | 13 | `ALodgedClaimEndsInHerDecision` | 3 states |
| S18 | `OK` | 0 | none, and `vacuity.sh` at rc=0 | uncaught |
| S19 | `OK` | 0 | none, and `vacuity.sh` at rc=0 | uncaught |
| S20 | `OK` | 0 | none, and `vacuity.sh` at rc=0 | uncaught |
| S21 | `OK` | 0 | none, and `vacuity.sh` at rc=0 | uncaught |
| S22 | `OK` | 0 | none, and `vacuity.sh` at rc=0 | uncaught |
| S23 | `LIVENESS_VIOLATION` | 13 | `ALodgedClaimEndsInHerDecision` | 3 states |
| S24 | `LIVENESS_VIOLATION` | 13 | `ClaimsStartWithTheCreditor` | 2 states |
| S25 | `OK` | 0 | none, and `vacuity.sh` at rc=5 | uncaught by the cfg |
| S26 | `OK` | 0 | none, and `vacuity.sh` at rc=5 | uncaught by the cfg |
| S27 | `SAFETY_VIOLATION` | 12 | `SheDistributesOnlyWhenClear` | initial state |
| S28 | `OK` | 0 | none, and `vacuity.sh` at rc=0 | uncaught |

21 of 28 caught by an obligation, and 3 more by `vacuity.sh`. Only S14 was
caught by `TypeOK`, and that's the variant written to break `TypeOK`, so nothing
here is caught for the wrong reason.

### Family P

| id | token | rc | obligation reported |
|---|---|---|---|
| P01 | `OK` | 0 | none |
| P01S03 | `SAFETY_VIOLATION` | 12 | `SheDistributesOnlyWhenClear`, not the weakened property |
| P02 | `OK` | 0 | none |
| P02S07 | `SAFETY_VIOLATION` | 12 | `SheDistributesOnlyWhenClear`, not the weakened property |
| P03 | `LIVENESS_VIOLATION` | 13 | `TheEstateIsEventuallyDistributed`, 6 states |
| P04 | `OK` | 0 | none |
| P05 | `OK` | 0 | none |
| P05S06 | `OK` | 0 | none |

### Follow-up probes, authored after the runs

Two questions the frozen matrix raised and couldn't answer, so these sit under
`step2-variants/probes/` and are marked as outside the matrix. Nothing in the
matrix moved to accommodate them.

The first: P01S03 and P02S07 came back rc=12 on an obligation I hadn't touched,
which leaves it open whether the weakened property went blind or simply lost the
race. `ISO*` re-runs each pair under a cfg carrying one `PROPERTIES` line and
nothing else.

| probe | cfg carries | rc | obligation |
|---|---|---|---|
| ISO03 | `ClaimsStartWithTheCreditor` over S03 | 13 | `ClaimsStartWithTheCreditor` |
| ISO03W | the same, weakened subscript | 0 | none |
| ISO07 | `TheNoticeNeverReopens` over S07 | 13 | `TheNoticeNeverReopens` |
| ISO07W | the same, weakened subscript | 0 | none |
| ISO06 | `ADecisionStands` over S06 | 13 | `ADecisionStands` |
| ISO06W | the same, weakened subscript | 0 | none |

The second: whether the ninth cfg line `DESCRIPTION.md` §3 offers actually
catches S19, and whether it leaves the reference green.

| probe | rc | obligation |
|---|---|---|
| R01REF | 0 | none, 138 generated and 77 distinct, unchanged |
| R01S19 | 13 | `SheTakesOneClaimAtATime`, 4 states |

## 5. Findings

The gate is red, on one variant, and finding 3 is the whole of it. Six of the
seven that stayed uncaught have a structural cause I can name, and §6's rule is
that an uncatchable variant with a named cause is a finding and not a failure.
S19 is the exception, and it's catchable.

### 1. S19 is uncaught, and a ninth cfg line closes it

The batch decision passes all eight obligations at rc=0 and passes every vacuity
probe. That's what the description predicted, and the prediction held. Two
creditors decided in one step satisfy items 2, 3 and 4 for both of them, and no
other item reads a step at all.

It isn't structural. §3 of the description offers the repair and hands the call
to this pass, so here's the measurement it asked for. Add one `PROPERTIES` line:

```tla
SheTakesOneClaimAtATime ==
    [][\A a \in Creditors :
          \A b \in Creditors :
              (/\ a # b
               /\ Observe.standing[a] # Observe'.standing[a])
                  => Observe.standing[b] = Observe'.standing[b]]_Observe
```

R01S19 comes back rc=13 against it at 4 states, and R01REF stays rc=0 at 138
generated and 77 distinct, which is the reference's own count unchanged. Nine
cfg lines is still inside the five-to-nine band, so the vector doesn't move.

I'd add it. §2 of the description says a ninth item "would be redundant against
these seven rather than new", and the measurement says that's wrong: this one
catches a store nothing else catches. §3 of the same file says the opposite, so
the two sections already disagree and this settles which is right. It also
closes the one gap between the reference and Rule 5's "she takes one claim at a
time", which is otherwise ungraded.

The cost is one degree of the author's freedom, and I think it's worth paying.
Under shape A the learner writes the whole store, and a batch model is the kind
of thing a learner writes by accident when they reach for a set.

Applying it is §9.5b's job, not mine. The reference is untouched.

### 2. The two bad openings are caught, but not by the property set

I predicted S25 and S26 would come back green and unrepairable without an
opening item. They do come back green at rc=0 against all eight obligations.
`harness/vacuity.sh` then catches both at rc=5, `VACUOUS_DEAD_ACTION`, and I
think this is the most useful thing in the report.

A wrong opening leaves actions permanently disabled, and that's visible where a
property isn't. S25 starts every creditor lodged, so `Lodge` and `ComeForward`
never fire and the probe names both with the guard that never came true. S26
starts the notice closed, so `Lodge`, `Close`, `Decide` and `Pay` all die.

So the opening isn't ungraded. It's graded one layer up, by the harness rather
than by the cfg, and the description's ambiguity 13 gets to keep its spare line.
That's worth carrying to the other rungs: an `Init` mutation that starves an
action is a vacuity finding, not a property finding, and a step 2 gate that runs
only the cfg will call it a pass.

I'd stop short of saying every bad opening lands this way. These two starve an
action. One that doesn't wouldn't be seen, and I haven't built one.

### 3. S09 is §5.3's fourth vacuity vector, reproduced in the field

Dropping `Distribute` from `Next` while `WF_vars(Distribute)` stays in `Spec`
gives rc=0 with 61 distinct states and every obligation green, including the
liveness one. `vacuity.sh` returns rc=7, `VACUOUS_UNSATISFIABLE`.

This is the shape §5.3 describes from `harness/fixtures/vacuity/UnsatFairness.tla`,
and this is the first time I know of that it's turned up in a real problem's
variant set rather than in a purpose-built fixture. The failure direction is the
bad one: a passing run that means only there was nothing to fail.

Worth knowing for the grading engine. A learner who deletes an action and leaves
its fairness conjunct hands in a spec that passes everything.

### 4. The wrong-subscript escape reproduces three times out of three

Every action property here is subscripted `_Observe`. Subscript one on a field
instead and it goes blind to any step that leaves that field alone, because the
property is then satisfied by its own stuttering disjunct.

ISO03, ISO07 and ISO06 each catch their system variant at rc=13. The weakened
form of each catches nothing at rc=0. The state counts say the same thing from
the other side: ISO03W explores 97 distinct against S03's 6 before the violation,
and ISO07W explores 144, so the weakened property isn't stopping the search at
all.

The matrix run hid this. P01S03 and P02S07 both came back rc=12 on
`SheDistributesOnlyWhenClear`, an obligation I never touched, because S03 and
S07 each break that invariant too and the invariant sits earlier in the search.
Incidental coverage, exactly qsl's finding 8. A learner whose subscript is wrong
still passes, and passes for a reason that has nothing to do with the property
they got wrong.

P05S06 is the clean case. `ADecisionStands` subscripted on `distributed` misses
S06 outright at rc=0, with the full 77 states explored and nothing else catching
it.

Form left open 1 puts the subscript in the learner's hands on item 7. My read is
that the subscript is worth withholding more widely than that on this problem,
because it's live on five of the six action properties and not just the one.

### 5. Blanket fairness passes, as the description said it would

P04 replaces the four named conjuncts with `WF_vars(Next)` and comes back rc=0
with the reference's own 138 generated and 77 distinct. The description's §5
argument holds: every action here disables itself for good, `Creditors` is
finite, so the graph is a finite DAG with no terminal state holding the residue.

No property change catches this and I don't think one can. It's a claim about
which behaviours `Spec` admits, and both forms admit a superset containing the
same violating-free set. The catch has to happen in the statement, which is
where form left open 1 already puts it.

### 6. All four fairness conjuncts are load-bearing, one at a time

The description's §2 says item 7 is false if any one of the four is dropped. It
is, and each drop breaks it at a different length: S11 at 5 states, S10 and S12
at 7, S13 at 9. P03 drops all four and breaks at 6.

That's a claim the description made and the measurement confirms, which I'd
rather record than leave implied.

### 7. Barring the late step changes nothing in the state count

`ALTERNATIVES.md` says barring `ComeForward` after the distribution "would cut
the distributed layer from four places per creditor to three". S22 does exactly
that and comes back at 77 distinct, the reference's own count, with 130 states
generated against 138.

So the counterfactual is wrong even though the conclusion isn't. A creditor
reaches out of time before the distribution, with the notice closed and the
residue still in hand, and the estate distributes over him. The late step adds
generated states and no distinct ones. The author checked the shipped number and
got it right. The reasoning about which layer the late step buys didn't get
tested, and it doesn't hold.

### 8. Who acts is invisible, and the counts prove it

S28 gives `Close` a creditor parameter, so a creditor closes the executor's
notice. rc=0, and 77 distinct states, identical to the reference. Generated goes
from 138 to 163, which is just the same close reached through two witnesses.

The description says this in §3 and I'd have believed it without the run. Having
the number is better, and the statement author can use it: no property over
`Observe` will ever say who acted, whatever fields get added.

### 9. The three restrictions and the one stutter

S18, S21 and S22 each remove behaviours and add none. S18 makes her wait for the
close before deciding, S21 obliges the creditors to lodge, S22 bars the late
step. Every behaviour that survives satisfies every obligation, so no linear-time
property can see the ones that stopped existing. S18 drops the space from 77
distinct to 56, and S22 and S21 leave it at 77.

S20 drops the `distributed = FALSE` guard so `Distribute` can fire twice. The
second firing leaves all three variables where they were, which is a stutter
under `[Next]_vars` and generates no state. 154 generated against 138, 77
distinct either way.

Four uncatchables with named causes, all four predicted before the runs.

### 10. A relative module path costs you `Gate.tla`

Running the postcondition with the module named relatively gives rc=150,
`PARSE_ERROR`, with `TLA-Library` set and pointing at `harness/`. The same run
with the module absolute gives rc=0. That's `harness/vacuity.sh:240-250`
describing the trap from the other direction, and it cost me two runs.

Anyone driving `verdict.sh -p` by hand wants both paths absolute. The note in
`vacuity.sh` says the cwd is searched on a relative main path, which is true and
isn't enough, because the cwd here is the worktree root and `Gate.tla` lives one
directory down.

## 6. For the statement author

One violating variant per obligation, all under 10 states. The satisfying halves
come from the reference, which is green.

| obligation | pick | trace | shortest available |
|---|---|---|---|
| `TypeOK` | S14 | 2 states | S14 |
| `SheDistributesOnlyWhenClear` | S01 | 4 states | S27, initial state |
| `ClaimsStartWithTheCreditor` | S03 | 3 states | S04 or S16 or S24, 2 states |
| `ALodgedClaimEndsInHerDecision` | S05 | 3 states | S05 |
| `ADecisionStands` | S06 | 4 states | S06 |
| `TheNoticeNeverReopens` | S07 | 3 states | S07 |
| `TheDistributionIsNeverUndone` | S08 | 4 states | S08 |
| `TheEstateIsEventuallyDistributed` | S10 | 7 states, then stuttering | S11, 5 states |

Where the pick differs from the shortest, it's because the pick is the break the
description's §2 names, and that break is the one a person would recognise. S01
is the estate distributed with a claim still lodged. S03 is the creditor lodging
after the close. S10 is the executor who never closes, which is the stall Rule 9
exists to rule out.

The liveness trace is a lasso. TLC reports 7 states and then the behaviour
stutters there forever, with the notice open, nothing lodged and nothing
distributed. Any of S10 through S13 gives the same shape at a different length,
so pick on which stall reads best rather than on the count.

S27 is the shortest violation in the whole matrix and it's reported against the
initial state with no trace at all, so it's a poor trace pair even though it's
the cheapest catch. S02 at 2 states is the one to use if the length matters.

## 2b, the repair

Written under V2-PLAN §9.5b against the same reference, at the same bead. The
matrix above didn't move and nothing under `step2-variants/` was edited. Finding
1 named the one uncaught catchable variant and specified the property that closes
it. I applied that property and re-ran the whole checklist, and the re-run below
is the gate rather than the intent.

### What changed

`EstateNotice.tla` gains one operator and `EstateNotice.cfg` gains one
`PROPERTIES` line. Nothing else in either file moved.

```tla
SheTakesOneClaimAtATime ==
    [][\A a \in Creditors :
          \A b \in Creditors :
              (/\ a # b
               /\ Observe.standing[a] # Observe'.standing[a])
                  => Observe.standing[b] = Observe'.standing[b]]_Observe
```

That's finding 1's text character for character, which is the point of splitting
the two passes. The cfg is now 2 `INVARIANTS` lines and 7 `PROPERTIES` lines, so
nine in all. The band runs five to nine, so property count stays at 2 and the
vector doesn't move.

### How the variants were re-run

The frozen modules don't define `SheTakesOneClaimAtATime`, so the repaired cfg
names an operator they haven't got and TLC answers with a config error rather
than a verdict. Copying is the way round that, and it's what the R01 probes
already did for one variant.

Each of the 36 frozen modules was copied to a scratch tree with the operator
spliced in above the module's closing line, and the repaired reference cfg was
copied in beside it. The originals were read and never written. The scratch tree
is deleted.

### The six gate checks, re-run

```
harness/verdict.sh -t 120 --config $REF/EstateNotice.cfg $REF/EstateNotice.tla
    OK                   rc=0
harness/verdict.sh -t 120 --config $REF/EstateNotice.cfg $REF/EstateNotice.tla -- -inv FALSE
    SAFETY_VIOLATION     rc=12
harness/verdict.sh -t 120 --config $REF/EstateNotice.cfg -p Gate!NonVacuous $REF/EstateNotice.tla
    OK                   rc=0
harness/vacuity.sh -c $REF/EstateNotice.cfg -n 4 -t 120 \
    --expect-actions Lodge,ComeForward,Close,Decide,Pay,Distribute \
    --observe Observe $REF/EstateNotice.tla
    NON_VACUOUS          rc=0
```

All five vacuity probes pass, the same five section 3 lists.

Action coverage from the plain run. The check is `total == 0`.

| action | distinct : total |
|---|---|
| `Init` | 1 : 1 |
| `Lodge` | 3 : 10 |
| `ComeForward` | 8 : 20 |
| `Close` | 4 : 25 |
| `Decide` | 28 : 44 |
| `Pay` | 20 : 22 |
| `Distribute` | 13 : 16 |

No action sits at zero, and every pair is the pair section 3 recorded.

Counts: 138 states generated, 77 distinct, complete graph depth 9. All three are
section 3's numbers unchanged, so the ninth obligation costs nothing in the state
space. R01REF said it wouldn't and it didn't.

### Every variant against the repaired cfg

The command is the one section 4 used, with the scratch paths in place of the
frozen ones.

```
harness/verdict.sh -t 120 --config $SCRATCH/<id>.cfg $SCRATCH/<id>.tla
```

| id | rc | obligation reported | against section 4 |
|---|---|---|---|
| S01 | 12 | `SheDistributesOnlyWhenClear` | same |
| S02 | 12 | `SheDistributesOnlyWhenClear` | same |
| S03 | 13 | `ClaimsStartWithTheCreditor` | same |
| S04 | 13 | `ClaimsStartWithTheCreditor` | same |
| S05 | 13 | `ALodgedClaimEndsInHerDecision` | same |
| S06 | 13 | `ADecisionStands` | same |
| S07 | 13 | `TheNoticeNeverReopens` | same |
| S08 | 13 | `TheDistributionIsNeverUndone` | same |
| S09 | 0 | none, `vacuity.sh` at rc=7 | same |
| S10 | 13 | `TheEstateIsEventuallyDistributed` | same |
| S11 | 13 | `TheEstateIsEventuallyDistributed` | same |
| S12 | 13 | `TheEstateIsEventuallyDistributed` | same |
| S13 | 13 | `TheEstateIsEventuallyDistributed` | same |
| S14 | 12 | `TypeOK` | same |
| S15 | 13 | `ADecisionStands` | same |
| S16 | 13 | `ClaimsStartWithTheCreditor` | same |
| S17 | 13 | `ALodgedClaimEndsInHerDecision` | same |
| S18 | 0 | none, `vacuity.sh` at rc=0 | same |
| S19 | 13 | `SheTakesOneClaimAtATime`, 4 states | **moved from rc=0** |
| S20 | 0 | none, `vacuity.sh` at rc=0 | same |
| S21 | 0 | none, `vacuity.sh` at rc=0 | same |
| S22 | 0 | none, `vacuity.sh` at rc=0 | same |
| S23 | 13 | `ALodgedClaimEndsInHerDecision` | same |
| S24 | 13 | `ClaimsStartWithTheCreditor` | same |
| S25 | 0 | none, `vacuity.sh` at rc=5 | same |
| S26 | 0 | none, `vacuity.sh` at rc=5 | same |
| S27 | 12 | `SheDistributesOnlyWhenClear`, initial state | same |
| S28 | 0 | none, `vacuity.sh` at rc=0 | same |
| P01 | 0 | none | same |
| P01S03 | 12 | `SheDistributesOnlyWhenClear` | same |
| P02 | 0 | none | same |
| P02S07 | 12 | `SheDistributesOnlyWhenClear` | same |
| P03 | 13 | `TheEstateIsEventuallyDistributed` | same |
| P04 | 0 | none | same |
| P05 | 0 | none | same |
| P05S06 | 0 | none | same |

### What moved

One row out of 36. S19 went from rc=0 to rc=13 on `SheTakesOneClaimAtATime`, at a
four-state trace: both creditors lodge, then `DecideTwo(c1, c2)` settles both in
one step. That's the length and the shape R01S19 measured, so the isolated probe
and the full cfg agree.

Nothing else moved. Every previously caught variant came back on the same
obligation, and the three vacuity codes are unchanged at S09 rc=7, S25 rc=5 and
S26 rc=5. Family P is identical row for row.

Family S is now 20 of 28 caught by an obligation. Eight stay uncaught by the cfg,
and three of those are caught a layer up by `vacuity.sh`. That leaves five
uncaught outright, each with a cause section 5 already names: S18, S21 and S22
are restrictions, S20 is a stutter, and S28 is interface blindness. P04 is the
sixth, and finding 5 is the argument that no property change catches it.

I'd read that as the gate closing. The one variant that was catchable is caught,
and every variant still standing has a structural reason rather than a gap.

### A count in section 4 that doesn't add up

Section 4 says "21 of 28 caught by an obligation, and 3 more by `vacuity.sh`".
Its own family S table carries 19 rows at rc=12 or rc=13 and 9 rows at rc=0. I
get 19 whichever way I count it, so I think the 21 is an arithmetic slip rather
than a disagreement about what counts as caught. The vacuity clause is right at
3. After the repair the caught count is 20 and the uncaught count is 8.

### One row for section 6

The trace table gains one line. Section 6 above stands as written otherwise.

| obligation | pick | trace | shortest available |
|---|---|---|---|
| `SheTakesOneClaimAtATime` | S19 | 4 states | S19 |

S19 is the only variant in the matrix that breaks this obligation, so the pick
and the shortest are the same module and there's no choice to make. The break
reads as a person would tell it: two creditors have lodged, and she settles both
of them in one act. That's the batch model a learner writes when they reach for a
set, which is why the obligation is worth its line under shape A.
