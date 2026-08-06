# verdict fixtures

One purpose-built spec per row of the exit-code table in `harness/verdict.sh`.
Each exists to drive `verdict.sh` to exactly one verdict, so that the mapping
from TLC exit code to harness verdict is pinned by execution rather than by
belief. `harness/test-verdict.sh` runs every row and asserts the raw exit
status as well as the token.

Measured 2026-08-06 against TLC 2026.03.04 / tla2tools 1.8.0.

| fixture | rc | verdict | how it provokes the code |
|---|---|---|---|
| `Ok.tla` | 0 | `OK` | trivially-satisfied invariant over 5 states |
| `AssumeFalse.tla` | 10 | `ASSUMPTION_FAILED` | `ASSUME FALSE` |
| `PostCondFalse.tla` | 10 | `ASSUMPTION_FAILED` | 1 distinct state fails `Gate!NonVacuous` |
| `Deadlock.tla` | 11 | `DEADLOCK` | `x = 2` has no successor (needs `--check-deadlock`) |
| `SafetyViolation.tla` | 12 | `SAFETY_VIOLATION` | `INVARIANT x < 3`, reachable `x = 3` |
| `LivenessViolation.tla` | 13 | `LIVENESS_VIOLATION` | `PROPERTY <>(x = 1)` with no fairness |
| `Unbounded.tla` | 124 | `TIMEOUT` | infinite state space under a short `timeout` |
| `ParseError.tla` | 150 | `PARSE_ERROR` | syntactically invalid module |
| `ConfigError.tla` | 151 | `CONFIG_ERROR` | `.cfg` names an operator the spec lacks |
| `NoSuchModule.*` | 255 | `TLC_EXCEPTION` | *deliberately absent* — never create either file |

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

`NoSuchModule.tla` and `NoSuchModule.cfg` are fixtures by their *absence*.
Creating a file at either path breaks both the rc=255 case and the rc=150 case
that share them. `test-verdict.sh` asserts the absence before it asserts the
verdicts, so the damage surfaces as a named failure rather than as a
green-for-the-wrong-reason.
