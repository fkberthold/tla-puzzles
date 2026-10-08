# Spike: a rollout step marked complete against stale status

Built 2026-10-08 against TLC2 Version 2026.07.31.184830 (`tlc` with no arguments,
line 1). Source: `argoproj/argo-cd#29410`, OPEN, plus the surveyor's extract at
`sources/rollout.md:178-215`. Every row below came from `harness/spike-measure.sh`.
Raw rows are in `measurements.tsv`.

Two headlines. The problem is small, and both reported failures land in a
five-variable model inside half a second. And the fix the issue proposes is
necessary but not sufficient on its own: with the revision comparison in place
and nothing else changed, a single commit still strands a cohort permanently.
That second one is the finding I'd build the problem around.

## How big it is

Five variables, 37 distinct states for the correct system, 21 for the broken one.
No state constraint, no symmetry set, no view, no fairness. The `vars`, `fairness`
and `temporal` columns below read the module text rather than the run, which is
what `harness/spike-measure.sh` documents them as.

| label | module | rc | verdict | secs | distinct | depth | vars |
|---|---|---|---|---|---|---|---|
| broken-2cohort | MCBroken2 | 12 | invariant violated | 0.4 | 3 | 3 | 5 |
| fixed-2cohort | MCFixed2 | 0 | checked, no violation | 0.4 | 17 | 8 | 5 |
| broken-3cohort-all-four | MCBroken3 | 12 | invariant violated | 0.4 | 3 | 3 | 5 |
| broken-3cohort-inversion-only | MCBrokenInversion | 12 | invariant violated | 0.3 | 9 | 4 | 5 |
| broken-3cohort-divergence-only | MCBrokenDivergence | 12 | invariant violated | 0.3 | 21 | 5 | 5 |
| broken-3cohort-stranded-only | MCBrokenStranded | 12 | invariant violated | 0.3 | 3 | 3 | 5 |
| fixed-3cohort | MCFixed3 | 0 | checked, no violation | 0.3 | 37 | 11 | 5 |
| fixed-4cohort | MCFixed4 | 0 | checked, no violation | 0.3 | 77 | 14 | 5 |
| fixed-5cohort | MCFixed5 | 0 | checked, no violation | 0.3 | 157 | 17 | 5 |
| fixed-6cohort | MCFixed6 | 0 | checked, no violation | 0.3 | 317 | 20 | 5 |
| fixed-3cohort-2commits | MCFixed3Rev2 | 0 | checked, no violation | 0.3 | 314 | 18 | 5 |
| norestart-fixed-1commit | MCNoRestartFixed1 | 12 | invariant violated | 0.3 | 8 | 3 | 5 |
| norestart-fixed-2commits | MCNoRestartFixed | 12 | invariant violated | 0.4 | 9 | 3 | 5 |
| inflight-broken-3cohort | MCInflightBroken | 12 | invariant violated | 0.3 | 3 | 3 | 7 |
| inflight-fixed-3cohort | MCInflightFixed | 0 | checked, no violation | 0.3 | 65 | 14 | 7 |
| dead-action-control | DeadSyncProbe | 0 | checked, no violation | 0.3 | 33 | 8 | 5 |

Every run finished in under half a second on one worker. Nothing here needs a
budget.

**The headline row is `fixed-3cohort`: 5 variables, 37 distinct states, depth 11,
0.3 seconds.** The broken pair's numbers are smaller and they're smaller for a
boring reason, so don't read them as difficulty. TLC stops at the first violation,
and `NoStrandedApp` fires at depth 3, which truncates the search before anything
else happens. The per-obligation rows exist so each failure has its own trace.

The variable count is a fact about my modelling choices, not about the problem.
Over the 143 systems in `corpus/manifest.tsv` the variable-count medians by level
run 3, 2, 6, 7, 8, levels 1 and 2 come out inverted, and level 1 alone spans 1 to
87 variables (`harness/spike-measure.sh:6-12`). I got 5 and the seven-variable
framing below got the same verdicts, which is one more instance of the same point.

