# 03 two-tools

- family: control-state
- shape: prose situation, one rule, a stated intended end state, and a second run with one change
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, three treatments of the end state on two procedures, six runs (rc 11 / 0 / 0 on the agreed order, and rc 11 / 0 / 13 on the new hire)

## Constructs exercised

Named as `drill/INVENTORY.md` field 4 writes them.

| id | construct | where |
|---|---|---|
| K092 | Terminating | the disjunct, and what it says that the config switch does not |
| K059 | deadlock (checking) | `CHECK_DEADLOCK FALSE`, measured against the disjunct |
| K089 | ProcSet | the range of the `\A` in `Terminating` and the domain of `pc` |
| K036 | `pc` (PlusCal's label-tracking variable) | hand-rolled |
| K054 | `pc[...]` (multi-process pc) | guards and updates |
| K090 | label-as-action encoding | one action per label |
| K041 | model value | labels, tools, `Nobody` |
| K040 | ASSUME | `Nobody \notin Techs`, `Rookie \in Techs` |
| K002 | IF-THEN-ELSE | `FirstTool`, `Other` |
| K095 | `WF_v(A)` (weak fairness) | the liveness comparison run |
| K067 | `<>` (eventually) | `DayEnds` |

## The lesson in one line

`Terminating` names the one stuck state you meant. `CHECK_DEADLOCK FALSE` forgives all of them, and the translator used to make that choice for you.
