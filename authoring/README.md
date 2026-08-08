# authoring/ — system descriptions, the input to §6 step 1

A system description is what a reference-solution author receives (§9.4's `<system description>`).
It is **not** the learner-facing statement, which §9.6's author writes later from the frozen spec.

**This is the answers side of the boundary.** Learners work in a separate location and never see
these — they carry the observation-operator design, the deliberate modeling forks, and the
ambiguity resolutions, all of which would hand over the abstraction choice the problem exists to
test. §2.4 and §6b.1 are the reasons; the pilot broke the same rule once and a leakage pass caught
it.

## What each one carries

Beyond the system rules themselves, each description states the things the pilot's author had to
settle silently and which then became defects four dispatches downstream:

- **The observation operator**, as fields with a stated reason for each. Central got this wrong
  twice on the pilot, first as a constant record of sets that cannot depend on state, then as an
  operator that under-exposed so a whole rule was ungradable in principle.
- **The open forks** — modeling choices deliberately left open, with the wording that keeps them
  open. Column A problems are abstraction-choice problems (§2.1), so a description that makes one
  model obviously right has destroyed the problem while looking complete.
- **The resolved ambiguities**, each with the alternative it could have been. The pilot's author
  resolved six in silence; these carry nine or ten each, declared.

## Status

Drafted 2026-08-07 by dispatched authors, from domains selected by a three-model recall probe.
**None has been adversarially reviewed yet**, and that review is a gate — see the bead that owns it.
Do not dispatch a reference author against an unreviewed description.