## The modelling decision the whole thing turns on

I modelled the application, not the mechanism. Nothing in `Rollout.tla` is a
reconciliation loop, a manifest renderer, a health assessor, a work queue or a
resource hook. The mechanism that matters is three sentences.

1. An app's published status is a copy of its real state, taken earlier by a
   refresh loop.
2. The controller's step-completion predicate reads the copy.
3. While the controller owns an app, only the controller can make it converge.

That third one is how "progressive sync turns automated sync off" gets into the
model. `SyncApp` is the only action that moves `live`, and it's guarded by the
app's cohort being the step currently rolling. So an app the step pointer has
walked past has nothing left that could sync it, and that's failure 2 with no
extra machinery.

The five variables:

| variable | what it is |
|---|---|
| `target` | the revision being rolled out |
| `step` | the step the controller is on, `Idle` when done |
| `live[a]` | the revision app `a` has actually applied |
| `obsRev[a]` | the revision `a`'s published status compared against |
| `obsSynced[a]` | whether that comparison came back Synced |

`(obsRev, obsSynced)` is Argo CD's `status.sync.comparedTo` and
`status.sync.status`, which is the pair PR #29418 compares. The defect is one
clause in one predicate:

```tla
StepComplete(s) ==
    \A a \in Apps :
        Cohort(a) = s =>
            /\ obsSynced[a]
            /\ (Strict => obsRev[a] = target)
```

`obsSynced[a]` on its own says "this app reports Synced", and says nothing about
which revision that verdict was reached against. One constant switches the two
systems, which is what keeps the broken and fixed runs comparable.

Revisions and cohort indices are naturals throughout, so there's no model value
sitting beside an integer and no cross-type comparison for TLC to abort on.

## The two failures

### Failure 1: the ordering inversion

`MCBrokenInversion`, rc 12, 9 distinct states, depth 4. Cohort 2 rolls while
cohort 1 is still on the old revision.

```
State 1: Init          live=<<0,0,0>>  target=0  step=4  obsSynced=<<T,T,T>>  obsRev=<<0,0,0>>
State 2: Commit        target=1  step=1         \* the commit touches every cohort
State 3: Advance       step=2                   \* step 1 "complete" on a pre-commit verdict
State 4: SyncApp(2)    live=<<0,1,0>>           \* cohort 2 rolls, cohort 1 never did
```

That's `prod-cohort apps rolled first` with the names taken off. At three cohorts
the same model reaches cohort 3 the same way, so the reported canary-before-prod
ordering is in there too.

### Failure 2: silent permanent divergence

Two separate claims, so two obligations and two traces.

`MCBrokenDivergence`, rc 12, 21 distinct states, depth 5, is the reporting half.
The controller reaches `Idle` with every app still on revision 0.

```
State 2: Commit        target=1  step=1
State 3: Advance       step=2
State 4: Advance       step=3
State 5: Advance       step=4                   \* Idle. Rollout complete, nothing synced.
```

`MCBrokenStranded`, rc 12, 3 distinct states, depth 3, is the permanence half, and
it fires one action earlier. Once `step` passes an app's cohort, `SyncApp` for
that app is dead, and `Advance` only ever increments. So the app sits out of sync
with nothing scheduled to fix it, which is the issue's own wording.

I wrote the permanence as an enabledness invariant rather than a liveness
property, so it needs no fairness:

```tla
CanStillConverge(a) == target < MaxRev \/ step <= Cohort(a)
NoStrandedApp == \A a \in Apps : (live[a] # target) => CanStillConverge(a)
```

It enumerates the two routes by which `live[a]` can move again. The enumeration
over-approximates reachability, which is the safe direction here: a violation is a
real violation, and the invariant is just weaker than the tightest statement.

## Where the source is silent, and what I chose

Six places. The second one changed my view of the problem.

