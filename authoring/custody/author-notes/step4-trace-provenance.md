# Step 4, author-only: where every published trace comes from

Never show anything in `author-notes/` to a learner or a blind agent. This
file maps each `statement/traces/` file to its source variant in the frozen
step-2 matrix, with the command that produced it and what TLC named. The
statement's property numbers are the learner's numbering, so the map from
property to obligation is also recorded here and nowhere learner-visible.

All runs went through `harness/verdict.sh` from `harness/` as the working
directory, on TLC 2026.07.31.184830, against the reference frozen at
`a2bfffb` (FREEZE.sha256 verified `OK`, all 10 files, before the first run).
Variants were rebuilt from the report's "Exact mutations" section by
`trace-probes/build-variants.py`, which refuses an anchor that does not
match exactly once. The command shape, per variant NN:

```
./verdict.sh -t 300 -c ../tmp-variants/vNN/MCCustody.cfg \
    --trace ../tmp-variants/vNN/trace.json \
    --log   ../tmp-variants/vNN/run.log \
    ../tmp-variants/vNN/MCCustody.tla
```

with `-t 2400` for V16 (the family's step-2 budget) and `-t 600` for V05 and
V06. Tables were rendered from the JSON traces by
`trace-probes/render-traces.py`, over the observation fields only.

## The violating traces

| Trace file | Property (learner) | Obligation (graded) | Variant | Token | rc | TLC named | States gen/distinct |
|---|---|---|---|---|---|---|---|
| property-01 | total custody | `TotalCustody` | V07 | `SAFETY_VIOLATION` | 12 | `Invariant TotalCustody is violated` | 59 / 58 |
| property-02 | opening baseline | `OpeningBaseline` | V09 | `LIVENESS_VIOLATION` | 13 | `Property line 80 ... of module Custody is violated by the initial state` | initial state |
| property-03 | at most one flip | `FlipOnce` | V23 | `LIVENESS_VIOLATION` | 13 | `Action property FlipOnce is violated` | 976 / 475 |
| property-04 | flips from acceptance | `FlipCause` | V13 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | 3 / 3 |
| property-05 | past is fixed | `PastFixed` | V06 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | 460,933 / 96,446 |
| property-06 | proposals point forward | `PendingFresh` | V14 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | 32 / 32 |
| property-07 | the cap | `CapRespected` | V24 | `SAFETY_VIOLATION` | 12 | `Invariant CapRespected is violated` | 48,238 / 12,878 |
| property-08 | quiet at the end | `QuietAtEnd` | V06 | `LIVENESS_VIOLATION` | 13 | (same run as property-05) | 460,933 / 96,446 |
| property-09 (first) | window runs | `WindowCompletes` | V05 | `LIVENESS_VIOLATION` | 13 | `Temporal property WindowCompletes was violated` | 7,176 / 3,059 |
| property-09 (second) | window runs | `TodayMarches` | V02 | `LIVENESS_VIOLATION` | 13 | `Action property TodayMarches is violated` | 2 / 2 |
| property-10 | proposal holds its day | `OneOutstanding` | V16 | `LIVENESS_VIOLATION` | 13 | `Action property OneOutstanding is violated` | 62 / 58 |

Every token and named obligation matches the step-2b re-run table in
`reports/step2-variants.md`, V09's line-range naming quirk included. Two
rows earn a note.

**V06 serves two properties.** Its counterexample flips day 1 at
`today = H`, which violates `PastFixed`, `QuietAtEnd` and `FlipCause` at
once. TLC names `FlipCause` because that check fires first, but the trace
itself breaks all three, and the two property files each point at the break
their property owns. No caught variant is named by `PastFixed` or
`QuietAtEnd` on this instance (the step-2 report's redundancy note), so a
shared trace is what the frozen set offers.

**V16 at step 4 costs seconds, not minutes.** The step-2 budget warning was
about the uncaught V16 exploring 2.2M states for an `OK`. With
`OneOutstanding` in the frozen set it dies at depth 3. The `-t 2400` budget
was honored anyway.

## The satisfying trace

`traces/full-window.md` is hand-shaped, then verified by replay:
`trace-probes/TraceReplay.tla` forces the reference's own `Init` and `Next`
through the 24 states and requires `INVARIANT NotDone` to fail.

```
./verdict.sh -t 300 -c ../tmp-variants/replay/TraceReplay.cfg \
    ../tmp-variants/replay/TraceReplay.tla
=> SAFETY_VIOLATION, rc=12, "Invariant NotDone is violated", 25 / 24 states
```

rc=12 is the pass: TLC reached `i = 24`, so all 23 steps are real
transitions of the frozen spec from its real opening state. rc=0 on that
probe would mean a forged trace, and it must be re-run if the trace tables
are ever edited.

## The transcription R-probe

`trace-probes/gen-replay-sub.py` builds the "submission" measured in
`reports/step4-screens.md`: the same 24 states as a deterministic script
with no `Next` behind it. Obligations run `OK` rc=0, all three witness
probes rc=12. Kept here because step 5 and §5.3 will want to reproduce it.

## Renderer conventions, in case a trace needs regenerating

- Base string `AAABAAA BBBABBB`, holidays day 4 to B and day 11 to A,
  swapped day shows the other parent, V07's swapped day shows `-`.
- Narration is written by hand for variant-invented actions (V02's jump,
  V06's churn, V13's unilateral swap, V23's unswap); the renderer emits a
  placeholder for those.
- The 0 marker renders as "none yet" (`today`) and "none" (`pending`).
