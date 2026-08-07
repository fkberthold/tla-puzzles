# seeded-bug fixtures

Purpose-built inputs for `harness/seeded-bugs.sh` (V2-PLAN.md §5.5, bead
`tla-kl5.8`). `selftest.sh` runs every row and asserts the raw exit status as
well as the verdict token, so a renumbered table breaks the build instead of
quietly relabelling itself.

Measured 2026-08-07 against the TLC 2026.03.04.183147 nightly, and re-measured unchanged
the same day against tla2tools v1.8.0 (TLC 2026.07.31.184830). Every row below holds on
both builds.

```
harness/fixtures/seeded-bugs/selftest.sh
```

## The row the component exists for

`Inv == TRUE` holds of the reference, holds of every variant, passes §5.3's
vacuity probes, passes the comment gate, and exits 0 every single time. Every
check that asks *does your property hold* says yes.

| submission | reference | variants | verdict |
|---|---|---|---|
| `properties/Good.tla` | rc=0 | rc=12, rc=12, rc=12 | `BUGS_CAUGHT` (0) |
| `properties/AlwaysTrue.tla` | rc=0 | **rc=0, rc=0, rc=0** | `PROPERTY_TOO_WEAK` (40) |

Both halves of the obligation are load-bearing and neither is sufficient. Drop
the rc==12 half and `AlwaysTrue` passes; drop the rc==0 half and `Unsound`
passes, which is the same worthlessness with the sign flipped.

## The fixture matrix

`crossing/` is the matrix root: `reference/`, `oracle/`, `variants/`. The other
variant directories are used with `--variants`, sharing that one reference and
oracle rather than duplicating them.

| invocation | verdict | rc | what it pins |
|---|---|---|---|
| `Good.tla` | `BUGS_CAUGHT` | 0 | the positive control |
| `AlwaysTrue.tla` | `PROPERTY_TOO_WEAK` | 40 | the only mechanical defense against `Inv == TRUE` |
| `MutexOnly.tla` | `PROPERTY_TOO_WEAK` | 40 | right about one bug, still not enough |
| `TypeOnly.tla` | `PROPERTY_TOO_WEAK` | 40 | the other conjunct alone — neither subsumes the other |
| `Unsound.tla` | `PROPERTY_UNSOUND` | 41 | the reference itself violates it |
| `--variants variants-inert` | `VARIANT_INERT` | 42 | a mutation that changed nothing — **our** bug |
| `--variants variants-divergent --strict-trace` + `TypeOnly` | `TRACE_DIVERGED` | 43 | caught, but a different bug than the oracle's |
| `--variants variants-malformed` | `MATRIX_MALFORMED` | 44 | a variant that does not supply the module it mutates |
| `--oracle oracle-unsound/Oracle.tla` | `ORACLE_UNSOUND` | 45 | the instrument checks itself first |
| `properties/NoSuchModule.tla` | `PARSE_ERROR` | 150 | TLC outcomes pass through unchanged |

## The variants, and what each one is for

All four are `crossing/reference/Crossing.tla` with **one definition** changed,
keeping the module name so the same property module extends them unmodified.

| variant | mutation | caught by |
|---|---|---|
| `ns-runs-red` | `NSGo` loses its `ew = "red"` guard | mutual exclusion |
| `ew-runs-red` | `EWGo` loses its `ns = "red"` guard | mutual exclusion |
| `amber-on-go` | `NSGo` assigns `"amber"` | a type invariant **only** |
| `inert-guard` | `NSStop`'s `ns = "green"` becomes `ns # "red"` | **nothing** |
| `two-bugs` | both of the first and the third | either, at the same depth |

`amber-on-go` is the discriminating row. Mutual exclusion never fires on it —
the lights are never both green — so without it "catches the seeded bugs" would
be satisfiable by a single conjunct.

## `inert-guard` — the fixture that is wrong on OUR side

Every reachable state has `ns \in {"red", "green"}`, so `ns # "red"` and
`ns = "green"` pick out the same states and the mutated state graph is
**identical** to the reference's. No property can distinguish it, because there
is nothing to distinguish. ~39.3% of single mutations are like this.

The measurement that makes the attribution real is that the verdict does not
depend on the submission:

| submission graded against `variants-inert/` | verdict |
|---|---|
| `Good.tla` | `VARIANT_INERT` (42) |
| `AlwaysTrue.tla` | `VARIANT_INERT` (42) |

Both rows are in `selftest.sh`. Remove the inert check and the second row comes
back `PROPERTY_TOO_WEAK` — a wrong verdict, about the right exit code, billed
to the wrong party. That is measured, not asserted: it is mutation `M3` of the
suite's own mutation testing.

`variants-inert/` also holds a live variant, so "reports `VARIANT_INERT`" is
distinguishable from "reports `VARIANT_INERT` whenever it cannot catch
anything".

## `traces/` — what the comparison ignores

Four hand-written trace dumps, fed to `seeded-bugs.sh --trace-signature`. This
is the only place the comparison's **blindness** can be shown: a live fixture
can show that two runs agree, never that they would still have agreed had the
values differed.

| pair | signature | verdict |
|---|---|---|
| `base.json` vs `same-actions-other-values.json` | `3 steps: EWGo -> NSGo` (both) | **equal** |
| `base.json` vs `other-actions.json` | `... -> NSGo` vs `... -> EWStop` | different |
| `base.json` vs `shorter.json` | `3 steps` vs `2 steps` | different |

The first pair carries different variable **names**, a different value
**domain** (integers against strings) and different concrete **values**, and
describes the same behaviour. Diffing values would fail a correct submission
for choosing a different encoding — the representational freedom §3.2 exists to
protect.

## Normalisation happens before the dump

`crossing/reference/Crossing.tla` defines `Alias`, passed as `ALIAS Alias` in
the generated `.cfg`. The trace on disk therefore carries `north`/`east` and
never `ns`/`ew`, which is the only way to show the ordering: a normalisation
applied afterwards would leave the raw names in the dumped file.

The alias lives in the **spec**, not in a property module. The oracle run and
the submission run must normalise identically or the comparison means nothing,
and a submission's module is not in scope for the oracle run at all.

## Do not "repair" these

`crossing/variants/*`, `variants-inert/inert-guard`, `variants-divergent/two-bugs`,
`oracle-unsound/Oracle.tla`, `properties/Unsound.tla` and
`variants-malformed/no-such-module/` are all wrong on purpose. Fixing any of
them silently deletes a row.

## The caveat that travels with every number here

Only ~10.9% of real faulty student specs are one mutation away from correct —
real mistakes are multi-step — and ~39.3% of single mutations are semantically
inert. Mutants of our own reference are systematically unlike real learner
errors. **This is a bootstrap, not a proxy for learner behaviour.** A pass here
is evidence a property catches *these* bugs and nothing more. The long form is
in the header of `harness/seeded-bugs.sh`, where the next reader will meet it.