**Can a refresh land mid-cohort?** The issue names the window ("the window is the
app-status refresh interval") and never says whether a refresh is confined between
cohorts. I let `Refresh(a)` fire in any state where it would change something, so
it can land part way through a step. That choice is what makes the inversion
reachable at all. The `NoMidCohortRefresh` probe is the witness that it happens in
the state space rather than only in the module text.

**Does a new commit restart the rollout from step 1?** Nothing in the issue says.
I chose restart (`Commit` sets `step' = 1`), and I built the other choice as
`RolloutNoRestart.tla` to see what it costs. It's red with a single commit, 8
distinct states, depth 3:

```
State 1: Init          live=<<0,0,0>>  target=0  step=1
State 2: Advance       step=2                   \* nothing to do at revision 0
State 3: Commit        target=1  step=2         \* app 1's step has already gone by
```

So without the restart, any commit that lands after the step pointer has moved
past a cohort permanently strands that cohort, and the revision comparison doesn't
help. I think that settles the silence rather than leaving it open: restart is the
only reading under which progressive sync can roll anything at all. It also means
the issue's proposed fix is necessary and not sufficient, and I'd want the problem
to make a learner meet that.

**The concurrency cap.** `maxUpdate: 1` on the last step is in the issue's repro
and it isn't causal. I left it out, with one app per cohort, which makes a cap of
1 inert by construction. A cohort of two apps under a cap would need a count of
in-flight syncs, and I'd expect that to add an axis without adding a defect.
`INFERRED` for the expectation, since I didn't build it.

**Is the health channel stale too?** The issue says the app was "still reporting
Synced/Healthy", which reads as both channels being stale. My primary model makes
a sync atomic, so only the revision channel can be stale. `RolloutInflight.tla` is
the literal reading, with `busy` and `obsBusy` added. See the edges below.

**Apps whose manifests didn't change.** The rule quotes "synced (or been confirmed
unchanged) at the revision being rolled out". I never modelled the
confirmed-unchanged route. Every commit in my model touches every cohort, which is
the issue's own scenario ("a commit changed a template value affecting all
cohorts"). An app that needed no change would want `live[a] = target` without a
`SyncApp`, and that's a second completion route the fix has to get right. It's
also where PR #29418's `SpecsEquivalent` work went, so I suspect it's the harder
half of the real fix.

**One step pointer or one per app?** The issue mentions per-app records in
`status.applicationStatus`. I used a single global `step`, which assumes the
controller holds one position for the whole AppSet. That's the smaller model and
I think it's the right one for this failure, since the inversion is between
cohorts rather than inside one.

## What a passing run means here

Three of the sixteen models exit 0, and an invariant guarded by a condition that
never holds also exits 0. So 16 probes, each denying something the model had
better be able to do, plus four controls. `bash run-probes.sh` reproduces the
table, and the verdict in every row is the exit code.

| probe | broken rc | fixed rc | what a 0 would have meant |
|---|---|---|---|
| `NeverCommits` | 12 | 12 | nothing ever moves |
| `NeverSyncs` | 12 | 12 | no app ever converges |
| `NeverAdvances` | 12 | 12 | there's no second step to order |
| `NeverCompletes` | 12 | 12 | the rollout can never finish |
| `NeverStale` | 12 | 12 | the stale window doesn't exist |
| `NoMidCohortRefresh` | 12 | 12 | refreshes only land between cohorts |
| `NeverAllConverged` | 12 | 12 | the broken system can only fail |
| `NeverObservedOutOfSync` | 12 | 12 | `obsSynced` is a constant |

Expected 12 in all 16 cells and got 12 in all 16.

Two of those carry more weight than the rest. `NeverCompletes` against the fixed
model is the one that defends its rc 0: a completion predicate that could never be
satisfied would make every obligation hold for free, and that's one clause away at
all times. `NeverAllConverged` against the broken model says the happy path is
still reachable there, so the defect is a race on the refresh interval and not an
inevitability. A model where the rollout could only ever fail would overstate the
issue.

