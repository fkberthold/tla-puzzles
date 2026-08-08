# qsl step 4 — author-only trace map

Never ships to a learner or a blind agent. It maps each pair under
`authoring/qsl/statement/traces/` to the frozen reference obligation it
witnesses, with the provenance of both halves. Bead `tla-kstb`.

The learner-visible artifact set is exactly: `statement/PROBLEM.md`,
`statement/Bureau.tla`, and the nine files under `statement/traces/`.
Nothing in this file or in `reports/` is reachable from those.

## The map

| pair | obligation | violating half | rc | trace | satisfying half |
|---|---|---|---|---|---|
| 1 | `Opening` | S01 opening-seeded | 13 | initial state | TC1, rc=12 |
| 2 | `FilesOnlyGrow` | S02 mail-replaces | 13 | 3 states | TC2, rc=12 |
| 3 | `FilesWellFormed` | S03 mail-allows-self | 12 | 2 states | TC3, rc=12 |
| 4 | `OneEnvelopeAtATime` | S04 mail-carbon-copy | 13 | 2 states | TC4, rc=12 |
| 5 | `CreditIsCorroborated` | S19 one-sided corroboration | 12 | 3 states | TC5, rc=12 |
| 6 | `CreditIsMutual` | S06 credit-one-sided | 12 | 4 states | TC6, rc=12 |
| 7 | `CreditComesWhole` | S07 credit-batches-bands | 13 | 4 states | TC7, rc=12 |
| 8 | `CreditIsPermanent` | S09 credit-expires | 13 | 5 states | TC8, rc=12 |
| 9 | `BureauKeepsUp` | S10 fairness-dropped | 13 | 4 states + self-loop | TC9, rc=12 |

`TypeOK` has no pair on purpose. It's the model's own typing, not a stated
rule, and shape B grades the learner's property set against the rules.

## Provenance, violating halves

Step 2's variant modules weren't committed, so the nine were recreated
from the frozen matrix text in `reports/step2-variants.md` section 1. Each
recreation is a verified single-mutation diff against the frozen reference
(FREEZE check ran first, both files OK). Each ran through
`harness/verdict.sh -t 300` with the reference `.cfg` unchanged, tracing
via `-dumpTrace json`, and all nine came back with the rc and the reported
obligation step 2's results table records.

One difference to know about: my S10 counterexample is 4 states ending in
a self-loop where step 2 recorded 5 states then stuttering. Same failure,
different enumeration, presumably because a recreated CarbonCopy-class
disjunct or envelope order enumerates differently than agent B's exact
text. The pair-9 rendering carries the self-loop as "nothing ever
changes", which is the honest reading of either trace.

Traces render over `Observe` fields only, states only. Action names,
formulas, and obligation names were stripped by the renderer, and the
variant action names (`Expire`, `CarbonCopy`) never appear.

## Provenance, satisfying halves

Hand-designed so each mirrors its violating twin (same envelopes or the
same target state, reached lawfully), then machine-validated against the
STRIPPED learner spec, not the reference, so the shipped artifact is the
thing the runs are behaviors of. The validator forces the exact state
sequence and conjoins `Next` on every step: rc=12 means the full run was
walked, rc=0 means some step is not a `Next` step. Nine of nine came back
rc=12. A deliberately illegal control trace (credit with no claims on
file) came back rc=0, so the validator can fail and the nine passes mean
something.

## Notes for step 5 and the grader

- Pair 8's forbidden run breaks `CreditIsPermanent` and `CreditComesWhole`
  both, and no run can break permanence alone (step 2, finding 2). The
  statement's traces section licenses rejecting a run for any rule it
  breaks. Don't mark a learner wrong for covering pair 8 with their
  whole-credit step rule, and don't mark permanence-as-its-own-property
  wrong either.
- Pair 5 uses S19, not S05: credit on one operator's word is the mistake a
  person makes. S13 routes to `CreditIsCorroborated`, not `CreditIsMutual`
  (step 2, finding 4), so pair 6 uses S06.
- The statement names no property count. The pair count is the oracle, per
  the B row of §2.1.
- The wrong-subscript warning in `PROBLEM.md`'s interface section is the
  §3.3 interface-fixing for step 2's finding 7. A learner's step rule
  subscripted on one `Observe` field goes blind exactly as measured there.
