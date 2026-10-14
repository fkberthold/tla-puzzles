# 06 three-reds

- family: control-state
- shape: a field procedure with a loop and a branch, three rules, a four-row behavior table with one foreclosing row, and a closing question about what records the step
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: the two end-state treatments (rc 0 / rc 0, 13 states each) against neither (rc 11), and the off-by-one neighbor (rc 12)

## Constructs exercised

One per bullet, spelled as `drill/INVENTORY.md` field 4 spells it.

- pc (PlusCal's label-tracking variable)
- label-as-action encoding
- Terminating
- deadlock (checking)
- IF-THEN-ELSE
- ' (prime, next-state value)
- action property
- [P]_x (box action formula)
- PROPERTY (TLC model config: register a temporal property)
- Booleans and logical operators
- model value

## Where each lands

| what | where |
|---|---|
| the label-tracking variable | hand-rolled scalar, five labels |
| label-as-action | one action per transition, loop closed by `pc' = Start` |
| Terminating | two intended ends under one disjunct |
| deadlock checking | the config-switch alternative, measured |
| IF-THEN-ELSE | the branch in `SeeRed` |
| the prime | `reds'` on the right-hand side of the branch |
| the action property and the box action | `HandsOff`, registered as a `PROPERTY` |
| the logical operators | the equivalence in `ThreeRedsExactly` |
| model values | labels |

## The lesson in one line

When the same data holds at different places in the procedure, the label is carrying history the data does not, and that is when it earns its place.