Sixteen 12s is also what a probe channel stuck at 12 looks like, so four control
rows:

| control | config | expected | rc |
|---|---|---|---|
| `LiveNeverRunsAhead` | broken | 0 | 0 |
| `LiveNeverRunsAhead` | fixed | 0 | 0 |
| `StepPrefixConverged` | broken | 12 | 12 |
| `StepPrefixConverged` | fixed | 0 | 0 |

`StepPrefixConverged` is the useful one. Same operator text, 12 on the broken
model and 0 on the fixed one, with one constant between them. That's the channel
discriminating rather than reporting.

`harness/vacuity.sh` covers the mechanical vectors, driven by `run-vacuity.sh`:

| model | rc | token | what ran |
|---|---|---|---|
| `MCFixed3` | 0 | `NON_VACUOUS` | space, configured check, satisfiability, all four actions |
| `MCBroken3` | 0 | `NON_VACUOUS` | space and configured check only |
| `DeadSyncProbe` | 5 | `VACUOUS_DEAD_ACTION` | named `SyncApp`, 0 total, guard never true |

Two things worth saying about that table. On `MCBroken3` the satisfiability and
dead-action probes didn't run, because the model violates its invariant, so
"every action fired" is not established there. And the dead-action probe has been
watched failing: `DeadSyncProbe.tla` is the same system with `SyncApp`'s guard
changed to `target > MaxRev`, and `vacuity.sh` named the action, the line and the
guard, having evaluated it 99 times without it ever being true. A dead-action
probe that's never fired isn't evidence about the models where it says nothing is
wrong.

## The seeded-bug matrix

Seven variants, each the reference module with one hunk changed. The mutation is
`matrix/seed-variants.sh` rather than seven hand-typed copies, and the script
refuses to finish if any variant comes out byte-identical to the reference.
`matrix/reference/Rollout.tla` is byte-identical to the primary model, which `cmp`
reports.

| variant | the one change |
|---|---|
| `drop-revision-check` | completion reads health alone. The reported defect. |
| `no-completion-check` | `Advance` stops consulting the predicate |
| `sync-any-cohort` | `SyncApp` stops checking the app's cohort |
| `off-by-one-cohort` | completion reads the previous cohort |
| `refresh-always-synced` | the refresh loop publishes Synced regardless |
| `skip-a-step` | `Advance` increments by two |
| `commit-overshoots` | a commit jumps two revisions, past the bound |

Both halves of the obligation held in both runs: rc 0 against the reference, and
the oracle caught all seven in phase 3, so no variant in the set is inert.

I graded two submissions, and the first one is here to be failed.

| submission | obligations | rc | token | caught |
|---|---|---|---|---|
| `SubmissionNoTypeOK` | 3 domain invariants | 40 | `PROPERTY_TOO_WEAK` | 6 of 7 |
| `Submission` | those 3 plus `TypeOK` | 0 | `BUGS_CAUGHT` | 7 of 7 |

The missed variant is `commit-overshoots`, and the reason is worth keeping. A
commit that jumps two revisions still rolls out in cohort order, still reaches
every app, and still leaves nobody behind. All three domain invariants hold. Only
the type invariant notices that `target` left `0..MaxRev`. So the obligation set
this problem ships needs `TypeOK` in it, and I'd have guessed otherwise before
running the matrix.

One trace divergence survives the green run, on `refresh-always-synced`. The
oracle fires at `Commit -> Refresh`, three steps, and the shipped set fires at
`Commit -> Refresh -> Advance`, four. That's expected rather than a problem: the
oracle carries an extra conjunct about the refresh loop itself, which is violated
as soon as a lying status is published, while the shipped set only notices once a
step advances on it. The harness computes trace agreement on every run and only
fails on it under `--strict-trace`.

