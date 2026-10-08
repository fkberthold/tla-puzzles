# Spike: a transaction that can neither commit nor time out

Apache Kafka KAFKA-20090, built 2026-10-08 against TLC 2026.07.31.184830.
Every row came from `harness/spike-measure.sh`, and `measure.sh` in this
directory re-runs the whole sweep. Raw rows are in `measurements.tsv`.

Two headlines, and the second one is worth more.

The problem is small. The broken model is 4 variables and 21 distinct states,
and the whole 31-model sweep is about 7 seconds of wall clock. The
counterexample is the issue body's four numbered steps in order, with nothing
added.

The liveness property the problem is about does **not** isolate the defect.
`TxnBeginChecks.tla` is a one-line repair where every transaction eventually
ends and the coordinator still hands a fenced client an epoch it can never
use. So a learner who writes the stated requirement faithfully gets a green
run on a spec that still has the bug. I think that's the best thing in this
candidate, and it's the same shape the fencing spike found from the other
direction.

## The measured row

The headline model is `MCBrokenLiveness`: **4 variables, 21 distinct states,
depth 12, 0.4 seconds**, exit 13. The `TxnBroken` row stops at 16 states
because TLC halts at the first invariant violation, so 21 is the full space.

| label | rc | verdict | secs | distinct | depth | vars |
|---|---|---|---|---|---|---|
| TxnBroken | 12 | invariant violated | 0.4 | 16 | 8 | 4 |
| MCBrokenLiveness | 13 | property violated | 0.4 | 21 | 12 | 4 |
| MCBrokenNoFair | 13 | property violated | 0.4 | 21 | 12 | 4 |
| MCBrokenStuck | 12 | invariant violated | 0.3 | 19 | 10 | 4 |
| MCBrokenDeadlock | 11 | deadlock reported | 0.4 | 21 | 12 | 4 |
| MCWitnessOngoing | 12 | invariant violated | 0.3 | 2 | 2 | 4 |
| MCWitnessAborted | 12 | invariant violated | 0.3 | 7 | 4 | 4 |
| MCWitnessRotation | 12 | invariant violated | 0.3 | 4 | 3 | 4 |
| MCWitnessCeiling | 12 | invariant violated | 0.3 | 12 | 6 | 4 |
| TxnFenceRotates | 0 | checked, no violation | 0.3 | 18 | 9 | 4 |
| MCFenceRotatesLiveness | 0 | checked, no violation | 0.3 | 18 | 9 | 4 |
| MCFenceRotatesCeiling | 0 | checked, no violation | 0.3 | 18 | 9 | 4 |
| MCFenceRotatesWork | 12 | invariant violated | 0.4 | 4 | 3 | 4 |
| TxnBeginChecks | 12 | invariant violated | 0.4 | 16 | 8 | 4 |
| MCBeginChecksLiveness | 0 | checked, no violation | 0.4 | 18 | 9 | 4 |
| MCBeginChecksWork | 12 | invariant violated | 0.4 | 4 | 3 | 4 |
| TxnRetryGuarded | 0 | checked, no violation | 0.4 | 18 | 9 | 4 |
| MCRetryGuardedLiveness | 0 | checked, no violation | 0.3 | 18 | 9 | 4 |
| MCRetryGuardedWork | 12 | invariant violated | 0.3 | 4 | 3 | 4 |
| TxnDoubleBump | 0 | checked, no violation | 0.3 | 30 | 12 | 4 |
| MCDoubleBumpLiveness | 0 | checked, no violation | 0.3 | 30 | 12 | 4 |
| MCDoubleBumpFenceable | 12 | invariant violated | 0.3 | 21 | 8 | 4 |
| MCBroken4 | 13 | property violated | 0.3 | 39 | 18 | 4 |
| MCBroken16 | 13 | property violated | 0.3 | 147 | 54 | 4 |
| MCFenceRotates16 | 0 | checked, no violation | 0.3 | 144 | 51 | 4 |
| TxnUnbounded | 0 | checked, no violation | 0.3 | 75 | 27 | 4 |
| MCUnboundedWork | 12 | invariant violated | 0.3 | 66 | 24 | 4 |
| MCUnboundedFree | 124 | hit the 120s budget | 120.1 | 61,735,435 | - | 4 |
| MCBrokenCoverage | 0 | checked, no violation | 0.3 | 21 | 12 | 4 |
| MCFenceRotatesCoverage | 0 | checked, no violation | 0.3 | 18 | 9 | 4 |
| MCReInertProbe | 0 | checked, no violation | 0.3 | 18 | 9 | 4 |

