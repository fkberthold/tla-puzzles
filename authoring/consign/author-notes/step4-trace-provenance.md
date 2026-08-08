# Step 4 trace provenance

Agent C, bead `tla-exm1`. Author-only. Every trace under
`statement/traces/` maps to one TLC run recorded here. Nothing in the traces
was written by hand: the tables are renderings of TLC's own state sequences,
relabeled from the model instance to the statement's names.

**The relabeling.** `i1` is Ann's lamp, `i2` is Ann's clock, `i3` is Ben's
radio, `i4` is Ben's vase. `o1` is Ann, `o2` is Ben. Same ownership split as
the frozen `MCConsign.tla`, `Floor = 2`.

**The command shape.** Every run went through the verdict channel, module
path absolute, library at `harness/`:

```
JAVA_TOOL_OPTIONS="-DTLA-Library=<worktree>/harness" \
  harness/verdict.sh -t 300 --log <dir>/run.log <abs>/MCConsign.tla
```

**The freeze.** `sha256sum -c FREEZE.sha256` in
`authoring/consign/reference/` returned OK for all three files before any of
this ran.

## Violating traces: rebuilt caught variants

Rebuilt from the frozen step-2 matrix rows by `scratch-step4/prep.py`
(scratch, uncommitted, dies with the worktree). Each replacement had to hit
exactly once or the build died. For every variant dir, `MCConsign.tla` and
`MCConsign.cfg` were checked byte-identical to the frozen ones before the
run. Where a matrix row leaves the mutation site open, the choice here is
mine and is named.

| Trace file | Matrix row | Mutation as built | Token | rc | Obligation the log names |
|---|---|---|---|---|---|
| `opening.md` | C01 | `Init` admits one item already listed | `LIVENESS_VIOLATION` | 13 | `OpeningAllUnlisted`, by the initial state |
| `standings.md` | C19 | `GoHome` writes `"mislaid"` (my site choice) | `SAFETY_VIOLATION` | 12 | `OneStandingEach` |
| `cap.md` | C02 | `Intake` drops the cardinality guard | `SAFETY_VIOLATION` | 12 | `FloorCap` |
| `path.md` | C11 | `GoHome` guard admits `"sold"` | `LIVENESS_VIOLATION` | 13 | `LawfulPath` |
| `till.md` | C14 | `Settle` settles one item per step | `LIVENESS_VIOLATION` | 13 | `SingleStepOrSettlement` |

All five tokens and rcs match the step-2 results table for their rows, which
is the corroboration that the rebuilds hit the rows they claim.

## Satisfying traces: reachability probes on the frozen reference

Scratch copies with `Consign.tla` byte-identical to the frozen module
(asserted by `prep.py`). Each probe adds one definition to the scratch
`MCConsign.tla` and one line to the scratch cfg, so the five shipped
obligations stayed configured on every run and held along every trace. S1 to
S4 assert the target state unreachable as an added `INVARIANT`, and TLC's
counterexample is the reachability witness. S5 asserts no step moves two
items, as an added `PROPERTY`, and the counterexample ends in the two-item
settlement (the same probe shape RESULTS-2B used).

| Trace file | Probe | Target | Token | rc |
|---|---|---|---|---|
| `opening.md` | S1 | lamp listed, rest unlisted | `SAFETY_VIOLATION` | 12 |
| `standings.md` | S2 | sold, listed, returned, unlisted | `SAFETY_VIOLATION` | 12 |
| `cap.md` | S3 | sold, listed, listed, unlisted | `SAFETY_VIOLATION` | 12 |
| `path.md` | S4 | settled, returned, unlisted, unlisted | `SAFETY_VIOLATION` | 12 |
| `till.md` | S5 | a step moving two items | `LIVENESS_VIOLATION` | 13 |

One reading note. The S4 witness TLC chose settles the lamp while Ann's only
sold item is the lamp, so its final step is a legal one-item settlement, and
all four lawful moves appear across the six states. The S5 witness is the
two-item settlement, so the pair in `till.md` differs only in its last step,
which I think is what makes it teach: whole payout beside partial payout,
five identical states, one diverging step.