The caveat `harness/seeded-bugs.sh` puts on itself applies here in full. These are
mutants of my own reference, about 10.9% of real faulty specs are one mutation from
correct, and about 39.3% of single mutations are semantically inert. So 7 of 7
means the shipped obligation set catches these seven. It says nothing about what a
learner would actually write.

## The edges

**Scaling in cohorts.** The correct system, one commit:

| cohorts | distinct | ratio to previous | depth |
|---|---|---|---|
| 2 | 17 | | 8 |
| 3 | 37 | 2.18 | 11 |
| 4 | 77 | 2.08 | 14 |
| 5 | 157 | 2.04 | 17 |
| 6 | 317 | 2.02 | 20 |

Each cohort roughly doubles the space and adds exactly three to the depth. The
depth is a derivation: a cohort costs one `SyncApp`, one `Refresh` and one
`Advance`. The doubling is a fit over five points, and `5 * 2^n - 3` reproduces
all five exactly. I wouldn't read anything into the closed form past the range
measured. Doubling is much flatter than three functions over `n` apps would
suggest, and I think the reason is that the ordering keeps most of the product
unreachable.

**Two commits.** `MCFixed3Rev2` goes from 37 to 314 states at rc 0, so the second
revision costs about 8.5x. It also does real work rather than just costing: at
`MaxRev = 1`, `obsRev` only ever holds 0 or 1, so `obsRev[a] = target` degenerates
to a freshness bit and the revision comparison is indistinguishable from a
"refreshed since the commit" flag. At `MaxRev = 2` it isn't. If the problem wants
a learner to find the revision comparison rather than a boolean, I'd set it at two
commits and pay the 8.5x.

**The second staleness channel.** `RolloutInflight.tla` adds `busy` and `obsBusy`
and splits a sync into begin and finish, which is the literal reading of "still
reporting Synced/Healthy". Seven variables, and the fixed side goes from 37 states
to 65, about 1.76x. Same verdicts, same obligation set, no new defect.

It does buy one thing, and it's smaller than I expected. The inversion
counterexample fires at `BeginSync(2)` rather than at a completed sync, so the
model can say "a later cohort is mid-sync while an earlier one is untouched",
which the atomic model can't express. Same 9 distinct states and same depth 4
getting there. My call is that the atomic five-variable model is the one to set,
and the in-flight version is worth building afterwards for the same reason the
fencing spike's clockless model was: deleting a channel teaches something to
somebody who already paid for it.

## Discrepancies

**`harness/spike-measure.sh` counts comment words in a commented `VARIABLES`
block.** My first measured row read 36 variables for a module declaring 5, because
each declaration line carried a `(* ... *)` note. Isolated in
`probe-vars-comment/`, two modules declaring the same two variables:

```
$ bash harness/spike-measure.sh --dir .../probe-vars-comment --module VarsCommented
vars-commented  VarsCommented  0  checked, no violation  0.4  ...  8  ...
$ bash harness/spike-measure.sh --dir .../probe-vars-comment --module VarsPlain
vars-plain      VarsPlain      0  checked, no violation  0.4  ...  2  ...
```

8 against 2. The six extra are the identifier-shaped words inside the two
comments. The cause is in the `nvars` awk: `strip()` removes `\*` line comments
and leaves `(* *)` alone, so the `tally()` regex matches ordinary English. This is
a different hole from the one the fencing spike reported, which was `VARIABLES`
alone on its line and has since been fixed. The gate at
`harness/test-spike-measure.sh` doesn't catch it, and I didn't fix it, since my
brief scoped me to this directory. I moved my own comments above the block
instead, so the rows in this report read 5.

**The worktree-isolation harness refused two command lines I expected to work.**
`bash harness/vacuity.sh -c <cfg> -n <n> --expect-actions ... <module>` came back
as too complex to verify, which `harness/spike-measure.sh --dir ...` did not.
`run-vacuity.sh` is the workaround and it's the same one the `--alias` hazard
already documents. Worth adding `vacuity.sh` to that hazard's list in
`.claude/rules/dispatched-agents.md`, which isn't a file I'm allowed to edit.