The `vars` column reads 4 on every row and 4 is what every module declares.
The over-count the fencing spike reported at
`sources/spikes/fencing/REPORT.md` is gone on this build, so somebody fixed
the awk. `depth` is the depth of the state-graph search and not the
counterexample length, which matters for the `MCBrokenNoFair` row below.

The counter's range is close to linear in cost, which I didn't expect going
in. `MaxEpoch` of 2, 4 and 16 gives 21, 39 and 147 distinct states. The real
coordinator's ceiling is `Short.MaxValue`, so a learner who reaches for the
real number pays about 32,767 times the states of a model that finds the same
bug. Two is enough.

One number in that table does not reproduce. `MCUnboundedFree` is a timeout,
so its distinct-state count is whatever the run got through in 120 seconds,
and three runs gave 61,439,301, 61,735,435 and 62,615,625. Read it as an
order of magnitude. Every other row reproduced byte for byte across three
sweeps.

## What the request channel costs, which is nothing

4 variables: `txn`, `cEpoch`, `pEpoch`, `pState`. There's no message set, no
request record and no epoch field on a request.

A client sitting in `pState = "ending"` **is** an EndTxn in flight, and the
epoch it carries is `pEpoch`. Nothing changes `pEpoch` while `pState` is
`"ending"`, because only the coordinator's response changes it and the
response is the step out of `"ending"`. So "a late end-transaction request
carrying the previous epoch" needs no variable of its own, and the whole
lateness of the request is the interleaving TLA+ hands you for free.

That also deleted a hazard the brief warned about. A `none` marker would have
been a model-value constant, and the model has no marker at all.

## The counterexample

`MCBrokenLiveness`, exit 13, at `MaxEpoch = 2`. Transcribed from TLC's
output with `pEpoch` and `cEpoch` shortened to `p` and `c`.

```
State  1: Initial          txn=Empty          p=0  c=0  ready
State  2: Begin            txn=Ongoing        p=0  c=0  inTxn
State  3: RequestEnd       txn=Ongoing        p=0  c=0  ending
State  4: EndBump          txn=Empty          p=1  c=1  ready
State  5: Begin            txn=Ongoing        p=1  c=1  inTxn
State  6: TimeoutFence     txn=PrepareAbort   p=1  c=2  inTxn     step 1
State  7: RequestEnd       txn=PrepareAbort   p=1  c=2  ending
State  8: EndRetry         txn=PrepareAbort   p=2  c=2  ready     step 2
State  9: CompleteAbort    txn=CompleteAbort  p=2  c=2  ready
State 10: Begin            txn=Ongoing        p=2  c=2  inTxn     step 3
State 11: RequestEnd       txn=Ongoing        p=2  c=2  ending
State 12: EndRefused       txn=Ongoing        p=2  c=2  ready     step 4
State 13: Stuttering
```

The four marked states are the issue body's four numbered steps, in the order
it gives them. State 12 is the stuck transaction: `txn` is `"Ongoing"`, and
`cEpoch = MaxEpoch` so no bump is available to either the commit path or the
timeout path.

## Why that stuttering tail is the run and not the tail

A liveness counterexample can't be a finite prefix, so TLC closes one with a
cycle. Here the cycle is a self-loop, printed as "State 13: Stuttering". That
is also exactly what a counterexample looks like when the fairness conjunct
is missing, so the tail on its own says nothing. Two controls settle it.

`MCBrokenNoFair` is the same property against `Spec` instead of `FairSpec`.
It also exits 13, at the same 21 states and the same graph depth of 12, which
is why the `depth` column can't tell them apart. The counterexamples are
nothing alike:

```
State 1: Initial      txn=Empty    p=0  c=0  ready
State 2: Begin        txn=Ongoing  p=0  c=0  inTxn
State 3: RequestEnd   txn=Ongoing  p=0  c=0  ending
State 4: Stuttering
```

