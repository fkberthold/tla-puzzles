# Step 5: source, spike and statement read together

Built 2026-10-08 against TLC2 Version 2026.07.31.184830, the project's canonical
build. Bead `tla-pmm2.1`. Three inputs, read in this order so the source could
not be coloured by either half: `argoproj/argo-cd` issue #29410 and PR #29418
from the web, then `sources/spikes/progressive-sync-stale-status/REPORT.md` and
its modules, then `authoring/progressive-sync-stale-status/statement/PROBLEM.md`.

Per decision D4 this report carries no difficulty number and no `VECTOR.md`.

Every claim below carries a command and its output, a `file:line`, a quotation,
or the marker `INFERRED`.

---

## Verdict

**The statement is not sufficient. One change is blocking.**

Rule 4 hands the superintendent a completion signal that cannot go stale.
"A box under issue pastes the amendment in and stops being under issue. That's
a step of the box's, not of hers" (`PROBLEM.md:104`). Rule 7 then lets her read
"which boxes she has out" freely (`PROBLEM.md:130`), and the interface defines
that set as "the boxes she has out that haven't pasted in yet"
(`PROBLEM.md:172`). So membership of `underIssue` drops at the exact moment a
box finishes, and she sees it.

A sign-off guard that reads `underIssue` and her own record of what she has
issued satisfies requirement 1 without consulting the board at all. Rule 7
permits it: the guard is "built out of her records and the board"
(`PROBLEM.md:132`), and that is a permission to use both, not an obligation.

I built that model and ran it. No board, no clerk, six variables, guard
"every box of the district in hand has been issued, and none of them is still
under issue":

```
$ tlc -deadlock -cleanup -noTE -config ZZBoardless.cfg ZZBoardless.tla
Model checking completed. No error has been found.
15 states generated, 14 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 11.
rc=0
```

All seven requirements green. It also passes the statement's own second check,
because a run exists in which head office never issues anything:

```
$ tlc -deadlock -cleanup -noTE -config ZZQuiet.cfg ZZBoardless.tla
Error: Temporal property EverIssues was violated.
rc=13
```

So a learner can pass both of the statement's declared checks over a region in
which the defect the source reports cannot occur. The stale board, which is the
whole subject of issue #29410, is optional.

The statement half-sees this and then mis-files it. "A model with no board can
still report all five fields correctly. It can't state rule 7 at all, because
its superintendent has nothing to read" (`PROBLEM.md:193`). Rule 7 is not one of
the seven checked requirements, so nothing notices that it was never stated.

**The blocking change is one sentence in rule 4.** Leaving `underIssue` has to
be her act on board evidence, not the box's act. That is also what the real
system does. PR #29418 guards the `Waiting` to `Healthy` and `Progressing` to
`Healthy` transitions, and the controller takes those transitions by reading
`app.Status.Sync`, which is the stale copy. Under the amended rule the naive
guard retires a box on a stale line, requirement 1 breaks with a trace, and the
problem works.

Three further changes, none blocking:

- The Checking section's `.cfg` does not parse on this build. Measured in Q4.
- The Checking section should carry a counterexample-depth band, a required red
  run, and the completion probe it is missing. Q4.
- The restart fork is answerable from the source now. Q1.

Two things are right and should not be touched: rule 7's list of her records
(Q2), and requirement 7's final wording (Q4).

---

## Q1. Necessary and not sufficient, verified

### The spike's run reproduces exactly

```
$ tlc -deadlock -cleanup -noTE -config MCNoRestartFixed1.cfg MCNoRestartFixed1.tla
Error: Invariant NoStrandedApp is violated.
State 1: <Initial predicate>   live = <<0,0,0>>  target = 0  step = 1
State 2: <Advance ...>         step = 2
State 3: <Commit ...>          target = 1  step = 2
11 states generated, 8 distinct states found, 4 states left on queue.
The depth of the complete state graph search is 3.
rc=12
```

8 distinct states, depth 3, same invariant, same trace as `REPORT.md`. The claim
holds as stated. Three corrections and one addition.