**`tlc -inv <Operator>` reports the operator's own name on this build.** V2-PLAN
section 5.3 says the injected invariant is auto-named `__DebuggerExpr__<nanotime>`
and to never pattern-match it. TLC 2026.07.31.184830 printed
`Error: Invariant NeverStale is violated.` I read verdicts from exit codes, so
nothing here depends on it, and the advice not to match the name still stands. The
note just isn't describing this build's output.

## Difficulty: level 3, and this is candidate-selection only

**Not a placement.** Placement comes from the load vector after the reference is
frozen. This is one spike author's read, for deciding whether the candidate is
worth building.

By `PRACTICE-PLAN.md:257-261`, level 2 is one function as state and level 3 is
several functions or rules relating entities. `Rollout.tla` has three functions
over `Apps` plus two scalars, with the controller's step pointer related to
per-app status. That's level 3, and I'd put it at the upper edge rather than the
lower one, because the hard part is noticing that the completion predicate reads a
copy.

It doesn't reach level 4. Nothing here is nested, there are no records, there's no
refinement mapping, and progress doesn't matter: both failures are state
invariants and no model in the set declares `WF_` or `SF_`. The one change that
would push it to 4 is stating failure 2 as `<>[]` under fairness instead of as the
enabledness invariant, and I don't think that's worth the fairness argument.

## Re-running the numbers

From this directory:

```bash
bash measure.sh                   # every row, into measurements.tsv
bash run-probes.sh                # the 20 vacuity probe rows
bash run-vacuity.sh               # harness/vacuity.sh over three models
cd matrix && bash seed-variants.sh && bash run-matrix.sh
```

Each script resolves the repo root from `BASH_SOURCE` rather than a literal path,
so they're safe to run from a worktree.

## Files

- `Rollout.tla`, the system, five variables, no invariant. Doubles as the matrix
  reference.
- `Props.tla`, the four obligations.
- `Probes.tla`, eight vacuity probes and two controls.
- `MC*.tla` with matching `.cfg`, 13 wrapper modules carrying one config each.
- `RolloutNoRestart.tla`, the other answer to the restart silence.
- `RolloutInflight.tla`, the seven-variable framing with both channels stale.
- `DeadSyncProbe.tla`, a dead `SyncApp` so the dead-action probe can be watched
  failing.
- `probe-vars-comment/`, the `spike-measure.sh` variable-count isolation.
- `matrix/`, the seeded-bug matrix: reference, oracle, two submissions, seven
  variants, and the two scripts that drive them.
- `measurements.tsv`, all 16 rows.

## Verdict

**Good candidate, and I'd build it.** The whole reported incident fits in five
variables and 37 states, both failures have traces under depth 6, and the system
is the target learner's own: per-cluster cohorts, an ordered rollout of one
commit, a concurrency cap, and a member that silently stays behind.

**Three things I'd change about how it's set.**

The restart has to be part of the exercise. A learner who writes the revision
comparison and stops gets a green run on a model that still strands a cohort as
soon as the commit lands after the step pointer moved. That's the second-best
moment in the problem and it's one `UNCHANGED` away.

Set it at two commits, not one. At `MaxRev = 1` the revision comparison and a
"has this been refreshed yet" boolean are the same model, so a learner can get the
right answer with the wrong idea. The 8.5x costs 0.3 seconds.

Keep the type invariant in the shipped obligation set and say why. The matrix
found exactly one variant that only `TypeOK` catches, and I'd have cut `TypeOK` as
boilerplate without that run.

**One caution on all of this.** I built one model well and measured it, and the
claim I'm least sure of is the one about the in-flight framing buying nothing. It
found no new defect against my seven variants and my four obligations, which is
not the same as there being nothing to find. If the problem ever grows a cohort of
more than one app, I'd expect the in-flight window to matter and I'd re-run that
comparison rather than carry this result forward.
