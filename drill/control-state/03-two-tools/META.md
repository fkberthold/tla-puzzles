# 03 two-tools

- family: control-state
- shape: prose situation, one rule, a stated intended end state, and a second run with one change
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, three treatments of the end state on two procedures, seven runs (rc 11 / 0 / 0 on the agreed order, and rc 11 / 11 / 0 / 13 on the new hire)

## Constructs exercised

One per bullet, spelled as `drill/INVENTORY.md` field 4 spells it.

- Terminating
- deadlock (checking)
- ProcSet
- pc (PlusCal's label-tracking variable)
- pc[...] (multi-process pc)
- label-as-action encoding
- model value
- ASSUME
- IF-THEN-ELSE
- WF_v(A) (weak fairness)
- <> (eventually)

## Where each lands

| what | where |
|---|---|
| Terminating | the disjunct, and what it says that the config switch does not |
| deadlock checking | `CHECK_DEADLOCK FALSE`, measured against the disjunct |
| ProcSet | the range of the quantifier in `Terminating` and the domain of `pc` |
| the label-tracking variable | hand-rolled, with guards and updates per technician |
| label-as-action | one action per label |
| model values | labels, tools, `Nobody` |
| ASSUME | `Nobody \notin Techs`, `Rookie \in Techs` |
| IF-THEN-ELSE | `FirstTool`, `Other` |
| weak fairness and eventually | the liveness comparison run, `DayEnds` |

## The lesson in one line

`Terminating` names the one stuck state you meant. `CHECK_DEADLOCK FALSE` forgives all of them, and the translator used to make that choice for you.
