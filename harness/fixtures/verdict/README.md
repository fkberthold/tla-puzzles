# verdict fixtures

One purpose-built spec per row of the exit-code table in `harness/verdict.sh`.
Each exists to drive `verdict.sh` to exactly one verdict, so that the mapping
from TLC exit code to harness verdict is pinned by execution rather than by
belief. `harness/test-verdict.sh` runs every row and asserts the raw exit
status as well as the token.

Measured 2026-08-06 against the TLC 2026.03.04.183147 nightly, and re-measured unchanged
on 2026-08-07 against tla2tools v1.8.0 (TLC 2026.07.31.184830). Every row below holds on
both builds, except the five added on 2026-08-07 (`AssertViolation` through
`LivenessEvalFailure`), which are measured on v1.8.0 only.

The set of codes that *exists* is not a judgement call — it is read out of the jar:

```bash
javap -cp ~/lib/tla2tools.jar -constants 'tlc2.output.EC$ExitStatus'
```

| fixture | rc | verdict | how it provokes the code |
|---|---|---|---|
| `Ok.tla` | 0 | `OK` | trivially-satisfied invariant over 5 states |
| `AssumeFalse.tla` | 10 | `ASSUMPTION_FAILED` | `ASSUME FALSE` |
| `PostCondFalse.tla` | 10 | `ASSUMPTION_FAILED` | 1 distinct state fails `Gate!NonVacuous` |
| `Deadlock.tla` | 11 | `DEADLOCK` | `x = 2` has no successor (needs `--check-deadlock`) |
| `SafetyViolation.tla` | 12 | `SAFETY_VIOLATION` | `INVARIANT x < 3`, reachable `x = 3` |
| `LivenessViolation.tla` | 13 | `LIVENESS_VIOLATION` | `PROPERTY <>(x = 1)` with no fairness |
| `AssertViolation.tla` | 14 | `ASSERT_VIOLATION` | `Assert` FALSE while exploring behaviour |
| `AssertInInit.tla` | 75 | `SPEC_EVAL_FAILURE` | the *same* `Assert`, failing in `Init` |
| `SpecEvalFailure.tla` | 75 | `SPEC_EVAL_FAILURE` | one branch of `Tick` leaves `minutes'` unconstrained |
| `SafetyEvalFailure.tla` | 76 | `SAFETY_EVAL_FAILURE` | `INVARIANT` applies a function outside its domain |
| `LivenessEvalFailure.tla` | 77 | `LIVENESS_EVAL_FAILURE` | `PROPERTY` quantifies over the empty set |
| `Unbounded.tla` | 124 | `TIMEOUT` | infinite state space under a short `timeout` |
| `ParseError.tla` | 150 | `PARSE_ERROR` | syntactically invalid module |
| `ConfigError.tla` | 151 | `CONFIG_ERROR` | `.cfg` names an operator the spec lacks |
| `NoSuchModule.*` | 255 | `TLC_EXCEPTION` | *deliberately absent* — never create either file |

The five rows from `AssertViolation` down to `LivenessEvalFailure` were added 2026-08-07 by bead
`tla-i9m`, which found that `V2-PLAN.md` §5.1's table was six codes short of the jar's own
`EC$ExitStatus` enum and that none of the missing codes had a fixture.

## The two pairs, and why each is a pair

**`AssertViolation.tla` / `AssertInInit.tla` — rc=14 vs rc=75.** The same construct, an `Assert`
whose first argument is FALSE, in two places. In the next-state relation it exits **14**; in
`Init` it exits **75**, because the initial-state computation wraps the `EvalException` as
`EC.TLC_NESTED_EXPRESSION` (2103) rather than letting the assertion's own error code through. So
rc=14 is a fact about *when* the assertion fired, not about *what* fired. Anyone reading the
exit-code table as a map from language construct to code gets this wrong, so both halves are
pinned rather than one.

