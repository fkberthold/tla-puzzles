# bonded-store step 4 — author-only trace map

Never ships to a learner or a blind agent. It maps each pair under
`authoring/bonded-store/statement/traces/` to the frozen reference
obligation it witnesses, with the provenance of both halves. Bead
`tla-h2cg.7`.

The learner-visible artifact set is exactly `statement/PROBLEM.md`,
`statement/BondedStore.tla`, and the four files under `statement/traces/`.
Nothing in this file or in `reports/` is reachable from those.

## The map

| pair | obligation | violating half | rc | trace | satisfying half |
|---|---|---|---|---|---|
| 1 | `DutyMatchesPlace` | S02, release without payment | 12 | 3 states | T1, rc=12 |
| 2 | `MovementIsLawful`, the way in | S04, straight to released | 13 | 2 states | T2, rc=12 |
| 3 | `MovementIsLawful`, the two ways out | S06, back to not entered | 13 | 3 states | T3, rc=12 |
| 4 | `LeavingIsFinal` | S11, released lot moved on | 13 | 4 states | T4, rc=12 |

`TypeOK` has no pair on purpose. It's the model's own typing, and the
description says in as many words that it isn't a requirement handed to the
learner. Shape B grades the learner's property set against the stated rules.

## Four pairs for three obligations, and why

The brief asked for one pair per obligation, which is three. I shipped four,
and I'd rather argue it than let a reader find the mismatch.

`MovementIsLawful` is one operator carrying two arms, and the step 2 report
hands the statement author a separate violating trace for each of them
(`reports/step2-variants.md:547-548`). The arms fail differently. S04 skips
the store on the way in, S06 erases the store's account on the way out, and
no single run breaks both. A learner who writes only the way-in arm passes
a three-pair set with half a property. The pairs are the learner's own
oracle, so I'd rather they carry both arms than be tidy.

The cost is that the pair count no longer reads as the property count. At
form 0 that costs nothing, because the statement names three requirements
outright and says requirement 2 has two arms and two pairs
(`statement/PROBLEM.md:113-119,148-149`). qsl needed the pair count as the
oracle for how many properties to write. This rung doesn't.

## Provenance, violating halves

The step 2 variant modules are committed under `reports/step2-variants/`, so
each violating half is the shipped variant re-run rather than a recreation.
The FREEZE check ran first, both files matching by hash. Each variant ran
through `harness/verdict.sh -t 300` with its own committed `.cfg`, which is a
byte copy of the reference's. All four returned the rc, the obligation and the
trace length the step 2 results table records
(`reports/step2-variants.md:521-549`, table rows S02, S04, S06, S11).

Traces render over the `Observe` fields only, states only. Action names,
formulas and obligation names were stripped by hand, and the four place
values are written in the rules' English rather than in the module's own
strings. That last one is deliberate. `PROBLEM.md:100-101` tells the learner
to read the module for what it calls each of the four, so printing the raw
strings in a trace would hand back the one rendering step the traces can
reach.

## Provenance, satisfying halves

Hand-designed so each mirrors its violating twin, then machine-validated
against the STRIPPED learner spec rather than the reference, so the shipped
artifact is the thing the runs are behaviors of. The validator is a scratch
module that forces the exact state sequence, conjoins the learner spec's
`Init` on the opening state and its `Next` on every step, and carries an
invariant that fails only at the last forced state. rc=12 means the whole run
was walked. rc=0 means some step isn't a `Next` step, or the opening isn't
`Init`.

Four of four came back rc=12, at 3, 2, 3 and 4 states, matching the state
count each pair prints. A deliberately illegal control (a lot going from not
entered straight to released, T0) came back rc=0, so the validator can fail
and the four passes mean something.

## Notes for step 5 and the grader

- Pair 4's forbidden run breaks `LeavingIsFinal` alone. The moved-on lot ends
  with its duty unpaid, which the biconditional in `DutyMatchesPlace` is happy
  with, and both arms of `MovementIsLawful` guard on a lot still in or before
  the store. That's step 2 finding 2 and finding 3 used on purpose: item 4's
  trace breaks the place half rather than the duty half, so a learner who
  wrote only requirement 1 isn't made to look wrong.
- Pairs 2 and 3 both route to `MovementIsLawful`. A learner who writes the two
  arms as two separate properties is right, and so is one who writes them as
  one. The statement asks for one property, so a grader comparing counts
  should read the arms, not the line count.
- The wrong-subscript warning in `PROBLEM.md`'s requirement 2 is the interface
  fix for step 2 finding 4, where P01 and P02 subscript on `Observe.dutyPaid`
  and both go blind on the system variant their correct form catches. Form 0
  means the statement gives the subscript outright, so this rung closes the
  trap rather than measuring it.
