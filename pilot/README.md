# The Stage 3 pilot — one problem through all eight steps

Bead `tla-kl5.11`. Run 2026-08-07. Grid cell **(S5, C)**: lifecycle state machines, critique task
shape, gap #11. Domain is municipal permit review with parallel department sign-offs.

The pilot exists to find breakages on one problem rather than forty (§6). It found eighteen. The
problem itself is a by-product, and it is **not cleared to ship** — see below.

## What is here

| path | what it is |
|---|---|
| `reference/PermitReview.tla` | the frozen reference. PlusCal, no comments |
| `reference/PermitReview.cfg` | its config, harness-owned |
| `reference/FREEZE.sha256` | the step-3 hashes. Still verify |
| `reference/PermitReview.commented.tla` | the step-7 comment pass, gated byte-identical modulo comments |
| `reference/alternatives.md` | the author's representations considered and rejected. Stale in two places, noted in `reports/agent-f.md` |
| `statement/` | what a learner receives: the problem and the deficient spec |
| `ANSWER-KEY.md` | the delta between complete and deficient. **Not for a learner** |
| `screens.md` | the author's §5.7b answers and the §5.7 verdict. **Not for a learner** |
| `reports/` | the verification record, and the research artifact |

`ANSWER-KEY.md` and `screens.md` sit at the top level on purpose, outside `statement/`. During the
run they lived beside the statement, and the leakage pass caught that a step-6 brief pointing at
the directory would have handed three blind critics the answers. Keep them apart.

## The eight steps, as run

| # | step | outcome |
|---|---|---|
| 1 | reference written cold | rc=0, 842 generated, 220 distinct, diameter 8 |
| 2 | verification | **FAILED.** Eleven adversarial variants, five uncaught |
| 2b | repair | one action property added, caught count 6 to 8. Not in §6, and that is a finding |
| 3 | freeze and hash | recorded in `reference/FREEZE.sha256` |
| 4 | statement plus deficient spec | two gaps seeded, one gradable |
| 5 | leakage check | fit to ship, after a delivery-boundary fix |
| 6 | blind critique times three | **FAILED the spread rule.** See `reports/step6-spread.md` |
| 7 | comment pass | 372 comment lines, no other change |
| 8 | strip-and-diff | PASS via `harness/comment-gate.sh`, both checks |

Three variants remain uncatchable and each has a named structural cause rather than a defect in
this spec: one because the observation operator exposes no amendment count, two because a
submission's own operator can misreport. Beads `tla-59s` and `tla-x8s`.

## Why this problem does not ship

Two reasons, either sufficient.

**The §5.7 mechanism screen returns BURNED.** `harness/screen.sh` maps this domain to atomic
commitment and two-phase commit, five specs in `tlaplus/Examples`. The mapping is authored, not
inferred from phrasing. All three blind critics named two-phase commit unprompted, two of them
before opening the spec. The screen was right, and it was run at step 4 rather than before step 1,
which is bead `tla-stdl`.

**Gap location is trivial here, and I think that is structural to column C.** All three critics
found both gaps in seconds by reading a rule against the guard that implements it. §3.2 obliges
the statement to state the system completely, so a critique answer is a diff between complete
prose and incomplete formalism, and there is nowhere for the gap to hide. Bead
`tla-kl5.11`'s successor work carries the redesign.

## The part worth keeping

All three critics spent most of their time proving that the second gap **cannot be stated over the
observation operator at all**, and reached that by three different instruments. That is the
modeling judgment column C should be asking for, and the pilot found it by accident rather than by
design.
