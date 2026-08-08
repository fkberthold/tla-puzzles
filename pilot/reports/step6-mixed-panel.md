# Step 6, re-run with a mixed-model panel

The first step-6 run used three instances of one model and returned byte-identical answers. That
was read as "the problem is trivial". It could equally have been "three samples from one
distribution is not three opinions", and the §6 spread rule cannot tell those apart.

So the run was repeated against the **same frozen artifacts**, the **same brief verbatim**, with
only the model varying. Inputs verified byte-identical by md5 against the original critic
directories.

Panel: 3 x Opus (E1-E3, the original run), 2 x Fable (F1, F2), 1 x Sonnet (S1).

## Result

| | E1 | E2 | E3 | F1 | F2 | S1 |
|---|---|---|---|---|---|---|
| model | Opus | Opus | Opus | Fable | Fable | Sonnet |
| gap 1 found | yes | yes | yes | yes | yes | yes |
| conjunct content | same | same | same | same | same | same |
| **primary form** | invariant | invariant | invariant | **action** | invariant | invariant |
| route | rule vs guard | rule vs guard | rule vs guard | rule vs guard | rule vs guard | rule vs guard |
| said so unprompted | yes | yes | yes | yes | yes | yes |
| gap 2 found | yes | yes | yes | yes | yes | yes |
| **gap 2 argued** | proved | proved | proved | proved | proved | **not proved** |
| recognized 2PC | yes | yes | yes | yes | yes | yes |
| noticed at | Rule 3 | Rule 3, pre-spec | Rule 3, pre-spec | Rules 3-4, pre-spec | Rule 3, pre-spec | **Rule 4** |
| attempts | 1 | 1 | 1 | 1 | 1 | 1 |
| minutes | ~15 | ~25 | ~15 | ~15 | ~25 | ~25-30 |

## What this settles

**The triviality finding holds, and is now much stronger.** Six critics across three model
families, same gap, same conjunct content, one attempt each, all six volunteering that they found
it by comparing a rule against a guard rather than by reasoning about behaviour. That is not one
model's blind spot. §3.2 obliges the statement to state the system completely, so a critique
answer is a diff, and every model finds a diff.

**The mechanism burn is model-independent.** 6/6 named two-phase commit, five of them at Rule 3
and four before opening the spec. The §5.7 screen's verdict on this domain was right across
families.

**The hypothesis that low spread was a panel artifact was mostly wrong.** Central proposed this
re-run expecting the panel to be implicated. On content it was not.

## What it found that the single-model panel could not

**1. The discriminating spread is in the RIGOR of the negative argument, not in the answer.**

Every critic reached the same conclusion about gap 2: the amendment rule cannot be expressed over
the observation operator. Five built an instrument and proved it — refinement under a mapping with
a negative control; a projected state-graph diff against a second correct spec at a different
representation; a stuttering simulation with exhaustive `Observe` state and edge enumeration; a
trace-inclusion disjunction over every observable step a correct spec can take.

One did not. S1 constructed a single candidate encoding, found it vacuous on the given spec,
and reported honestly: *"reasonably confident it can't be done"* rather than proving it, flagging
the gap in its own rigor unprompted.

**That is the spread the §6 rule is looking for, and the rule as written cannot see it.** Same
answer, same conclusion, materially different depth of justification. It is invisible to "did they
find the gap" and it is exactly what a column-C problem should be grading.

**2. One critic in six submitted a form the grader would reject for its shape.**

F1 handed in the action form as primary and explicitly demoted the invariant, on the grounds that
the invariant presumes post-issuance positions stay represented as approvals, which Rule 7 does not
strictly promise. Content identical to the other five. A grader pinned to rc=12 rejects it, because
an action-property violation exits 13 (bead `tla-94n`).

The other Fable instance chose the invariant, so this is within-model variance rather than a clean
model effect, and n is too small to separate them. But 1 in 6 is enough to matter across 60
problems, and a three-instance single-model panel returned 0 in 3.

## Consequences

- The panel composition should be recorded with every difficulty verdict, the way a recall probe
  records its model id and date. A verdict from one model family is a verdict about that family.
- Mixed panels are worth the cost, but for a different reason than proposed: not because content
  diverges, but because **depth of justification does**, and depth is what column C measures.
- The rc=12 pin in the answer-form check is confirmed as a live defect against a real submission,
  not a hypothetical. See `tla-nyrb`.

## Method note

The inputs were identical and the brief was identical; only the model varied. The original three
runs were not repeated, so the Opus column is the earlier run rather than a fresh sample, and
run-to-run variance within Opus is unmeasured. Six critics, three families, one problem, one day.
