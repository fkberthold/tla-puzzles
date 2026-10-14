# META

- **shape**: two missing invariants in a given machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, minus the two claim bodies
- **time**: 15 to 25 minutes
- **verify**: `bash completion/verify-item.sh completion/sets/02-twohands`
- **source module**: `reading/sets/01-clockface`, varied rather than reused

## What changed from the reading sibling, and why the page is a hint

`reading/sets/01-clockface` is one hand on a clock face, carrying the set of
hours it has landed on. This item puts a second hand on the same face with its
own step size, and carries two sets instead of one: the gaps between the hands
and the hours they have shared.

The new fact is that the gap is itself a hand. It moves by a step size neither
hand has, the gap between the two step sizes, and claim 1 is where the learner
has to say so. The published page gives the shape of a containment claim and
the `Orbit` idiom, and it gives neither claim's content. `Walked` on that page
is about one hand's own orbit, which is the thing claim 1 is not about. Frank
chose vary over reuse on 2026-10-13, and this is his own suggestion for the
sets family.

Claim 2 is a second fact rather than a second phrasing of the first. Two
carried sets is what makes the item's two broken machines separate cleanly,
and it is the one place this item is built differently from the reference.
See the ANSWER's note on the vacuity trick.

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the two claim bodies and their accepted variants use.

- `Set relational and algebraic operators`
- `SUBSET (powerset)`
- `\A (universal quantifier, "forall")`

## Roles

| id | construct | role |
|---|---|---|
| K013 | `Set relational and algebraic operators` | both claims: `\subseteq` in claim 1, `\subseteq` and `\cap` in claim 2 |
| K017 | `SUBSET (powerset)` | variant of claim 1, and shown in `TypeOK` |
| K037 | `\A (universal quantifier, "forall")` | variant of both claims, absent from every shown file |

## No telegraph, and where it does not reach

`tla-rmuf`'s RED asks that the shown code not carry the construct a hole
exercises. At operator granularity this item holds. Neither `\subseteq` nor
`\cap` appears in any file the learner sees, and `TypeOK` types both carried
sets with `\in SUBSET Hour` rather than with `\subseteq`.

At INVENTORY-row granularity it reads as violated, the same way
`completion/sets/01-clockface` does and for the same reason. K013 covers `\cup`
as well as `\subseteq` and `\cap`, and all three machines show
`gaps \cup {Ahead(aPos', bPos')}`. I left the `\cup` in. A set filter would
have accumulated the same two sets without the row, and an unidiomatic
accumulator is noise in a machine whose job is to be read. So the honest
statement is the narrow one, and a gate that checks the rule per row will flag
this item.

What a learner cannot pattern-match from the shown code is the relation
between `gaps` and `Ahead(aStep, bStep)`. Nothing shown says the gap has a
step size at all.
