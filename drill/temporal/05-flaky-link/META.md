# META

- **shape**: lasso table to one fairness conjunct
- **TLA+ in the prompt**: none
- **time**: 8 to 10 minutes
- **verify**: `bash drill/temporal/verify-item.sh drill/temporal/05-flaky-link`

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the answer and the guarantee it buys use.

- `SF_v(A) (strong fairness)`
- `fairness conjunct on Spec`
- `fairness on a subaction`
- `[]<> (always eventually)`
- `<> (eventually)`

## Roles

| id | construct | role |
|---|---|---|
| K096 | `SF_v(A) (strong fairness)` | answer |
| K098 | `fairness on a subaction` | answer |
| K097 | `fairness conjunct on Spec` | answer |
| K069 | `[]<> (always eventually)` | the guarantee |
| K067 | `<> (eventually)` | the guarantee |
| K095 | `WF_v(A) (weak fairness)` | neighbor, killed by L2, not declared |
| K093 | `ENABLED` | implicit in what SF means, not declared |
| K094 | `<<A>>_v (angle action formula)` | implicit in what SF means, not declared |
