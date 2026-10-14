# META

- **shape**: behavior table to one temporal formula, plus a one-sentence safety question
- **TLA+ in the prompt**: none
- **time**: 6 to 10 minutes
- **verify**: `bash drill/temporal/verify-item.sh drill/temporal/03-commit-sticks`

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the answer and its accepted variants use.

- `[] (always)`
- `[P]_x (box action formula)`
- `' (prime, next-state value)`
- `action property`
- `UNCHANGED`

## Roles

| id | construct | role |
|---|---|---|
| K063 | `[] (always)` | answer, nested |
| K080 | `[P]_x (box action formula)` | variants |
| K079 | `' (prime, next-state value)` | variants |
| K078 | `action property` | variants |
| K085 | `UNCHANGED` | variant |
| K070 | `~> (leads-to)` | neighbor, killed by row 3, not declared |
| K067 | `<> (eventually)` | neighbor, killed by row 2, not declared |
| K068 | `<>[] (eventually always)` | neighbor, killed by row 2, not declared |
| K069 | `[]<> (always eventually)` | neighbor, killed by row 2, not declared |
