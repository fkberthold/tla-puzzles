# 05 crane-and-riggers

- family: control-state
- shape: prose situation with two kinds of process, one rule, a four-row behaviour table with one foreclosing row, and a closing question about how many control variables
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, a variable per kind (rc 0, 12 states) and one `pc` over the union of process identities (rc 0, 12 states), plus the site-wide phase (3 states, rule inexpressible) and the unguarded lift (rc 12)

## Constructs exercised

Named as `drill/INVENTORY.md` field 4 writes them.

| id | construct | where |
|---|---|---|
| K054 | `pc[...]` (multi-process pc) | `rig[r]`, and `pc[r]` in the union encoding |
| K089 | ProcSet | `Riggers \cup {TheCrane}` in the union encoding, and why hand-written TLA+ does not need it |
| K036 | `pc` (PlusCal's label-tracking variable) | hand-rolled, in two shapes |
| K090 | label-as-action encoding | every action owns one label transition |
| K038 | `\E` (existential quantifier, "exists") | `Lift`'s "somebody has rigged" |
| K037 | `\A` (universal quantifier, "forall") | `Lift`'s "nobody is still at it", and the rule |
| K009 | Implication | the rule |
| K002 | IF-THEN-ELSE | `Init` in the union encoding |
| K041 | model value | labels, `TheCrane` |
| K042 | set of model values | `Riggers` |
| K040 | ASSUME | `TheCrane \notin Riggers` |

## The lesson in one line

Each kind of process has its own label set, and the translator's single `pc` over a union is one way to draw that, not the only one. By hand, a variable per kind reads better and costs the same.
