# assay-office step 4, author-only trace map

Never ships to a learner or a blind agent. It maps each pair under
`authoring/assay-office/statement/traces/` to the frozen reference obligation
it witnesses, with the provenance of both halves. Bead `tla-h2cg.10`.

The learner-visible artifact set is exactly `statement/PROBLEM.md`,
`statement/AssayOffice.tla`, and the three files under `statement/traces/`.
Nothing in this file or in `reports/` is reachable from those.

## The map

| pair | obligation | violating half | rc | trace | satisfying half |
|---|---|---|---|---|---|
| 1 | `MarksFollowTheFinding` | S12, every ware struck with no finding | 12 | initial state | T1, 3 states, rc=12 |
| 2 | `TheRecordOnlyGrows` | S04, a finding rewritten | 13 | 3 states | T2, 3 states, rc=12 |
| 3 | `SubstandardIsDefaced` | P03, the fairness conjunct dropped | 13 | 6 states then stuttering | T3, 4 states, rc=12 |

`TypeOK` has no pair on purpose. Step 2 finding 3 records that nothing in the
22-variant matrix reached it, so it has no violating half to ship. The
description says in as many words that the type invariant is the reference
author's and is never a requirement the learner writes.

## Three pairs for three requirements

The three picks are the step 2 report's own, from its section 6 table. I took
all three unchanged and I want to say why for the two that had a named
alternative.

S12 breaks at the initial state, so the forbidden run is one state long. The
report offers S01 at 2 states, which shows the strike happening. I kept S12.
Requirement 1 is a state predicate, and a one-state forbidden run is the
cleanest thing the pair set can say about what a state predicate rejects. The
shape hint it carries, a one-state run meaning "wrong start", is residue the
pairs cannot avoid and shouldn't try to.

P03 runs six real states and then stutters. The report offers S09 at the same
length with the fairness narrowed rather than dropped, and S10 as a 10-state
lasso. I kept P03. The four states after the substandard finding are the
office testing and striking the other two wares, which is the point: the
office is working the whole time and never gets round to w1. A lasso would
read as a different fault, and this rung's liveness is the halt.

## Provenance, violating halves

The step 2 variant modules are committed under `reports/step2-variants/`, so
each violating half is the shipped variant re-run rather than a recreation.
The FREEZE check ran first, both files matching by hash. Each variant ran
through `harness/verdict.sh -t 300` with its own committed `.cfg` and
`-workers 1`. All three returned the rc, the obligation and the trace length
the step 2 results table records (`reports/step2-variants.md:253,261` for S04
and S12, `:287` for P03).

Traces render over the `Observe` fields only, states only. Action names,
formulas and obligation names were stripped by hand. The three findings print
as "not tested", "at standard" and "substandard" rather than in the module's
own names, and the two flags print as struck or unmarked and defaced or whole.
That's deliberate. `PROBLEM.md` tells the learner to read the module for what
it calls the three findings, so printing the raw strings in a trace would hand
back the one lookup the traces can reach.

## Provenance, satisfying halves

Hand-designed so each mirrors its violating twin, then machine-validated
against the STRIPPED learner spec rather than the reference, so the shipped
artifact is the thing the runs are behaviors of. The validator is a scratch
module that forces the exact state sequence, conjoins the learner spec's
`Init` on the opening state and its `Next` on every step, and carries an
invariant that fails only at the last forced state. rc=12 means the whole run
was walked. rc=0 means some step isn't a `Next` step, or the opening isn't
`Init`.

Three of three came back rc=12, at 3, 3 and 4 states, matching the state count
each pair prints. A deliberately illegal control (a ware struck in one step
from the opening, with no finding written) came back rc=0, so the validator
can fail and the three passes mean something.

## Notes for step 5 and the grader

- Pair 1's forbidden run breaks requirement 1 alone. Every ware starts struck
  with no finding, so nothing has moved yet and neither the growth rule nor
  the discharge rule has anything to say about it.
- Pair 2's forbidden run breaks requirement 2 alone. w1's finding goes from at
  standard to substandard, which requirement 1 is happy with at every state,
  and w1 is never marked or defaced.
- Pair 3's forbidden run breaks requirement 3 alone, and only through what
  happens after state 6. A learner who reads the six states as a finite run
  and stops will find nothing wrong with them, which is why the trace file
  spells the tail out under the block.
- The wrong-subscript warning in requirement 2 is the interface fix for step 2
  finding 5, where P01 and P02 subscript on one `Observe` field and both go
  blind on the system variant their correct form catches. Step 2 records that
  neither escape is rescued by another obligation here, which is where this
  differs from qsl. Form 0 gives the subscript outright, so this rung closes
  the trap rather than measuring it.
- A learner who declares `SPECIFICATION Spec` instead of `FairSpec` gets rc=13
  on requirement 3 with a correct formula. `PROBLEM.md` says so in the
  requirement itself. A grader seeing that failure should read the cfg's
  specification line before reading the formula.