**The module's own comment is wrong about what differs.**
`RolloutNoRestart.tla:41` says "THE ONE DIFFERENCE: step is UNCHANGED." `Init`
differs too: `step = 1` at `RolloutNoRestart.tla:36` against `step = Idle` at
`Rollout.tla:74`. That second difference is what produces this trace, since the
rollout has to be open at revision 0 for `Advance` to walk past app 1 before the
commit lands.

**The conclusion survives the faithful init and gets stronger.** I built the
variant with `step = Idle` and no restart, which is `Rollout.tla`'s own opening
and the issue's repro start ("Let both apps reach Synced/Healthy at rev N"):

```
Error: Invariant NoSilentDivergence is violated.
State 1: <Initial predicate>   step = 4
State 2: <Commit ...>          target = 1  step = 4
2 states generated, 2 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 2.
rc=12
```

Red at depth 2 with two states. At `Idle` both `Advance` and `SyncApp` are
disabled, so a commit can never roll anything at all. No-restart is broken a
fortiori.

**The claim is conditional on a second silence the spike never crossed with the
first.** `REPORT.md:199` asks "One step pointer or one per app?" and takes one
global pointer. Under a per-app record there is no monotone pointer to be past,
so "no restart" is not well-formed and the stranding argument does not run. The
two silences interact and `REPORT.md` treats them independently.

**And the source is not silent.** `REPORT.md:161` says "Nothing in the issue
says." True of the issue, false of the fix PR, which the spike cites for the
`ComparedTo` pair and evidently did not read for this. PR #29418
("Fixes #29410") resets each app on a change:

```go
if revisionsChanged || specChanged {
    ...
    // App has changed to waiting because the TargetRevisions changed
    // or it is a new selected app
```

A new target revision puts every affected app back to `Waiting`, which is a
per-app restart. So the spike's chosen reading is **attested**, not merely the
only coherent one, and its own hedge at `REPORT.md:175` can be upgraded. The
restart happens per app rather than by resetting a global pointer, which also
settles the second silence in the same direction.

### Does the statement let a learner reach it?

**No, and it does not need to. The statement forecloses the question rather than
assuming no restart.**

Rule 2 makes the amendment singular: "Head office issues the amendment once, and
nothing follows it" (`PROBLEM.md:73`). Rule 8 opens with no district in hand, and
rule 2 has her open the circulation by taking district 1 in hand once the
amendment is current. So the pointer starts before district 1 at the moment the
amendment lands, which is exactly the restart semantics, and with one amendment
there is no later commit to strand anybody. The spike's second-best moment is
absent, and it is absent by construction rather than by an assumption smuggled
in.

The cost is the spike's other recommendation. At one amendment the board's
revision field and a plain "visited since the amendment landed" bit are the same
model. `REPORT.md:336`: the revision comparison "degenerates to a freshness bit
and the revision comparison is indistinguishable from a 'refreshed since the
commit' flag". The statement sits at that setting.

One thing in the statement's favour, and it is worth recording because it is not
obvious. Rule 6 forbids the cheap freshness bit: "Between his visits the line
stands as last written, however the box has moved since" (`PROBLEM.md:118`), so
nothing but a visit writes a line, and nothing of hers makes him move
(`PROBLEM.md:121`). She therefore cannot maintain a "visited since" marker of
her own, because she cannot observe a visit. The line has to carry the
amendment. **The shape of the fix is forced even at one amendment.** What is not
forced is the understanding, which is the spike's own worry: a learner can get
the right answer with the wrong idea.

**Recommendation: do not adopt the spike's two-commit change.** A second
amendment reopens the restart question that rule 2 closes, and the statement
would then have to say what happens to a district already signed off when a
second amendment lands. That is a second problem, not a harder setting of this
one. Spend the budget on the blocking finding instead. `INFERRED` for the claim
that a second amendment needs new rules rather than just a larger constant.

---

## Q2. Rule 7's reading of the current amendment is not leakage

Rule 7: "Her own records she reads freely: which amendment is current, which
district is in hand, which boxes she has out, and which districts she has signed
off. Past those, the board is everything she has" (`PROBLEM.md:129-131`).

**Ruling: not leakage.** Four reasons.

**It names an operand, not the comparison.** The guard needs two values: the
current amendment, and what the board says the box was found working to. Rule 7
gives the first. The second is explicitly withheld, in the open-choices section:
"Rule 6 says a line records what the clerk found. It doesn't say what 'what he
found' comprises." The withheld half is where the defect lives, and the
statement says so in the same breath: "settling them is the work of this
problem."

