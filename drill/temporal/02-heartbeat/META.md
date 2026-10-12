# META

- **shape**: behaviour table to one temporal formula
- **TLA+ in the prompt**: none
- **time**: 6 to 10 minutes
- **verify**: `bash drill/temporal/verify-item.sh drill/temporal/02-heartbeat`

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the answer and its accepted variants use.

- `<<A>>_v (angle action formula)`
- `[]<> (always eventually)`
- `' (prime, next-state value)`
- `action (formal definition)`

## Roles

| id | construct | role |
|---|---|---|
| K094 | `<<A>>_v (angle action formula)` | answer |
| K069 | `[]<> (always eventually)` | answer |
| K079 | `' (prime, next-state value)` | answer |
| K084 | `action (formal definition)` | answer, the Beat action |
| K067 | `<> (eventually)` | neighbour, killed by row 2, not declared |
| K080 | `[P]_x (box action formula)` | neighbour, killed by row 3, not declared |
| K095 | `WF_v(A) (weak fairness)` | variant in the wrong register, not declared |
