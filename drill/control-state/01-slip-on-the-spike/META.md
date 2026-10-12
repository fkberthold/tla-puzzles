# 01 slip-on-the-spike

- family: control-state
- shape: prose situation, a four-row behaviour table with one foreclosing row, a stated property, and a follow-up question about a change to the workplace
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, two-step (rc 12, 9 states) and atomic (rc 0, 3 states)

## Constructs exercised

Named as `drill/INVENTORY.md` field 4 writes them.

| id | construct | where |
|---|---|---|
| K036 | `pc` (PlusCal's label-tracking variable) | hand-rolled, a function from picker to label |
| K054 | `pc[...]` (multi-process pc) | the guard and update in each action |
| K090 | label-as-action encoding | `Glance` and `Fetch` each own one label |
| K041 | model value | every label and both slip positions |
| K042 | set of model values | `Pickers` |
| K087 | EXCEPT | the pc update |
| K080 | `[P]_x` (box action formula) | the spec skeleton |
| K082 | vars (the all-variables tuple) | covers pc |
| K059 | deadlock (checking) | `CHECK_DEADLOCK FALSE`, and why that is the right call here |
| K037 | `\A` (universal quantifier, "forall") | the property |

## The lesson in one line

Where you put the control point decides the verdict. The two-step encoding admits the foreclosing row and fails. The atomic encoding passes and is a model of a different workplace.
