# 01 slip-on-the-spike

- family: control-state
- shape: prose situation, a four-row behaviour table with one foreclosing row, a stated property, and a follow-up question about a change to the workplace
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, two-step (rc 12, 9 states) and atomic (rc 0, 3 states)

## Constructs exercised

One per bullet, spelled as `drill/INVENTORY.md` field 4 spells it.

- pc (PlusCal's label-tracking variable)
- pc[...] (multi-process pc)
- label-as-action encoding
- model value
- set of model values
- EXCEPT
- [P]_x (box action formula)
- vars (the all-variables tuple)
- deadlock (checking)
- \A (universal quantifier, "forall")

## Where each lands

| what | where |
|---|---|
| the label-tracking variable | hand-rolled, a function from picker to label |
| the multi-process form | the guard and update in each action |
| label-as-action | `Glance` and `Fetch` each own one label |
| model values | every label and both slip positions, and `Pickers` |
| the box action and the tuple | the spec skeleton, with the tuple covering the control variable |
| deadlock checking | `CHECK_DEADLOCK FALSE`, and why that is the right call here |
| the universal quantifier | the property |

## The lesson in one line

Where you put the control point decides the verdict. The two-step encoding admits the foreclosing row and fails. The atomic encoding passes and is a model of a different workplace.
