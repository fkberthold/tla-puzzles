# META

- **shape**: two missing invariants in a given machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, minus the two claim bodies
- **time**: 10 to 20 minutes
- **verify**: `bash completion/verify-item.sh completion/modules/01-tiles`
- **reading sibling**: `reading/modules/03-fences`, varied rather than reused

## What changed from the reading sibling, and why the page is a hint

Both this item and `03-fences` instantiate one small library more than once and
state their claims through the instances, so the vocabulary carries straight
across: `INSTANCE`, a named instance, `!`, `WITH`, `LOCAL`, and an interval
clipped to a wall. Past that they share nothing.

`03-fences` has two gates cutting one static interval into three pieces, and its
claims are about coverage and a count at a single instant. This item has one tile
sliding along and a history variable that grows, so both facts are about what a
run has accumulated rather than about how one state decomposes. `Covered`,
`Counted` and `MidEmptyWhenAdjacent` give a reader nothing here. None of them
mentions anything like a laid set, and the published page's degenerate `Mid`
instance has no counterpart. I think the page tells a reader how to reach into an
instance, and not what to say with it.

One piece of mechanism is taken over on purpose. `03-fences` measured that the
`IF` clamp in `Count` is load-bearing rather than defensive, and `Tile!Cells`
clips the same way with a set filter instead of an `IF`.

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are what
the two claim bodies, their accepted variants, and the apparatus around them use.

- `INSTANCE`
- `named instance`
- `! (namespace lookup)`
- `INSTANCE ... WITH (<- constant substitution)`
- `partial parameterization`
- `LOCAL (definition modifier)`
- `Set relational and algebraic operators`
- `Implication`
- `\A (universal quantifier, "forall")`
- `Cardinality`

## Roles

| id | construct | role |
|---|---|---|
| K100 | `INSTANCE` | shown, the `Tile` library twice over |
| K102 | `named instance` | shown, `Here` and `Whole` |
| K103 | `! (namespace lookup)` | both claims, and shown in `Lay` |
| K104 | `INSTANCE ... WITH` | shown, `At` and `Size` take variables |
| K105 | `partial parameterization` | shown, `Wall` is out of both WITH clauses |
| K099 | `LOCAL` | shown, and `Far` does not cross the instance |
| K013 | `Set relational and algebraic operators` | claim 1, and `\cup` is shown |
| K009 | `Implication` | claim 2, absent from the shown code |
| K037 | `\A (universal quantifier, "forall")` | variant of claim 1, not shown |
| K014 | `Cardinality` | variant of claim 2, and shown in `Tile!Count` |

## Where the no-telegraph rule holds and where it does not

`tla-rmuf` asks that the shown code not carry the operator a hole needs. Claim 1
needs `\cap`, and no shown file has one. An earlier draft defined `Tile!Cells` as
`(At..Far) \cap (1..Wall)`, which hands claim 1 its operator by pattern match, so
`Cells` is a set filter now. Same clipped set, different operator, and the same
fix the reference made to its `TypeOK`.

At INVENTORY-row granularity the rule still reads as violated, because K013
covers `\cup` as well and `Lay` shows `laid \cup Here!Cells`. That is the finding
the reference already recorded against the gate rather than against the item, and
this item inherits it unchanged.

Two smaller leaks, named rather than fixed. `laid = {}` in every `Init` shows the
empty-set literal claim 1 compares against. And `TypeOK` puts `laid` and
`1..Wall` in one formula, which is the pair claim 2 relates. I think both are
tolerable, because in each case what is shown is the typing, and what the hole
asks for is a relation the typing does not state. Nothing shown says anything at
all about `laid` against `Here!Cells`, which is claim 1's real distinction.

## Measured asides

Worth having for whoever writes item 02 in this family.

`LOCAL` holds across the instance. Replacing claim 1 with `Here!Far > 0` gives rc
150 and "Unknown operator: `Far'.", so only the clipped `Cells` and the clamped
`Count` cross the boundary.

`03-fences` found that an `ASSUME` inside a library guards nothing once anybody
instantiates it. That is a real trap and a bad hole, because the run is rc 0
either way and no broken machine can refute it. `Tile` carries no `ASSUME` for
that reason, and the only one in the item is on `Wall` in the root module, where
it is checked.