Three steps, and at state 3 both `EndBump` and `TimeoutFence` are enabled.
The behaviour just stops. TLC v1.8.0 says so itself, which I hadn't expected
and which is worth knowing when you set this problem:

> Warning: The stuttering counterexample above may be caused by the absence
> of a fairness constraint in the behavior specification Spec defined at line
> 202 ... To rule out such counterexamples, conjoin a suitable fairness
> constraint to Spec.

`MCBrokenDeadlock` asks the independent question. `CHECK_DEADLOCK TRUE` and
no invariant at all, so the only thing TLC can report is a state with no
successors. It exits 11 on a state identical to the liveness trace's state
12: `txn` is `"Ongoing"`, `p = c = 2`, client ready. So the tail is a real
terminal state rather than an artifact of how the property was stated.

The deadlock run is a control and not a second detector, because this spec
has no other terminal state to confuse it with. That's measured rather than
assumed, and `NoStuckTxn` exists so the question doesn't depend on it.

## The property and the fairness condition, quoted

From `TxnBroken.tla`. The requirement as stated in the brief, "every
transaction can eventually be committed or aborted":

```tla
TxnEventuallyEnds == (txn = "Ongoing") ~> (txn # "Ongoing")
```

The fairness conjunct, and the spec it sits on:

```tla
Spec     == Init /\ [][Next]_vars
FairSpec == Spec /\ WF_vars(Next)
```

`MCBrokenLiveness.cfg` names `SPECIFICATION FairSpec` and `PROPERTY
TxnEventuallyEnds`, with `CHECK_DEADLOCK FALSE` so the temporal property is
what reports.

Both subscripts are the tuple of every variable. That's the default for the
reason `.claude/rules/tla-practice.md` section 2 quotes from 8.4 p. 96, and
it's what 96.2% of the resolvable box sites in that survey do.
`WF_vars(Next)` on the whole disjunction is weaker than per-action fairness,
and it's strong enough here: `MCFenceRotatesLiveness` exits 0 under the same
conjunct, so the fairness isn't doing the failing.

`FairSpec` is machine closed by the 8.9.2 p. 112 rule, since the liveness
half is one weak-fairness conjunct on a subaction of `Next`.

## The one state predicate that does isolate the defect

```tla
NoExhaustedEpochHeld == pEpoch # MaxEpoch
```

The coordinator never leaves the client holding an epoch that no bump can
move off. `EndBump` hands out at most `MaxEpoch - 1`, `EndRotate` hands out
0, and `EndRetry` is the only action in the module that can put `MaxEpoch`
into `pEpoch`. So the defect violates it and nothing else does.

Here's the pair that makes it worth having. `TxnBeginChecks.tla` adds one
conjunct to `Begin`, which is the `ProducerEpochExhausted` error the issue
thread proposes as defense in depth. On that spec:

| check | rc |
|---|---|
| `TxnEventuallyEnds` under `FairSpec` | 0 |
| `NoExhaustedEpochHeld` | 12 |

The liveness property is repaired and the defect is still there. The client
holds the exhausted epoch, it just can't start a transaction with it, so the
system stops accepting work instead of trapping a transaction. An
availability failure rather than a stuck one.

So the stated requirement is weaker than the defect, and a learner who checks
only the stated requirement can ship this repair and believe they're done. I
think that's the exercise.

## Three one-line fixes at three sites, and they aren't equivalent

| module | the one change | liveness | invariant | system stays open |
|---|---|---|---|---|
| `TxnFenceRotates` | the fencing abort rotates | 0 | 0 | yes |
| `TxnRetryGuarded` | the retry predicate checks the ceiling | 0 | 0 | no |
| `TxnBeginChecks` | transaction entry checks the ceiling | 0 | 12 | no |

`TxnFenceRotates` is the real fix, and it's the one the issue converged on.
Artem Livshits on the thread: "the `!isEpochFence` prevents the proper
producer id rotation and we end up in this state. I think just removing the
`!isEpochFence` condition should fix the issue."

