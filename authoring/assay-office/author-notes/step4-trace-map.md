# assay-office step 4, author-only trace map

Never ships to a learner or a blind agent. It maps each pair under
`authoring/assay-office/statement/traces/` to the frozen reference obligation
it witnesses, with the provenance of both halves. Bead `tla-h2cg.10`.

The learner-visible artifact set is exactly `statement/PROBLEM.md`,
`statement/AssayOffice.tla`, and the six files under `statement/traces/`.
Nothing in this file or in `reports/` is reachable from those.

## The map

| pair | obligation | violating half | rc | trace | satisfying half |
|---|---|---|---|---|---|
| 1 | `MarksFollowTheFinding` | S12, every ware struck with no finding | 12 | initial state | T1, 3 states, rc=12 |
| 2 | `TheRecordOnlyGrows` | S04, a finding rewritten | 13 | 3 states | T2, 3 states, rc=12 |
| 3 | `SubstandardIsDefaced` | P03, the fairness conjunct dropped | 13 | 6 states then stuttering | T3, 4 states, rc=12 |
| 4 | `MarksFollowTheFinding` | S02, an at-standard ware defaced | 12 | 3 states | T4, 3 states, rc=12 |
| 5 | `TheRecordOnlyGrows` | S06, a struck ware unmarked | 13 | 4 states | T5, 4 states, rc=12 |
| 6 | `TheRecordOnlyGrows` | S07, a defaced ware made whole | 13 | 4 states | T6, 4 states, rc=12 |

Pairs 4 to 6 came later than the first three. The section below says where
from.

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

## The three added pairs

Step 5's leakage check found three clauses with no forbidden run behind them.
It filed requirement 1's `defaced` clause as D1 and requirement 2's two
monotonicity clauses as N1. Central took both. A learner could write half of
requirement 1, or a third of requirement 2, and every signal the statement
gives would say they were done.

| pair | clause it closes | what the variant does |
|---|---|---|
| 4 | requirement 1, `defaced` | defaces a ware found at standard |
| 5 | requirement 2, `marked` | clears a struck ware's mark |
| 6 | requirement 2, `defaced` | makes a defaced ware whole again |

The picks are the leakage report's own. S03 was the other candidate for pair
4 and I left it, because it strikes a substandard ware and that's the `marked`
clause pair 1 already covers. S02 is the only committed variant whose
counterexample reaches the untested half.

The mapping stops being one to one here, so `PROBLEM.md` now says so in its
trace section. Without that line I suspect a learner who found two pairs
answering to requirement 1 would read it as their own mistake.

## Provenance, violating halves

The step 2 variant modules are committed under `reports/step2-variants/`, so
each violating half is the shipped variant re-run rather than a recreation.
The FREEZE check ran first, both files matching by hash. Each variant ran
through `harness/verdict.sh -t 300` with its own committed `.cfg` and
`-workers 1`. All three returned the rc, the obligation and the trace length
the step 2 results table records (`reports/step2-variants.md:253,261` for S04
and S12, `:287` for P03).

Pairs 4 to 6 went the same way, with one change. Each ran under a cfg carrying
only the obligation it breaks, so the reported violation names the clause the
pair is for. S02 came back rc=12 on `MarksFollowTheFinding` at 3 states. S06
and S07 both came back rc=13 on `TheRecordOnlyGrows` at 4 states. Those match
`reports/step2-variants.md:251,255,256`.

Each of the three then ran again with its broken obligation dropped and the
other two left in. All three came back `OK` at rc=0, so no forbidden run in
the three new pairs breaks a requirement it wasn't picked for.

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

T4, T5 and T6 went through a rebuilt copy of the same validator, at 3, 4 and 4
states, all rc=12. The control was rebuilt with them and came back rc=0 again.
Each of the three mirrors its twin by keeping the twin's illegal move and
making it legal. T4 defaces a ware the office found substandard. T5 leaves a
mark standing while the office tests another ware. T6 does the same for a
defacing.

None of the three ends with a substandard finding still undischarged. That
isn't required, since a finite run with no tail note says nothing about
requirement 3, but the first three allowed runs all avoid it and I kept the
habit.

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
- Pair 4's forbidden run breaks requirement 1's `defaced` clause alone. w1 is
  defaced while its finding reads at standard, and no ware is ever struck.
- Pair 5's forbidden run breaks requirement 2's `marked` clause alone. w1
  loses a mark it was entitled to, so requirement 1 holds at every state.
- Pair 6's forbidden run breaks requirement 2's `defaced` clause alone. w1's
  defacing is undone at the last state, and a finite prefix says nothing
  about requirement 3.
- The `marked`-clause-only weakening of requirement 1, which step 5 filed as
  D1, now fails its hand-check against pair 4. Nothing is struck in that
  forbidden run, so the half property accepts a run the learner has to reject.
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
