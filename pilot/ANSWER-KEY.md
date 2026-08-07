# Answer key: PermitReview critique problem

**Never show this to a critic.** It carries the seeded gaps, the expected conjuncts, and
the measurements behind both.

Toolchain for every run below: `TLC2 Version 2026.07.31.184830 (rev: 30cc360)` and
`pcal.trans Version 1.12 of 01 July 2024`. `$P` is the pilot directory and `$H` is
`/home/frank/repos/tla-puzzles/harness`. Every verdict is `verdict.sh`'s raw exit code.
Nothing here reads TLC's prose for a verdict.

## The delta at a glance

Two gaps, seeded on purpose. No third.

| | gap | shape | gradable |
|---|---|---|---|
| 1 | unanimity is not required at issuance | state predicate over `Observe` | yes |
| 2 | an amendment does not clear recorded positions | transition property | **no** |

The deficient spec is green against its own `.cfg` at rc=0, so a critic cannot find
either gap by running TLC. `bash $H/verdict.sh -c $P/statement/PermitReview.cfg
$P/statement/PermitReview.tla` gives token `OK`, rc=0. It reaches 292 distinct states
against the reference's 220.

## Gap 1, primary: unanimity

**What the process requires.** Rule 3 of `PROBLEM.md`. The city can issue only when every
department is holding an approval at that moment.

**What the deficient spec says instead.** The city's guard is `Pending /\ ApprovedBy # {}`,
so one approval is enough. `PermitReview.tla:59` in the PlusCal, `PermitReview.tla:99`
in the translation. The `Unanimous` operator and the `IssuedOnlyWhenUnanimous` invariant
are both deleted, in the module and in the `.cfg`.

**Why they were deleted rather than left unchecked.** A defined-but-unlisted operator
named `IssuedOnlyWhenUnanimous` sitting in the module would name the gap outright. An
author who forgot unanimity would not have written the operator. Same reasoning for
`Unanimous`, which the weakened guard no longer uses.

**Expected conjunct.**

```tla
Observe.issued => (Observe.approvedBy = Departments)
```

**Two-sided check.** Driven by `$P/statement/.verify/twosided.sh`, which builds a
`Check.tla` extending each side's `PermitReview` and a one-check `.cfg` per candidate.

| candidate | deficient | frozen | verdict |
|---|---|---|---|
| `G1_Canonical` | `SAFETY_VIOLATION` rc=12 | `OK` rc=0 | accept |
| `G1_Cardinality` | `SAFETY_VIOLATION` rc=12 | `OK` rc=0 | accept |
| `G1_WeakOneDept` | `SAFETY_VIOLATION` rc=12 | `OK` rc=0 | **reject, see below** |

`G1_Cardinality` is `Cardinality(Observe.approvedBy) = Cardinality(Departments)` under the
same antecedent. It's the same claim in another phrasing and it grades the same.

**Counterexample TLC produced against the deficient spec**, from
`.verify/logs/deficient-G1_Canonical.log`. Three states: initial, `Reviewer("planning")`
records an approval, `City` issues. That's the seeded witness and not a side effect, and
it matches the `3 steps: Reviewer, City` signature agent B recorded for `v01`.

### The degenerate answer to watch for

`Observe.issued => ("fire" \in Observe.approvedBy)` passes the two-sided check at 12 and 0.
It names one department out of three and says nothing about unanimity. The mechanical
check cannot tell it from the real answer.

`PROBLEM.md` disqualifies it in prose, under "The vocabulary your answers are written in":
conjuncts have to hold for any `Departments` and any amendment bound. That's a
human-graded line, not a mechanical one. **If step 5 grades this problem by exit code
alone, this family gets in.** I'd treat a department-naming answer as a partial credit and
flag it rather than score it.

## Gap 2, secondary: the amendment rule. Seeded, and not gradable

**What the process requires.** Rule 5 of `PROBLEM.md`. An amendment throws away every
position recorded against the old version.

**What the deficient spec says instead.** The amend branch increments the counter and
does nothing else. The clearing assignment is gone, and the translator hoists
`UNCHANGED position` across both branches of the applicant's `either`.
`PermitReview.tla:45-48` in the PlusCal, `PermitReview.tla:97` in the translation.
`AmendmentClearsApprovals` is deleted from the module and the `.cfg`.

**It is identifiable by reading.** The amend action visibly bumps a counter and touches
nothing else. A critic comparing rule 5 against that action should see it.

**It is not expressible in the required answer form.** Two independent reasons, and both
are measured rather than argued.

### Reason 1: no state predicate can separate the amendment weakening from the reference

I built a gap-2-only spec at `.verify/g2only/` (the frozen reference with only the
clearing assignment removed, re-translated by pcal), dumped every reachable state from it
and from the frozen reference with `-dump`, and compared them as **sets of whole records**
rather than line-wise. Agent B's report records that a line-wise comparison reports every
variant identical, including ones that are not, so the record-set comparison is the one to
trust.

```
frozen    distinct records: 220
g2only    distinct records: 220
g2only == frozen (as SETS): True
  g2only \ frozen: 0
  frozen \ g2only: 0
```