`MCFenceRotatesCeiling` is the same assertion as `MCWitnessCeiling`, which
asserts the counter never reaches `MaxEpoch`. It exits 0 on the repaired spec
and 12 on the broken one. One assertion, two verdicts, and that pair is the
measurement: the repair doesn't guard the ceiling, it makes the ceiling
unreachable.

The other two close the hole by refusing work. After the ceiling they both
reach a terminal state where no new transaction can start, so their exit 0 is
partly the clean-because-idle hazard. `MCRetryGuardedWork` and
`MCBeginChecksWork` are the probes that say work happened first, and both
exit 12.

## What I made the next bump do, and the source was silent on it

The brief is right that the source doesn't say. The issue body says the
fencing abort "bumps the epoch to max" and stops. The 24 comments don't say
what a bump from max does either. The nearest thing is a statement that the
case shouldn't arise: "abort completes and finishes producer id rotation (if
initiated), thus we never have epoch==max in completed state."

**I made a bump at the ceiling unavailable.** `CanBump == cEpoch < MaxEpoch`
guards every write to the counter, so at `cEpoch = MaxEpoch` neither the
commit path nor the fencing path is enabled. That's the reading that makes
both halves of step 4 true at once, since step 4 says "we cannot commit this
transaction with TV2 and we cannot timeout the transaction".

Two alternatives, and the world where each would win.

**Saturate.** A bump at the ceiling leaves the counter at the ceiling and
reports success. I'd take this if step 4 had named only one of the two
failures, because a saturating commit succeeds and the transaction ends. It
contradicts "cannot commit", so I rejected it.

**Wrap to zero.** This reuses epochs, which is a safety bug rather than a
liveness one, and the fencing spike already covers epoch reuse at
`FencedRestart.tla`. Different problem.

What the source does settle, and it changed the model, is the asymmetry
between the two bump sites. The normal end path renews an exhausted epoch and
the fencing path doesn't. Livshits again: "If epoch is max - 1, then rotate
producer id, set epoch to 0." So `EndRotate` renews at `MaxEpoch - 1` and
`TimeoutFence` bumps past it.

That asymmetry is load-bearing. I built the model without it first, and the
stuck state was then reachable by a path that never touches `EndRetry`: climb
to the ceiling by ordinary commits, then start one more transaction. With the
renewal in place the ceiling is reachable only through `TimeoutFence`, and
the client can only get a usable copy of it through `EndRetry`. So the defect
is necessary for the failure, which is what makes this a problem about the
defect rather than about arithmetic.

I collapsed the producer id away and kept only the epoch reset. The cost is
that epochs repeat across a renewal, which none of these properties can see
and which the fencing spike shows is its own safety bug. Adding `cPid` and
`pPid` would be 6 variables instead of 4 and would buy nothing for this
property.

## The climbing counter that erases the whole problem

`TxnUnbounded.tla` is the same module with `CanBump == TRUE` and `Exhausted
== FALSE`. The trap predicate isn't merely unviolated there, it's
unsatisfiable, so the brief's warning is right and it's worth stating
precisely: a climbing counter leaves the two predicates with no value to
disagree at.

`Bound` in that module is a `CONSTRAINT` bound and nothing in the next-state
relation reads it. Keeping the two roles in separate names is the point. A
ceiling changes what the system does, a constraint changes only how much of
it TLC looks at. `TxnUnbounded.cfg` exits 0, and all that establishes is no
violation among the states reachable without `cEpoch` passing 8.

`MCUnboundedFree` drops the constraint and hits the 120-second budget at
61,735,435 distinct states. Same asymmetry the fencing spike found: an
unbounded counter costs nothing when the answer is a counterexample and
everything when the answer is a proof.

## Is the off-by-one reachable

Yes, and the brief was right to ask, because the project has been bitten by
an unreachable one before.

`MCWitnessCeiling` asserts `cEpoch # MaxEpoch` and requires TLC to refute it.
Exit 12 at 12 distinct states and depth 6, so the ceiling is reached early
and the disagreement is live. The disagreement itself is between two
predicates a reader can hold side by side:

```tla
CanBump    == cEpoch < MaxEpoch                    the ending rule
IsRetry(e) == cEpoch > 0 /\ e = cEpoch - 1        the retry predicate
```

