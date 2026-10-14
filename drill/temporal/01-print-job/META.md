# META

- **shape**: behavior table to one temporal formula
- **TLA+ in the prompt**: none
- **time**: 6 to 10 minutes
- **verify**: `bash drill/temporal/verify-item.sh drill/temporal/01-print-job`

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the answer and its accepted variants use.

- `~> (leads-to)`
- `[] (always)`
- `<> (eventually)`

## Roles

| id | construct | role |
|---|---|---|
| K070 | `~> (leads-to)` | answer |
| K063 | `[] (always)` | spelled-out variant |
| K067 | `<> (eventually)` | spelled-out variant |
| K069 | `[]<> (always eventually)` | neighbor, killed by row 2, not declared |
| K068 | `<>[] (eventually always)` | neighbor, killed by row 5, not declared |
| K080 | `[P]_x (box action formula)` | neighbor, killed by row 3, not declared |
