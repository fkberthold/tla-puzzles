# META

- **shape**: two missing invariants in a given machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, minus the two claim bodies
- **time**: 10 to 20 minutes
- **verify**: `bash completion/verify-item.sh completion/state-space/01-canvass`
- **reading sibling**: `reading/state-space/02-tickets`, varied

## What changed from the reading sibling, and why the page is a hint

Tickets has a counter that only climbs, a `Nil` model value, a set of model
values and a `CONSTRAINT` that buys termination. All four are here. What
changed is the mechanism underneath them. Tickets runs a queue discipline,
where a ticket is taken once and then served in order, so its facts are about
the order of two counters. Here a door can be knocked on again and the new
answer overwrites the old one, and a separate set accumulates everything ever
heard. That turns the statable facts into relations between a per-door record
and an accumulator, which is a different kind of claim from an ordering.

The page is a hint rather than a key because none of tickets' five invariants
is either claim here. `Issued`, `NoSkip` and `Distinct` are all about ticket
numbers against the counter, and there is no counterpart to them in this
machine. What the page gives is how the configuration surface fits together,
which is the part worth lifting: where `Nil` comes from, what a set of model
values looks like in a `.cfg`, and why the `CONSTRAINT` line is there at all.

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the two claim bodies and their accepted variants use.

- `\A (universal quantifier, "forall")`
- `Implication`
- `Equality and inequality`
- `Set relational and algebraic operators`
- `Cardinality`
- `Integers`

## Roles

| id | construct | role |
|---|---|---|
| K037 | `\A (universal quantifier, "forall")` | claim 1, absent from the shown code |
| K009 | `Implication` | claim 1, absent from the shown code |
| K003 | `Equality and inequality` | claim 1, absent from the shown code |
| K014 | `Cardinality` | claim 2, absent from the shown code |
| K005 | `Integers` | claim 2's comparison, absent from the shown code |
| K013 | `Set relational and algebraic operators` | both claims, and `\in` and `\cup` are shown |

## Where the no-telegraph rule lands

Five of the six rows are clean, and that is measured rather than argued.
`grep` over `work/*.tla` and `work/*.cfg` finds no `=>`, no `Cardinality`, no
`<=` or `=<`, no `\A` and no `#`. The shown code states no relation between
`noted` and `heard`, and none between `heard` and `calls`.

K013 is the one row that reads as violated, and it reads that way for the
reference item's reason. `TypeOK` shows `\in`, `Answer \cup {Nil}` shows
`\cup`, and the row covers `\in`, `\notin`, `\subseteq`, `\union`,
`\intersect` and `\` together. So the honest statement is narrower than the
row: nothing in the shown code applies a set operator to `heard` against
anything, and a gate checking per row will flag this item while one checking
per operator will not.

K005 needs the same care in the other direction. The row is about integer
literals and arithmetic, the shown code has `calls + 1` and `0..Limit`, and
claim 2 needs a comparison. `Bounded` is written as `calls \in 0..Limit`
rather than `calls <= Limit` on purpose, and that is the choice that keeps the
comparison off the page.

## The deadlock keyword, and why it is not here

Both state-space reading models carry `CHECK_DEADLOCK TRUE` and discuss what
it covers. This item cannot. `completion/verify-item.sh` calls
`harness/verdict.sh` without `--check-deadlock`, and `verdict.sh` refuses the
run at 99 when the `.cfg` asks for a check the command line would discard.
Measured on a copy of `Canvass.cfg` with the keyword appended: rc 99,
`CHECK_DID_NOT_RUN`. So a completion item in this family inherits the
`CONSTRAINT` from tickets and leaves the deadlock check behind.
