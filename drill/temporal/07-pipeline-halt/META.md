# META

- **shape**: prose rules to one checkable predicate
- **TLA+ in the prompt**: none
- **time**: 6 to 8 minutes
- **verify**: `bash drill/temporal/verify-item.sh drill/temporal/07-pipeline-halt`

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the answer and its property form use.

- `ENABLED`
- `[] (always)`
- `Init / Next / Spec (the pure-TLA+ spec skeleton)`

## Roles

| id | construct | role |
|---|---|---|
| K093 | `ENABLED` | answer |
| K063 | `[] (always)` | property form |
| K083 | `Init / Next / Spec (the pure-TLA+ spec skeleton)` | `Next` as the operand |
| K069 | `[]<> (always eventually)` | neighbour, not declared |
| K067 | `<> (eventually)` | neighbour, not declared |

Cross-family, touched and not claimed: K059 `deadlock (checking)` and K034
`Invariant`, both in `state-space`.
