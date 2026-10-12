# META

- **shape**: lasso table to one fairness conjunct
- **TLA+ in the prompt**: none
- **time**: 8 to 10 minutes
- **verify**: `bash drill/temporal/verify-item.sh drill/temporal/06-help-desk`

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the answer and its two guarantee lines use.

- `WF_v(A) (weak fairness)`
- `fairness conjunct on Spec`
- `fairness on a subaction`
- `[] (always)`
- `~> (leads-to)`

## Roles

| id | construct | role |
|---|---|---|
| K095 | `WF_v(A) (weak fairness)` | answer |
| K098 | `fairness on a subaction` | answer |
| K097 | `fairness conjunct on Spec` | answer |
| K063 | `[] (always)` | the guarantee |
| K070 | `~> (leads-to)` | what the answer does not buy |
| K096 | `SF_v(A) (strong fairness)` | neighbour, killed by L2, not declared |
| K094 | `<<A>>_v (angle action formula)` | the NeverStops property, not declared |
| K093 | `ENABLED` | implicit in what WF means, not declared |