**It is faithful.** The issue's Expected paragraph has the controller knowing its
own target revision as a premise of the fix, not as the fix: "compare app's
synced revision with the AppSet's current target revision before marking a step
done." A controller that cannot read its own target revision is not the system in
the issue, and PR #29418 builds `desiredComparedTo` from the AppSet's own desired
spec.

**Withholding it makes the problem unsolvable.** An unsolvable problem is a worse
defect than a hint, and the author is right that there is no third option.

**The statement avoids the sentences that would be leakage.** It never says the
board line records which amendment the clerk compared against, and it never uses
the word compare. Rule 6's "however the box has moved since" states the
mechanism, which the source also states plainly ("Step 1's app was still
reporting Synced/Healthy from before the commit"), and without it there is no
problem to pose.

The enumeration is also right at its edges. All four records are controller-side
state and none is a box's. `working` is not in the list. The anti-vacuity note
beside the interface is the right shape too: "`signedOff` is a fact her sign-off
step sets, not a reading of `working`. Derive it from `working` and requirement 1
comes out true by construction."

**The leak is in rule 4, not rule 7.** Q2 pointed at the wrong sentence. Rule 7's
first line is "She never sees into a box", and rule 4 then gives her a per-box
flag that the box itself clears when it finishes. See the verdict.

---

## Q3. The mid-cohort fork, the warning, and the second completion route

### The warning does not carry that weight, and it does not have to

The warning (`PROBLEM.md:284-291`): "Watch the second one, because I suspect it's
where a model shrinks without the author noticing. The tighter you tie the
clerk's round to her steps, the fewer runs you've checked. All seven can then
stay green over a region that no longer exists... Forbid a step the rules allow,
and every check stays green over a region nobody runs."

It is good prose and it names the hazard exactly. It is also advice, and this
project's own convention is gate-don't-advise: a correctness invariant must never
depend on human memory. So as "the only thing stopping a reader closing the fork
the degenerate way" it is the wrong instrument.

Two things make that less serious than the author feared.

**Rule 6 has already closed most of the fork.** "The round is the clerk's own. He
takes boxes in whatever order he likes, nothing in the circulation waits on him,
and no step of hers makes him move" (`PROBLEM.md:120-121`). That is a rule, not a
hint, and it forbids coupling a visit to her steps. The open-choices section then
says the statement "doesn't fix whether the clerk can look at a box while a
district is in hand", which is a narrower freedom than it sounds. The statement
disagrees with itself about how open the fork is, in the safe direction.

**The fully degenerate closure is caught by a red run.** Confine visits to
between circulations and no visit lands after a box pastes, so the board never
goes fresh, she can never sign off on board evidence, and requirement 7 fails.
That is a gate. **But it bites only if the board is load-bearing.** In the
boardless model requirement 7 is green with no clerk in the module at all, so the
rule 4 hole disarms the one real gate the statement has. Fix rule 4 and the
warning drops to being a hint, which is the right status for it. `INFERRED` for
the between-circulations case, which I reasoned rather than ran.

**The sentence that would carry the weight is not a warning.** It is an
instruction to watch a test fail, which is this project's own discipline:

> Before you fix anything, write the guard that reads the board's verdict and
> ignores which amendment it was reached against, and watch requirement 1 go red
> with a trace. If it does not go red, your superintendent is learning a box's
> state by some route other than the board, and the problem has gone out of your
> model.

That one sentence gates the fork and the boardless model together.

### The spike overstates what the fork buys, and its own trace says so

`REPORT.md:157` and `Rollout.tla:114` both claim the mid-cohort choice "is what
makes the inversion reachable at all." Measured:

```
$ tlc -deadlock -cleanup -noTE -config MCBrokenInversion.cfg MCBrokenInversion.tla
Error: Invariant NoStepInversion is violated.
State 1: <Initial predicate>  live = <<0,0,0>> target = 0 step = 4 obsSynced = <<TRUE,TRUE,TRUE>>
State 2: <Commit ...>         target = 1  step = 1
State 3: <Advance ...>        step = 2
State 4: <SyncApp(2) ...>     live = <<0,1,0>>
12 states generated, 9 distinct states found. Depth 4. rc=12
```

**No `Refresh` step appears.** The stale verdict comes from `Init`, where every
app is Synced at revision 0 and the commit then moves the target. The inversion
is reachable with the refresh loop never firing once.

The claim is true only under the strongest closure, a mandatory synchronous
refresh of every app at each cohort boundary, and false under the weaker one,
refreshes confined to moments when no sync is in flight. `REPORT.md` does not
distinguish them, and the probe `NoMidCohortRefresh` witnesses that mid-cohort
refreshes occur rather than that the defect needs them.

The statement is in the same position and better off for it. Rule 8 makes the
opening board agree with every box, and rule 2 then makes the amendment current,
so every line is a stale verdict at the opening with no visit needed. **The
defect is reachable however the learner closes the fork.** That makes the fork a
modelling-discipline lesson here rather than the load-bearing choice the spike
makes it, and it is the main place where the two halves disagree about the shape
of the problem.

### The second completion route: no, not before freeze

**The statement has closed it rather than left it open.** Requirement 1 demands
every box of a signed-off district works to the amendment, and rule 3 gives a box
exactly one way to get there, by pasting. There is no confirmed-unchanged route
to get wrong, so nothing is silently missing.

The spike's suspicion is correct and sharper than it knew. `REPORT.md:196`
guesses that this is "where PR #29418's `SpecsEquivalent` work went". The diff
confirms the name and puts the hard part exactly there:

> SpecsEquivalent sees the live and desired apps as equivalent. The freshness
> check must then use the live app's normalized spec (targetRevision=v1.0.0)
> against ComparedTo (which also records v1.0.0), so statusIsFresh=true and the
> app advances to Healthy. Without the fix, the raw desired spec (v2.0.0) would
> not match ComparedTo (v1.0.0), leaving the app permanently stuck in Waiting.

So the unchanged route produces its own permanent stranding, caused by the
revision comparison itself. That independently corroborates the spike's
necessary-and-not-sufficient headline, through a mechanism the spike did not
model and from the source rather than from a modelling choice.

It is still a sequel and not an amendment. Covering it would force requirement 1
to become "works to the amendment, or was confirmed unaffected", and "confirmed
unaffected" needs a second oracle carrying its own normalization rules. That is a
whole second problem, and three of PR #29418's four changed files are its tests.
File it as the follow-on candidate and leave rule 3 as it stands.

---

## Q4. The gap, and the vacuity lesson

### What the Checking section should say

The author's reason for omitting a state count is right about an exact count and
throws away the part that generalizes. A learner's state count depends on the
board. **The depth of the first counterexample does not**, because it is a count
of acts by named parties, and neither does the order of magnitude. Four changes.

**1. Add the completion probe that is missing.** The statement checks one
direction, that the model can still produce a run where head office never
issues. The complement is unchecked, and the spike's own channel names it
(`REPORT.md:225`): "`NeverCompletes` against the fixed model is the one that
defends its rc 0: a completion predicate that could never be satisfied would make
every obligation hold for free, and that's one clause away at all times." Say:
check that your model can produce a run in which the amendment is issued and the
last district is signed off. Without it, a model that can never open a
circulation or never finish one passes all seven.

**2. Quote a depth band and an order of magnitude, not a count.** The spike's
rows convert: inversion at depth 4, divergence at depth 5, the fixed model at
depth 11 with 37 distinct states, all under half a second at three apps. My
boardless model of the statement's own region ran to depth 11 with 14 distinct
states. Suggested wording: expect tens to a few hundred distinct states and
seconds rather than minutes, and expect a wrong first attempt to break
requirement 1 in roughly three to six steps. A twenty-step counterexample, or
tens of thousands of states, means your board is carrying more than a line per
box.

**3. Require the red run.** The sentence from Q3. This is the highest-value
addition in the report, because it also gates the boardless model.

**4. The `.cfg` as written does not parse on this build.** Measured:

```
$ tlc -deadlock -cleanup -noTE -config ZZBoardless.cfg ZZBoardless.tla
Error: TLC threw an unexpected exception.
tlc2.tool.ConfigFileException: TLC found an error in the configuration file at line 5
It was expecting = or <-, but did not find it.
rc=255
```

Line 5 was the `Districts` assignment lifted verbatim from `PROBLEM.md`, a
two-element sequence of sets. Line 4, the `Boxes` set of three model values,
parsed fine, so it is the sequence and not the set of model values. The statement
hedges this the wrong way round at `PROBLEM.md:310`: "I think TLC takes that
shape in a `.cfg` without complaint. If yours balks, declare the two sets as
separate constants and build the sequence in your module." It always balks. The
fallback works and I used it for every run above. Promote the fallback to the
shipped `.cfg` and drop the hedge, or a learner's first ten minutes go on a parse
error the statement told them not to expect.

On `traces/`: the depth band in change 2 is the cheap substitute, and a shipped
trace would be a trace of the author's board, which is the same objection the
author raised against the state count. I would not ship one.

### Requirement 7's vacuity is genuinely fixed, and I watched both halves

Same module, same constants, fairness on her issuing removed so that a run exists
in which box b1 is never got out:

| property | wording | rc | result |
|---|---|---|---|
| `Req7` | "ends up working to it, and stays there" | 13 | violated |
| `Req7Original` | "every box eventually works to the amendment" | 0 | no error |

The author's diagnosis is exact. P is "every box works to the amendment". At the
opening the amendment is the standing edition `0` and every box works to `0`, so
P holds in the initial state and `<>P` is true of every run whatever follows.
`<>[]P` is false in the run where the amendment is issued and a box never gets
it, and true in the run where nothing is ever issued, which is what rule 9 wants
("a circulation that never opens breaks no rule here").

Two notes. The final wording names the shape in prose rather than in symbols,
which is right for this problem, and the clause "Read it that way and not as 'at
some moment it holds', which the opening state already satisfies"
(`PROBLEM.md:246-247`) does the whole job. Keep it verbatim. And the residual
vacuity is not in requirement 7 at all. It is change 1 above, because `<>[]P` is
also green over a model that can never open a circulation.

---

## Not asked about

**`NoStrandedApp` has an escape hatch that leaves it weak away from the top
revision.** `Props.tla:61-63` makes `CanStillConverge(a)` a disjunction of
"another commit could still land" and "the step pointer has not passed a's
cohort". The first arm says a stranded app is acceptable while `target < MaxRev`,
so the invariant has teeth only at `target = MaxRev`. `REPORT.md` flags the
over-approximation and calls it the safe direction, which is right for a
violation found and wrong for a green run: `MCFixed3Rev2` runs at `MaxRev = 2`,
where the hatch is open over most of the space. If the reference ships this
invariant, say so where it is defined.

**Two authors behind a wall reached the same encoding for the same stated
reason.** The statement: `inHand` "reads 0 before the circulation opens, k while
district k is in hand, and `Len(Districts) + 1` once the last district is signed
off. Numbering it that way keeps every field a number or a set of numbers, so no
comparison in a requirement meets a string sitting beside a natural." The spike,
`Rollout.tla:26-27`: "NO `none` MARKER. Revisions and cohort indices are naturals
throughout, so there is no model value beside an integer and no cross-type
comparison for TLC to abort on." Same hazard, same fix, independently. Worth
recording as the pipeline working.

**Requirements 1 and 2 together are the source's headline, decomposed.** The
issue reports one thing, "Progressive ordering (canary-before-prod) silently
inverted". The statement splits it into "a sign-off says what it means" and "no
box moves ahead of its turn", each separately named and separately declared,
which is what `.claude/rules/tla-practice.md` section 1 says published specs do
and what gives TLC a label to report. The spike's `NoStepInversion` is the single
conjoined form. The statement's decomposition is the better one and the reference
should follow it.

**Two difficulty claims already exist and neither is mine.** The spike says level
3 at the upper edge and marks it candidate-selection only. The statement says
"Plan on 25 to 45 minutes if you've read the learntla core chapters". Both were
written before any measurement. Whoever writes `VECTOR.md` should know they are
there and that this report neither endorses nor replaces them.

**Nothing here depends on the `spike-measure.sh` variable-count bug** filed as
`tla-83lg`. Every run above called `tlc` directly.