The two reachable state sets are equal. A state predicate is a function of the state, so
**no state predicate whatever** separates them, over `Observe` or over the raw variables.
This is stronger than agent B's count-only claim for `v02`, which showed 220 on both sides
without showing the sets matched.

### Reason 2: `Observe` exposes no amendment count

The faithful statement of rule 5 needs to detect that an amendment happened.

```tla
[][ (amendments' # amendments) => (Observe'.approvedBy = {}) ]_vars
```

That reads `amendments`, a spec-internal variable, so it's outside the answer form
`PROBLEM.md` requires. Measured as `G2_Faithful`: deficient `LIVENESS_VIOLATION` rc=13,
frozen `OK` rc=0. It fails the required check on two counts. It reads a variable rather
than `Observe`, and an action property returns 13 where the check wants 12. The 13 is
central's `tla-94n` finding reproducing here, not a defect.

Its counterexample is the seeded witness: initial, `Reviewer("planning")` approves,
`Applicant` amends and the approval survives. That matches agent B's `v02` signature.

### One Observe-only separator exists, and it is not an answer

I went looking for an action property over `Observe` alone that separates the two specs,
expecting none. There is one.

```tla
[][ (Observe.approvedBy = Departments /\ ~Observe.issued /\ ~Observe.withdrawn)
      => (Observe' # Observe) ]_vars
```

Measured as `G2_ObsNoSilentStepAtUnanimity`: deficient rc=13, frozen rc=0. It works
because in the reference every non-stuttering step out of a fully-approved open state
changes something observable, and in the deficient spec an amendment is an observably
silent step.

**It is not a statement of the amendment rule.** It says a fully-approved open state
can't step silently, which is an accident of the reference's step structure rather than
anything rule 5 asserts. It would not hold of every correct spec of this process. If a
critic submits it, they found *a* separator, not gap 2. Don't score it as gap 2 without
reading their reasoning.

It also returns 13, so a grader pinned to rc=12 rejects it anyway.

### What to record in step 6

Whether the critic **names** the amendment gap, in a conjunct or in their notes. That's
the measurement. A critic who says "the amendment action doesn't clear positions, and I
can't write it over `Observe` because there's no amendment count" has found it completely,
and scores zero on a mechanical grader. Central knows: beads `tla-59s`, `tla-x8s`.

`PROBLEM.md` invites a `Notes` section so an unexpressible finding has somewhere to land.
Without it the measurement is impossible. See the leakage note in my report.

## There is no third gap

The deficient spec's reachable set is a strict superset of the reference's, by exactly 72
states, and every one of them has `issued = TRUE` with an approval set that's neither
empty nor all of `Departments`.

```
deficient distinct records: 292
deficient superset of frozen: True
  deficient \ frozen: 72
  all extra states have status=issued: True
  all extra states non-unanimous    : True
  all extra states have >=1 approval: True
```

The arithmetic agrees. 27 position vectors times 4 amendment values times 3 statuses is
324 type-correct states. The deficient spec reaches 108 open, 108 withdrawn, and the 76
issued states whose approval set is non-empty, so 292. The reference reaches only the 4
unanimous issued states, so 220.

So every state predicate over `Observe` that passes the two-sided check has to exclude at
least one of those 72 states, and each of those states is issued without unanimity. **Every
gradable answer is a weakening of gap 1.** A critic cannot stumble onto a gradable third
finding, so the step-6 spread stays clean.

## Controls

Both were measured, and both behave, so the two-sided check discriminates rather than
always saying yes.

| control | deficient | frozen | reading |
|---|---|---|---|
| `NC_NeverIssued` (`~Observe.issued`) | rc=12 | rc=12 | violated both sides, not an answer |
| `NC_Trivial` (`P \/ ~P`) | rc=0 | rc=0 | holds both sides, not an answer |

`NC_NeverIssued` is the one `PROBLEM.md` shows the learner, so the cheap way to satisfy
run 1 is named up front and closed.

## Provenance of the deficient spec

Derived from the frozen reference by five source edits, then re-translated.

1. Delete `Unanimous` from the `define` block.
2. Delete the clearing assignment from the amend branch.
3. Weaken the city's guard to `Pending /\ ApprovedBy # {}`.
4. Delete `IssuedOnlyWhenUnanimous`.
5. Delete `AmendmentClearsApprovals`.

Frozen hashes checked before any of it, and they match `frozen/FREEZE.sha256`:
`f5fbe37d…` for the `.tla` and `729790c7…` for the `.cfg`.

The TRANSLATION block moved. Before pcal it was byte-identical to the reference's at md5
`47ba2b5f2fb3c90e88e3fa1c9f138b7d`, which is the value agent A2 recorded. After pcal it's
`0dff9fcd540f19b5c03fa5d3a21eed39`. pcal is a fixed point on the result, so the shipped
translation is what pcal produces and not a hand edit.

`OutcomeIsAbsorbing`, `IssuanceIsFinal`, `WithdrawalIsFinal`, `OutcomeExclusive`, `TypeOK`
and `ObserveWellTyped` are all retained and all pass. Every action still carries the
`Pending` guard, so rules 1 and 7 are intact in the deficient spec and are not gaps.
