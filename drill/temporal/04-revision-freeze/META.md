# META

- **shape**: step table to a complete module
- **TLA+ in the prompt**: none
- **time**: 8 to 12 minutes
- **verify**: `bash drill/temporal/verify-item.sh drill/temporal/04-revision-freeze`

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the answer uses.

- `VARIABLE / VARIABLES`
- `vars (the all-variables tuple)`
- `Init / Next / Spec (the pure-TLA+ spec skeleton)`
- `action (formal definition)`
- `UNCHANGED`
- `nondeterministic action (\E form and disjunction form)`
- `' (prime, next-state value)`
- `[P]_x (box action formula)`

## Roles

| id | construct | role |
|---|---|---|
| K081 | `VARIABLE / VARIABLES` | answer |
| K082 | `vars (the all-variables tuple)` | answer, and the two subscript neighbors |
| K083 | `Init / Next / Spec (the pure-TLA+ spec skeleton)` | answer |
| K084 | `action (formal definition)` | answer |
| K085 | `UNCHANGED` | answer |
| K086 | `nondeterministic action (\E form and disjunction form)` | answer, disjunction form |
| K079 | `' (prime, next-state value)` | answer |
| K080 | `[P]_x (box action formula)` | answer |