`IsRetry` asks nothing about the ceiling, so at `cEpoch = MaxEpoch` it
accepts a request and answers it with an epoch the ending rule will refuse
forever. Three sites can close that, and they're the three fix modules above.

The reachability isn't free, though, and this is the part I'd flag to anyone
setting the problem. The counter has to climb to `MaxEpoch - 1` by ordinary
commits before the fence can push it over, and that's two transactions at
`MaxEpoch = 2`. A model with `MaxEpoch = 1` can't reach the bug, and there's
no signal in a green run that separates it from a correct one.
`MCWitnessRotation` is the cheap guard, at exit 12 and 4 states.

## The vacuity probes

16 probes. 13 refuted the thing they asserted, 1 came back clean on purpose,
and 2 came back `VACUOUS_DEAD_ACTION`. Both of those last two are facts about
the systems rather than defects in the models, and I'd resist the urge to
"fix" either.

`harness/vacuity.sh` ran all five of its vectors over three models, driven by
`vacuity.sh` in this directory. `--expect-actions` carries all nine action
names, because the `total == 0` predicate can't see a deleted action: TLC
prints one coverage row per disjunct of `Next`, so a deleted disjunct has no
row to match.

| probe | model | asserted | rc | what it establishes |
|---|---|---|---|---|
| vectors 1, 2, 4 | `MCFenceRotatesCoverage` | - | 0 | 18 states, an invariant configured, `Spec` satisfiable |
| vector 3 | `MCFenceRotatesCoverage` | - | 0 | all 9 actions fired |
| vector 3 | `MCBrokenCoverage` | - | 5 | `ReInit` never fires |
| vector 3 | `TxnDoubleBump` | - | 5 | `EndRetry` never fires |
| vector 5 | all three | - | - | not run, no observation operator named |
| `MCWitnessOngoing` | broken | no transaction opens | 12 | one does, at 2 states |
| `MCWitnessAborted` | broken | the abort branch never runs | 12 | it does, at 7 states |
| `MCWitnessRotation` | broken | the counter never reaches `MaxEpoch - 1` | 12 | it does, so the normal path ran |
| `MCWitnessCeiling` | broken | the counter never reaches `MaxEpoch` | 12 | it does, so the defect is live |
| `MCFenceRotatesCeiling` | repaired | the same assertion | 0 | the repair makes the ceiling unreachable |
| `MCFenceRotatesWork` | repaired | the counter never reaches `MaxEpoch - 1` | 12 | the repaired system still commits |
| `MCRetryGuardedWork` | `TxnRetryGuarded` | the same | 12 | work happens before the wall |
| `MCBeginChecksWork` | `TxnBeginChecks` | the same | 12 | work happens before the wall |
| `MCDoubleBumpFenceable` | `TxnDoubleBump` | an open transaction is always fenceable | 12 | the double bump loses that near the ceiling |
| `MCReInertProbe` | repaired | `ReInit` never fires at the rotation threshold | 0 | why one seeded variant is inert |
| `MCBrokenNoFair` | broken | the liveness property, no fairness | 13 | a 3-step useless counterexample |

The liveness half has its own check, because a property that only ever fails
hasn't been shown to be checkable. Four models pass `TxnEventuallyEnds` under
the same `FairSpec` conjunct and the same constant:
`MCFenceRotatesLiveness`, `MCRetryGuardedLiveness`, `MCBeginChecksLiveness`
and `MCDoubleBumpLiveness`, all at exit 0. Each is paired with a work witness
at exit 12, so none of those zeros is a system standing still.

### The two dead actions are the finding, not the bug

`ReInit` never fires in `TxnBroken`. The probe names the conjunct, `pEpoch #
cEpoch`, evaluated 4 times and never true. The reason is the defect from a
third angle. The fencing abort bumps by exactly one, so a late request is
always exactly one epoch behind, so `IsRetry` always matches, so `EndRefused`
is never enabled on that path. The client is never told anything is wrong, so
it never re-initialises. A client that's never told it was fenced has no
reason to recover, and `ReInit` does fire in `TxnFenceRotates`, where the
rotation drops the counter below the client.

