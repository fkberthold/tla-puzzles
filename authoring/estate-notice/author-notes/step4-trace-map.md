# estate-notice step 4, the author-only trace map

Never ships to a learner or to a blind agent. It maps each pair under
`authoring/estate-notice/statement/traces/` to the frozen reference obligation
it witnesses, with the provenance of both halves. Bead `tla-h2cg.13`, rung 7 of
batch 2, shape A.

The learner-visible artifact set is exactly `statement/PROBLEM.md` and the eight
files under `statement/traces/`. No model ships, so there's no learner copy of
the spec. Nothing in this file or under `reports/` is reachable from that set.

## The map

Pair N witnesses requirement N of the statement, in the statement's own
numbering, which is `DESCRIPTION.md` section 2's numbering unchanged.

| pair | obligation | variant | rc | violating trace | satisfying half |
|---|---|---|---|---|---|
| 1 | `SheDistributesOnlyWhenClear` | S01 | 12 | 4 states | W1, rc=12, 5 states |
| 2 | `ClaimsStartWithTheCreditor` | S03 | 13 | 3 states | W2, rc=12, 4 states |
| 3 | `ALodgedClaimEndsInHerDecision` | S05 | 13 | 3 states | W3, rc=12, 3 states |
| 4 | `ADecisionStands` | S06 | 13 | 4 states | W4, rc=12, 4 states |
| 5 | `TheNoticeNeverReopens` | S07 | 13 | 3 states | W5, rc=12, 3 states |
| 6 | `TheDistributionIsNeverUndone` | S08 | 13 | 4 states | W6, rc=12, 4 states |
| 7 | `TheEstateIsEventuallyDistributed` | S10 | 13 | 6 states, then stuttering | W7, rc=12, 6 states |
| 8 | `SheTakesOneClaimAtATime` | S19 | 13 | 4 states | W8, rc=12, 5 states |

`TypeOK` gets no pair. It's the reference author's own typing, declared in the
cfg, and it was never one of the eight stated requirements.

## Provenance, violating halves

The picks are the step 2 report's section 6 table, plus the section 2b row for
`SheTakesOneClaimAtATime`. Nothing under `reports/step2-variants/` was edited.

Every variant was copied to a scratch tree with `SheTakesOneClaimAtATime`
spliced in above the module's closing line, and the repaired reference cfg was
copied in beside it. The frozen modules don't define that operator, and the
repaired cfg names it, so TLC would answer with a config error rather than a
verdict. That's the same route section 2b took, for the same reason. The
scratch tree is deleted.

Each ran through `harness/verdict.sh -t 300 -- -workers 1` with the counterexample
kept. All eight came back on the rc and the obligation section 2b's table
records, and no run reported an obligation I wasn't expecting.

One difference in the count, and it's arithmetic rather than a different trace.
Step 2 records S10 at 7 states. My run prints six states and then `State 7:
Stuttering`, so the seventh is the stutter and not a sixth step. The pair-7 file
renders the six states and says under the last one that nothing more ever
happens, which is the honest reading of either count.

## Provenance, satisfying halves

Each satisfying half mirrors its violating twin: the same opening, the same
creditors moving, and the lawful outcome where the twin has the unlawful one.
Pair 3's twin sends a lodged claim back to `"none"`, so the mirror sends it to
`"rejected"`. Pair 8's twin settles both creditors in one act, so the mirror
settles them one at a time.

Then machine-validated against the frozen reference by a trace-forcing scratch
module, `W1` to `W8`. Each forces the exact state sequence, conjoins `Init` at
the opening and `Next` on every step, and carries an invariant that's false only
once the whole sequence has been walked. So rc=12 means the run is a real
behaviour of the reference, and rc=0 means some step of it isn't a `Next` step.
Eight of eight came back rc=12 at the full length.

The validator can fail. A control trace, `WC`, sends a creditor straight from
`"none"` to `"paid"` in one step, and comes back rc=0 with no counterexample at
all. Without that control the eight passes would only say the module compiled.

Traces render the three `Observe` fields and nothing else. No action name, no
formula, no obligation name, and the variants' own action names (`Withdraw`,
`Reopen`, `Clawback`, `DecideTwo`) never appear.

## The withheld subscript, and why requirement 4 carries it

Form left open 1 wants one action property's subscript in the learner's hands.
Five of the six get their subscript named in the statement. Requirement 4 is the
one left open.

The pick comes from step 2's finding 4, which measured the wrong-subscript
escape three ways and found that two of the three don't actually escape.
`ClaimsStartWithTheCreditor` and `TheNoticeNeverReopens` both go blind under a
wrong subscript, and their system variants get caught anyway, by
`SheDistributesOnlyWhenClear` sitting earlier in the search. That's incidental
coverage, and a learner who gets the subscript wrong there still passes.
`ADecisionStands` subscripted on `distributed` misses S06 outright at rc=0, with
all 77 states explored and nothing else catching it.

So requirement 4 is the one place on this problem where the subscript decision
is graded by the property it belongs to. Withholding it anywhere else withholds
a decision the cfg doesn't measure.

## A correction to `DESCRIPTION.md` section 5

Section 5 says the withheld subscript sits on item 7. Item 7 is
`TheEstateIsEventuallyDistributed`, which is `<>` over a state predicate and has
no subscript. So that sentence names a form that doesn't exist, and following it
would leave form at 0 with a sentence claiming otherwise. `VECTOR.md` carries the
same correction beside the form row.

The point section 5 was reaching for still stands, and the statement carries it
somewhere else. Its real worry is the blanket-fairness shortcut, which step 2's
finding 5 confirmed passes. That's a fairness decision rather than a subscript,
so the statement handles it in the requirement 7 section: the four named
conjuncts, one at a time, and the reason `WF` over the whole next-state relation
doesn't mean what Rule 9 means.

## Notes for step 5 and the grader

- Requirement 4's subscript is the one deliberate hole. A learner who subscripts
  it on the standings alone still catches S06, so a wrong-but-not-blind answer
  is possible here and shouldn't be marked the same as a blind one.
- Requirement 7 has three ways to be wrong and only one of them is the formula.
  Dropping any single fairness conjunct breaks it, blanket fairness passes it
  for the wrong reason, and step 2's finding 3 records a learner who deletes an
  action while keeping its fairness conjunct passing everything at rc=0.
- The statement gives 77 distinct states under the narrowest state shape, and
  says larger counts aren't wrong by themselves. Don't grade on the number.
- Pair 6's forbidden run breaks requirement 6 and nothing else, which is what
  S08 measured. Pair 1's breaks requirement 1 in a single state.
