# 05 crane-and-riggers

- family: control-state
- shape: prose situation with two kinds of process, one rule, a four-row behaviour table with one foreclosing row, and a closing question about how many control variables
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, a variable per kind (rc 0, 12 states) and one `pc` over the union of process identities (rc 0, 12 states), plus the site-wide phase (3 states, rule inexpressible) and the unguarded lift (rc 12)

## Constructs exercised

One per bullet, spelled as `drill/INVENTORY.md` field 4 spells it.

- pc[...] (multi-process pc)
- ProcSet
- pc (PlusCal's label-tracking variable)
- label-as-action encoding
- \E (existential quantifier, "exists")
- \A (universal quantifier, "forall")
- Implication
- IF-THEN-ELSE
- model value
- set of model values
- ASSUME

## Where each lands

| what | where |
|---|---|
| the multi-process form | `rig[r]`, and `pc[r]` in the union encoding |
| ProcSet | `Riggers \cup {TheCrane}` in the union encoding, and why hand-written TLA+ does not need it |
| the label-tracking variable | hand-rolled, in two shapes |
| label-as-action | every action owns one label transition |
| the existential | `Lift`'s "somebody has rigged" |
| the universal | `Lift`'s "nobody is still at it", and the rule |
| implication | the rule |
| IF-THEN-ELSE | `Init` in the union encoding |
| model values | labels, `TheCrane`, `Riggers` |
| ASSUME | `TheCrane \notin Riggers` |

## The lesson in one line

Each kind of process has its own label set, and the translator's single `pc` over a union is one way to draw that, not the only one. By hand, a variable per kind reads better and costs the same.