`EndRetry` never fires in `TxnDoubleBump`. The probe names `IsRetry(pEpoch)`,
evaluated 6 times and never true. That's the pre-KAFKA-19367 double bump, and
the thread predicted it: a late ABORT "might arrive with an epoch that is
further behind (e.g. currentEpoch - 2), which could make it less likely to be
considered a valid retry". At this size the measurement is stronger than the
prediction. It's never considered one.

Both would read as a red gate. `harness/vacuity.sh` exits 5 on each, and
that's the right verdict for a submission and the wrong lesson for a spike. A
dead action in a model of a broken system can be the brokenness.

## The seeded-mutant pass

`BUGS_CAUGHT`, exit 0. **4 variants caught out of 4 seeded**, after 1 of 5
was dropped as inert. Driven by `matrix/run.sh`, which exists because the
isolation harness refuses any command line carrying the `--alias` token.

The matrix's reference is the repaired spec, `matrix/reference/TxnCoord.tla`.
The oracle is the author's full property and the submission is the thin one a
learner would plausibly write from the stated requirement:

```tla
Oracle!Inv    == TypeOK /\ NoStuckTxn /\ NoExhaustedEpochHeld
Submitted!Inv == NoStuckTxn
```

| variant | the one mutated definition | caught |
|---|---|---|
| `fence-skips-rotation` | `TimeoutFence` bumps and skips the rotation | 12 |
| `endbump-skips-rotation` | `EndBump` drops its `~Exhausted` guard | 12 |
| `rotate-threshold-off-by-one` | `Exhausted == cEpoch = MaxEpoch` | 12 |
| `exhausted-never` | `Exhausted == FALSE` | 12 |
| `reinit-skips-rotation` | `ReInit` always bumps | inert, dropped |

The first one is KAFKA-20090 itself, which is the `!isEpochFence` conjunct put
back.

The inert one is worth reading as a result rather than as housekeeping. The
first run returned `VARIANT_INERT` at rc=42, naming `reinit-skips-rotation`
as a variant the oracle couldn't catch either. That's phase 3 before phase 4
doing the job its header says it does, and the ~39.3% inert figure in that
header says to expect it. I then measured why, rather than inferring it:
`MCReInertProbe` asserts `ReInit`'s guard is never satisfied at the rotation
threshold, and exits 0. The mutated branch is on no reachable path, so the
mutation changes no behaviour. The variant is kept at `matrix/inert/` so the
record survives.

The grading run's trace comparison gave me the one number I'd have had
trouble getting any other way. The submission caught every variant on a
different counterexample than the oracle, and the difference is exactly one
step every time:

```
fence-skips-rotation
  oracle:  8 steps, ending EndRetry
  yours:  10 steps, ending EndRetry -> CompleteAbort -> Begin
```

So `NoStuckTxn` is weaker than the oracle by precisely one `Begin`. The
oracle catches the exhausted epoch when it's handed out. The surrogate
catches it when a transaction opens on it. Same bug, one step later, and
that's a quantitative statement of how much a learner loses by writing only
the stated requirement.

One caveat the harness's own header insists on and I'll repeat. These are
mutants of our correct spec, and ~10.9% of real faulty student specs are one
mutation from correct. 4 of 4 says the submission catches these bugs. It says
nothing about the bug a learner would have written.

## Difficulty

**Level 3, and candidate-selection only.** This is not a placement. Placement
comes from the load vector after the reference is frozen, and nothing below
is a load-vector reading.

By the criterion in `corpus/manifest.tsv`, level 2 is one function-valued
variable over scalars and level 3 is several functions relating multiple
entity kinds. This model has no function-valued variables at all, which pulls
toward level 2 on the structural axis. Four scalars, one of them a bounded
integer and two of them small enumerations.

What I think puts it at 3 anyway is that the structural axis isn't where the
work is. Three things have to be got right and none of them is visible in the
variable count.

The requirement is liveness, so a learner who reaches for an invariant gets a
clean run that proves nothing. Then the fairness conjunct has to go on, or
the counterexample is a 3-step behaviour that merely stopped. Then the stated
property turns out not to isolate the defect, which is the step I'd expect
most people to miss, since `TxnBeginChecks` passes it.

So I'd call it 3 at its upper edge for the property work and 2 for the
modelling, and I'd rather report both numbers than average them. I haven't
checked whether that split generalises past this system, so treat it as a
reading of one problem.

