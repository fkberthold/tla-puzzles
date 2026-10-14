# META

- **shape**: step table to one action formula
- **TLA+ in the prompt**: none
- **time**: 6 to 8 minutes
- **verify**: `bash drill/temporal/verify-item.sh drill/temporal/08-turnstile-clock`

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the answer and its accepted variant use.

- `[P]_x (box action formula)`
- `' (prime, next-state value)`
- `action property`
- `[] (always)`

## Roles

| id | construct | role |
|---|---|---|
| K080 | `[P]_x (box action formula)` | answer |
| K079 | `' (prime, next-state value)` | answer |
| K078 | `action property` | answer |
| K063 | `[] (always)` | answer, the outer box |
| K082 | `vars (the all-variables tuple)` | neighbor, killed by S2, and the reason the item exists, not declared |
| K085 | `UNCHANGED` | neighbor, the spelled-out clock, not declared |
