# Step 6 — the panel, and the spread read on the argument

## The panel

| seat | model | attempts | distinct states | representation |
|---|---|---|---|---|
| p1 | claude-fable-5 | 1 | 102,460 | swaps set, custodian derived |
| p2 | claude-opus-5 | 1 | 102,460 | swaps set, custodian derived; two guards deliberately omitted so the properties carry them |
| p3 | claude-haiku-4-5 | 1 | 96,445 | explicit custodian variable plus an internal agreedSwaps set |

One instance each, 2026-08-08, isolated directories holding the thirteen learner
files. Reports in the panel directories and the session transcript.

## Verdict: GREEN

The two strong seats converged on byte-equivalent behavior at the reference's
own count, from independent derivations, with discriminating instruments under
every conclusion. p3 diverged (96,445 distinct, three properties "verified by
construction" rather than checked) and the divergence reads as solver depth,
not statement ambiguity: the seats that instrumented their readings agree
exactly.

## The finding that matters — p2 rediscovered V12 blind

p2 measured that the ten properties alone do not pin the model: a no-op-swap
rendering (custody ignores the agreed swaps) passes all ten at the identical
state count. That is the step-2 matrix's V12, found independently with no
access to it, which is about the strongest corroboration a variant matrix can
get. p2 then showed the closure the statement itself carries: the published
satisfying trace does not replay against the no-op model (stalls at the first
swapped row). Properties prohibit; the trace pair obliges. The §5.3 probes
committed at 2b (cap reachability, both flip directions) are the grading-side
form of the same closure, and p2's R2/R3 probes reproduce them almost exactly.

**Consequence for grading, on the record:** the learner's model must be run
against the trace-admission check, not only the property set. The statement
already frames full-window.md as "your model must allow it"; the grader treats
that as a gate, per the step-5 precondition and tla-dk7w.

## Instruments, split per rule 1

- p1: eleven single-target mutants (all red on the named property), three
  expected-red vacuity checks, 24-state exact containment of the published
  behavior, one honestly-unmechanized bijection argument.
- p2: eleven mutants (11/11, counterexample shapes checked against the trace
  files), the no-op control, a replay negative control proving the replay
  itself can fail, eleven reachability probes, five spare arrangements
  including cap-zero and one-day windows.
- p3: green run plus assertions; several conclusions carried no instrument.
  Its 96,445-state model was never reconciled against the published trace by
  its own checks, and its report does not notice the count difference. Depth
  diverging across families where content converges, third panel running.

## Notes

- p2's timing flag (40 s against the statement's minutes budget) resolves
  benignly: the count matches to the digit and the budget line stays, since
  over-budgeting is harmless and the reference run with liveness on a loaded
  box measured slower.
- Recall probes: no published-problem recognition; mechanism namings (OCC/CAS
  race, bounded reservation; contract formation) are generic and arrived
  without shortcutting the boundary details.
- Rule 6: p3 was not first-try clean in substance (its model diverges), so the
  every-solver flag does not fire; the easy-end telemetry of the strong seats
  carries to §7.5 as with the other panels.

**Step 6 closes GREEN.** Statement stands. Step 7 next.