## Discrepancies

**The seeded-bug matrix can't grade this problem's actual property.**
`harness/seeded-bugs.sh:546` writes `INVARIANT $PROPERTY` and offers no
second shape, so a temporal formula can't go through it. Everything the
matrix says here is about a state-predicate surrogate. I think that's worth a
bead rather than a workaround, because the gap bites any liveness problem and
not just this one. The surrogate is sound in this family for a stated reason:
`cEpoch` is monotone except at a renewal, and every write to it is guarded by
`CanBump` or `Exhausted`, so a state with `txn` at `"Ongoing"` and no bump
available can never leave the trap.

`NoStuckTxn` is also stronger than "stuck". It fires the moment a transaction
is open with no bump available, whether or not that state is terminal. In
this family it's sound and it implies the liveness property, which is an
ordinary and attested way to check liveness. It isn't an exact
characterisation and I wouldn't present it as one.

**The matrix refuses `CHECK_DEADLOCK` in a constants fragment.** My first
`matrix/reference/constants.cfg` carried it and the matrix returned
`MATRIX_MALFORMED` at rc=44, which is correct behavior and worth knowing
going in. It means every matrix run has deadlock checking on, and this spec
has terminal states. It happened to be harmless, because breadth-first search
reaches the invariant violation before any terminal state on all four
variants. A spec where the terminal state came first would get rc=11 passed
through, and the report would read as a harness fault.

**The brief predicted the no-fairness run would give a shorter counterexample
and it does, but not in any column `spike-measure.sh` prints.** Both runs
report 21 distinct states and depth 12, because `depth` is the graph search
depth. The trace lengths are 13 and 4. If a future gate wants to tell a
useful liveness counterexample from a useless one, it needs the trace and not
the row.

**One thing I won't rule on.** I didn't check whether `WF_vars(Next)` on the
whole disjunction is the right strength for a problem that grows a second
client. With one producer it's enough and `MCFenceRotatesLiveness` proves it.
With two producers racing for one transactional id, which is case B on the
issue thread, I'd expect per-action fairness to start mattering and I haven't
measured it.

## Files

- `TxnBroken.tla`, the reference, 4 variables and 9 actions
- `TxnFenceRotates.tla`, the real fix, the fencing abort rotates
- `TxnRetryGuarded.tla`, the retry predicate checks the ceiling
- `TxnBeginChecks.tla`, transaction entry checks the ceiling, liveness only
- `TxnDoubleBump.tla`, the pre-KAFKA-19367 behaviour and what it cost
- `TxnUnbounded.tla`, the ceiling deleted, with `Bound` as a constraint
- `MC*.tla`, 22 wrapper modules carrying one config each
- `matrix/`, the seeded-bug matrix: reference, oracle, submission, 4 variants
- `matrix/inert/`, the variant the oracle couldn't catch, kept as a record
- `measure.sh`, `vacuity.sh`, `matrix/run.sh`, the three runners
- `measurements.tsv`, all 31 rows

## Verdict

**Good practice problem, and I'd build it.** The counterexample is a
published issue's own four numbered steps at 21 states and half a second, and
I don't think there's much risk of it feeling synthetic.

Three things I'd change about how it's set.

The property has to be the exercise. Hand a learner the stated requirement in
the issue's own English, let them write it as a temporal property, let them
repair the spec until it passes, and then show them `TxnBeginChecks`. The
finding is that the requirement they were given is weaker than the defect
they were shown. That's the part that transfers, and the fencing spike found
the same gap running the other way, so I suspect it's general to anything
with a deadline or a budget.

Set `MaxEpoch` at 2 and make the learner justify it. The real ceiling is
32,767 and the model that finds the bug is 21 states. A learner who reaches
for the real number pays five orders of magnitude for nothing, and a learner
who picks 1 can't reach the bug at all. Both mistakes are one config line
away and neither shows up in the output.

The three fix sites are the best sub-problem here and I'd use all of them.
They're all one line, they're all plausible, and they aren't equivalent: one
keeps the system working and two close it down, and one of the two leaves the
defect in place. The issue thread argued about exactly this for 24 comments,
so a learner who has to pick is doing the real work rather than a puzzle
version of it.