**`SpecEvalFailure.tla` / `AssertInInit.tla` — one code, two unrelated defects.** rc=75 is a
family: `EC.errorConstantToExitStatus` routes `TLC_NESTED_EXPRESSION` (2103),
`TLC_STATE_NOT_COMPLETELY_SPECIFIED_NEXT` (2109), `TLC_STATES_AND_NO_NEXT_ACTION` (2115) and
`TLC_FINGERPRINT_EXCEPTION` (2147) to it. These two fixtures reach it through the first two.

## `SpecEvalFailure.tla` is the one fixture that was not invented here

Every other spec in this directory was written to provoke a code. `SpecEvalFailure.tla` is a copy
of `puzzles/T29-unchanged/solution/Clock_buggy.tla` — the v1 curriculum's own under-constrained-
action demonstration, which hits rc=75 in the corpus today. Copied rather than referenced:
`puzzles/` is v1 and v2 does not modify it, and a fixture reaching out of `harness/fixtures/`
would make the verdict table hostage to a curriculum edit.

Its history is the reason §5.1 tells the story at length. Before the `tla-kl5.4` rewire the grep
chain classified this rc as `PASS-VIOLATION` **because it matched the `Trace exploration` line of
the `*_TTrace_*.tla` file TLC emits beside the error** — and the canonical invocation passes
`-noGenerateSpecTE`, which suppresses that file. Adopting the canonical invocation while keeping
the greps would have silently deleted the sole basis for T29's verdict.

## What is NOT here, and why that is deliberate

`ERROR_STATESPACE_TOO_LARGE = 152` and `ERROR_SYSTEM = 153` are declared in the jar's enum and
have **no fixture** — not because none was attempted, but because no bytecode in tla2tools v1.8.0
pushes either as an exit value (the only `sipush 152/153` sites in the jar are parser token
constants and bundled third-party libraries), and both are absent from the enum's own
`knownExitValues` set. They are dead constants in this build.

Do not add a case arm for either to `verdict.sh` on the strength of the enum alone. A mapping
nobody has measured is a guess wearing a table's authority; `test-verdict.sh` asserts the absence
of those two arms so the discipline is gated rather than merely written down.

`Gate.tla` is the shared non-vacuity gate (V2-PLAN.md §5.3); it is not itself a
fixture. `Ok.tla` doubles as the positive control for the `-postCondition`
channel, which is why it has 5 distinct states rather than 2.

## The three cfg-only fixtures

These carry no module of their own — they are applied to `Ok.tla` via
`--config`, because the point of each is that the *module* is fine.

| cfg | rc | what it pins |
|---|---|---|
| `BadCfgSyntax.cfg` | 255 | a `.cfg` that fails to PARSE is not 151 |
| `DanglingKeyword.cfg` | 0 | a `.cfg` keyword with no operand is not an error at all |

`DanglingKeyword.cfg` is the sharpest of the set. A bare `INVARIANT` line makes
TLC exit 0 having silently checked no invariant whatsoever — a vacuous pass
indistinguishable from a real one, and the §5.3 hazard class arriving through
the config file rather than through `Init`.

## Fixtures that are broken on purpose

`ParseError.tla` will not parse, `ConfigError.cfg` names an operator that does
not exist, and `BadCfgSyntax.cfg` is not a config file. Repairing any of them
silently deletes a row of the table.

The same holds for the five newer specs, and each is easy to "tidy" without
noticing: `SpecEvalFailure.tla` is missing an `UNCHANGED`,
`LivenessEvalFailure.tla` quantifies over `{}`, `SafetyEvalFailure.tla` applies
`f` outside its domain, and the two `Assert` fixtures assert something false.
None of that is an oversight. Note especially that moving `AssertViolation`'s
`Assert` into `Init`, or weakening it so it fails on the initial state, does not
break the suite loudly — it converts the fixture into a duplicate of
`AssertInInit.tla` and deletes the rc=14 row.

`NoSuchModule.tla` and `NoSuchModule.cfg` are fixtures by their *absence*.
Creating a file at either path breaks both the rc=255 case and the rc=150 case
that share them. `test-verdict.sh` asserts the absence before it asserts the
verdicts, so the damage surfaces as a named failure rather than as a
green-for-the-wrong-reason.
