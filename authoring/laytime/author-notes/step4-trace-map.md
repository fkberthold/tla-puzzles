# laytime step 4, author-only trace map

Never ships to a learner or a blind agent. It maps each pair under
`authoring/laytime/statement/traces/` to the frozen reference obligation it
witnesses, with the provenance of both halves. Bead `tla-h2cg.8`, shape A.

The learner-visible artifact set is exactly `statement/PROBLEM.md` and the
three files under `statement/traces/`. Shape A ships no spec, so there is no
learner copy of the module. Nothing in this file or in `reports/` is
reachable from that set.

## The map

| pair | requirement | obligation | violating half | rc | trace | satisfying half | rc |
|---|---|---|---|---|---|---|---|
| 1 | opens once, closes once | `OpensOnceClosesOnce` | S01 reckoning-before-notice | 13 | 2 states | Walk1, 3 states | 12 |
| 2 | one period, one move | `OnePeriodOneMove` | S05 two-periods-at-once | 13 | 3 states | Walk2, 4 states | 12 |
| 3 | demurrage waits | `DemurrageWaitsForAllowance` | S11 opens-on-demurrage | 12 | initial state | Walk3, 5 states | 12 |

`TypeOK` has no pair, on purpose. It's the reference author's cfg line and
not a learner requirement (DESCRIPTION.md §2), and the step 2 report's §5
caution says the same thing: three pairs and not four.

## Provenance, violating halves

All three variants are committed under `reports/step2-variants/` and were
re-run here rather than recreated. Each went through `harness/verdict.sh
-t 120` with the variant's own cfg, which is the reference cfg verbatim.
The rc, the reported obligation and the trace length match the step 2
results table row for row (`reports/step2-variants.md:215-236`).

- S01: `LIVENESS_VIOLATION`, rc=13, `OpensOnceClosesOnce`, states 1 and 2 of
  the log, the allowance falling from 2 to 1 with the notice untendered on
  both sides.
- S05: `LIVENESS_VIOLATION`, rc=13, `OnePeriodOneMove`, three states, the
  allowance falling from 2 to 0 in one step.
- S11: `SAFETY_VIOLATION`, rc=12, `DemurrageWaitsForAllowance`, violated by
  the initial state, one period accrued against a full allowance.

Step 2 named S18 as the alternative for pair 1 and S07 as the alternative
for pair 3. I took its picks. S01 is the mistake a person makes, and a
single state is the shortest counterexample there is.

Traces render over the four `Observe` fields, states only. Action names,
formulas, obligation names and variant ids were stripped by hand.

## Provenance, satisfying halves

Each is hand-designed to mirror its violating twin, then machine-validated
against the frozen reference. Pair 1 reaches the same drawdown lawfully, by
tendering first. Pair 2 reaches the same target state in two steps instead
of one. Pair 3 reaches positive demurrage lawfully, which at `Allowance` 2
takes five states and is the shortest route there is.

The validator is a scratch module that forces the exact state sequence and
conjoins the reference's `Next` on every step, with an index variable and
`NotDone == i < Len(Trace)` as the invariant. rc=12 means the walk reached
the last row, so every step is a `Next` step. rc=0 means the walk stalled,
so some step is not one. Three of three came back rc=12.

A deliberately illegal control, the allowance dropping from 2 to 0 in one
step, came back rc=0. So the validator can fail and the three passes mean
something.

The scratch modules ran against a staged copy of the reference under a
scratch directory and were deleted before the footprint check. `reference/`
was never written to.

## Notes for step 5 and the grader

- **Set the vacuity floor at 4, not 11.** Step 2's finding 3 leaves this
  call to me and it is the one real decision in this file. The reference has
  11 reachable states, so a floor at 11 leaves no room between the real
  model and a model one state short, and every honest variation reads as a
  transcription. At 4 the diagnosis is also right rather than merely
  present: S10 comes back `VACUOUS_DEAD_ACTION` and S12
  `VACUOUS_FROZEN_OBSERVE`, where at 11 both collapse to
  `VACUOUS_EMPTY_SPACE` (`reports/step2-variants.md:249-257,344-352`). The cost is
  that a floor of 4 is a floor a transcription clears, and I'd rather pay it
  than run a probe whose only answer is "smaller than the reference".
- **No seeded bug may use Rule 8's second half.** Step 2's finding 1
  measured S14 as having the reference's exact state graph, so a bug seeded
  there grades every submission the same. The statement says the rule stands
  and that no property watches that half, in the description's own words.
- **The opening is ungraded and that's deliberate.** S10 and S12 pass all
  four obligations. A fourth must-be-true pinning the opening would be a
  fifth cfg line and would move property count out of band 1
  (DESCRIPTION.md §5). The 11-state count in the statement's checking
  section is what a learner has instead, and the vacuity layer is what a
  grader has.
- **The wrong subscript is the live failure mode.** Step 2's finding 5
  reproduced it on both action properties, rc=13 under `_Observe` and rc=0
  under a single-field subscript. Shape A gives the learner no spec to copy
  the subscript from, so the statement states it twice: once per requirement
  and once as its own paragraph with the failure mode named.
- **Pairs 2 and 3 share a prefix.** Pair 2's forbidden run and pair 3's
  allowed run both pass through the notice being tendered against a full
  allowance. That's the system's only route to a spent allowance, not a
  coupling between the requirements.
