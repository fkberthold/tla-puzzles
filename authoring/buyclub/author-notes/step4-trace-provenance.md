# Step 4 trace provenance

Author-only. Every file under `statement/traces/` maps to a reference
obligation and a step-2 variant here, which is exactly what the learner
must not see. Bead `tla-7fbx`.

## How the pairs were made

**Violating runs** are TLC's own counterexamples. Nine of the step-2
matrix's caught variants were regenerated from the frozen reference
(sha256 checked against `reference/FREEZE.sha256` before mutation, every
anchor asserted to match once) and run through `harness/verdict.sh -t 300`
against the frozen `reference/BuyClub.cfg`, keeping `--trace` and `--log`.
The JSON counterexample is rendered with the cfg's model values renamed
(`m1/m2/m3` to Ana/Ben/Cai, `p1/p2` to oats/oil) and nothing else changed.

**Satisfying runs** are constructed behaviors, each verified by a probe.
The probe module extends the frozen reference (a sha-checked copy beside
it), holds the trace as a sequence `T`, and conjoins the reference `Next`
into its step relation:

```
PNext == i < Len(T) /\ Next /\ i' = i + 1 /\ phase' = T[i+1].phase /\ ...
INVARIANT NotDone   \* i # Len(T)
```

An exit of 12 means TLC walked the whole sequence: the first state
satisfies `Init` and every step is a real reference step. An exit of 0
would mean the constructed path is not a behavior. All nine exited 12.
Probes run at the statement's instance with string constants
(`{"Ana","Ben","Cai"}`, `{"oats","oil"}`, Min 3, Cap 2), so the satisfying
runs render with no renaming at all.

## The map

| traces file | obligation | variant | variant rc/token | log names | probe rc/token |
|---|---|---|---|---|---|
| requirement-1 | `Opening` | V01 | 13 `LIVENESS_VIOLATION` | Property line 78 (implied init, by source location) | 12 `SAFETY_VIOLATION` |
| requirement-2 | `OneHandAtATime` | V05 | 13 `LIVENESS_VIOLATION` | `OneHandAtATime` | 12 `SAFETY_VIOLATION` |
| requirement-3 | `Threshold` | V08 | 13 `LIVENESS_VIOLATION` | `Threshold` | 12 `SAFETY_VIOLATION` |
| requirement-4 | `Snapshot` | V10 | 13 `LIVENESS_VIOLATION` | `Snapshot` | 12 `SAFETY_VIOLATION` |
| requirement-5 | `TwoWaysOnly` | V13 | 13 `LIVENESS_VIOLATION` | `TwoWaysOnly` | 12 `SAFETY_VIOLATION` |
| requirement-6 | `ForwardPhases` | V20 | 13 `LIVENESS_VIOLATION` | `ForwardPhases` | 12 `SAFETY_VIOLATION` |
| requirement-7 | `SharesTellTheBook` | V06 | 12 `SAFETY_VIOLATION` | `SharesTellTheBook` | 12 `SAFETY_VIOLATION` |
| requirement-8 | `DeliveryComes` | V22 | 13 `LIVENESS_VIOLATION` | `DeliveryComes` | 12 `SAFETY_VIOLATION` |
| requirement-9 | `TypeOK` | V03 | 12 `SAFETY_VIOLATION` | `TypeOK` | 12 `SAFETY_VIOLATION` |

Every variant rc matches its step-2 row, and every log names the same
obligation step 2 recorded. V22's counterexample is a 13-state lasso whose
loop edge is a self-loop on the final state (`m2`'s oil collection last),
rendered for the learner as "from here nothing more happens".

## Choices worth a sentence

- **V05 over V07** for requirement 2, and **V06 over V04** for
  requirement 7: the two-state counterexamples. Same obligation, less to
  read.
- **V20 over V18** for requirement 6: V18's log names `SharesTellTheBook`,
  so its trace teaches the wrong requirement.
- **The satisfying runs double as over-constraint oracles.**
  requirement-3's run kills V24 (a pledge lands while the total is over
  `Min`), V26 (placement at 4, not at `Min` exactly), and V27 (Ben
  withdraws). requirement-5's kills V28 (Ana collects oats while oil is
  still open). That was the design intent: cause-A variants are invisible
  to the property set, so the traces are the only artifact that catches
  them.
- **V25 (strong fairness on placement) has no finite refutation.** No
  trace pair can show "this model forces the order eventually". The
  statement carries that clause in prose instead, in rule 3 and the
  two-directions warning. Known limit, on the record.

## Reproducing

The generator, probes, runner, and renderer live in `variant-scratch/step4/`
(`gen.py`, `common.py`, `run.sh`, `render.py`), uncommitted like step 2's
variants, and they rebuild everything above from the frozen reference at
this commit. `render.py` and the probes read the same state sequences from
`common.py`, so the learner files and the verification can't drift apart.
