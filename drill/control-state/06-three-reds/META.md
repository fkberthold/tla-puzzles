# 06 three-reds

- family: control-state
- shape: a field procedure with a loop and a branch, three rules, a four-row behaviour table with one foreclosing row, and a closing question about what records the step
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: the two end-state treatments (rc 0 / rc 0, 13 states each) against neither (rc 11), and the off-by-one neighbour (rc 12)

## Constructs exercised

Named as `drill/INVENTORY.md` field 4 writes them.

| id | construct | where |
|---|---|---|
| K036 | `pc` (PlusCal's label-tracking variable) | hand-rolled scalar, five labels |
| K090 | label-as-action encoding | one action per transition, loop closed by `pc' = Start` |
| K092 | Terminating | two intended ends under one disjunct |
| K059 | deadlock (checking) | the config-switch alternative, measured |
| K002 | IF-THEN-ELSE | the branch in `SeeRed` |
| K079 | `'` (prime, next-state value) | `reds'` on the right-hand side of the branch |
| K078 | action property | `HandsOff` |
| K080 | `[P]_x` (box action formula) | `HandsOff` as a `PROPERTY`, not only the spec |
| K064 | PROPERTY (TLC model config: register a temporal property) | `HandsOff` |
| K007 | Booleans and logical operators | `<=>` in `ThreeRedsExactly` |
| K041 | model value | labels |

## The lesson in one line

When the same data holds at different places in the procedure, the label is carrying history the data does not, and that is when it earns its place.
