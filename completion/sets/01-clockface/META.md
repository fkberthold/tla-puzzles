# META

- **shape**: two missing invariants in a given machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, minus the two claim bodies
- **time**: 10 to 20 minutes
- **verify**: `bash completion/verify-item.sh completion/sets/01-clockface`
- **source module**: `reading/sets/01-clockface`, properties removed

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the two claim bodies and their accepted variants use.

- `Set relational and algebraic operators`
- `Implication`
- `SUBSET (powerset)`
- `\A (universal quantifier, "forall")`

## Roles

| id | construct | role |
|---|---|---|
| K013 | `Set relational and algebraic operators` | claim 1, and `\cup` is shown |
| K009 | `Implication` | claim 2, absent from the shown code |
| K017 | `SUBSET (powerset)` | variant of claim 1, and shown in `TypeOK` |
| K037 | `\A (universal quantifier, "forall")` | variant of claim 1, not shown |

## What the no-telegraph rule caught, and where it does not reach

`tla-rmuf`'s RED asks that the shown code not contain the construct the hole
exercises. The first draft gave `TypeOK` as `seen \subseteq Hour`, which hands
claim 1 its shape by pattern match. `TypeOK` now reads `seen \in SUBSET Hour`,
which types `seen` the same way and spells it with a different operator.

At INVENTORY-row granularity the rule still reads as violated for claim 1,
because K013 covers `\cup` as well as `\subseteq` and `ClockFace.tla` shows
`seen \cup {pos'}`. The honest statement is narrower than the row: `\subseteq`
does not appear in any shown file, and K013 does. So a gate that checks this
rule per row will flag this item, and a gate that checks it per operator will
not. That is a finding for the gate rather than a defect in the item, and it
is recorded on `tla-rmuf`.

Claim 1's real distinction is not an operator at all. It is the relation
between `seen` and `Orbit(step)`, and nothing in the shown code states any
relation between them.
