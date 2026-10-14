# META

- **shape**: two missing invariants in a given machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, minus the two claim bodies
- **time**: 10 to 20 minutes
- **verify**: `bash completion/verify-item.sh completion/core/01-shutters`
- **reading sibling**: `reading/core/03-cups`, varied rather than reused

## What changed from the sibling, and why its page is a hint

Cups flips two cups with one cup between them, so the odd places and the even
places never mix, and its two invariants are the parity of each class on its
own. This item moves the catch to a neighboring pair and adds a tally of how
many times one has been worked. Those two changes retire both of the sibling's
facts and put two different ones in their place: the parity of the whole open
count, and the parity of the tally on coming back to all shut. Cups' own
invariant, written here as `Cardinality({i \in open : i % 2 = 1}) % 2 = 0`,
reports exit code 12 on `Shutters` at 2 distinct states. So a learner who
opens the published page finds the idea that flips are worth counting modulo
something, and finds neither claim.

The tally is the piece that makes the second hole possible at all. Without
it, the reachable sets are exactly the even subsets of `1..5`, and claim 1 is
then the only state invariant there is to state.

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the two claim bodies and their accepted variants use.

- `Cardinality`
- `Integers`
- `Implication`
- `Equality and inequality`
- `Sets`
- `\E (existential quantifier, "exists")`

## Roles

| id | construct | role |
|---|---|---|
| K014 | `Cardinality` | claim 1, absent from the shown code |
| K005 | `Integers` | `%` in both claims, absent from the shown code |
| K009 | `Implication` | claim 2, absent from the shown code |
| K003 | `Equality and inequality` | both claims, and `=` is shown in `Init` |
| K012 | `Sets` | `open = {}` in claim 2, and a variant of claim 1 |
| K038 | `\E (existential quantifier, "exists")` | a variant of claim 1, and shown in `Next` |

## What the no-telegraph rule caught, and where it does not reach

`tla-rmuf`'s RED asks that the shown code not contain the operator the hole
needs. Measured over the four modules and three configs the learner sees,
`grep -n 'Cardinality\|%\|=>\|<=\|\A '` returns nothing. `Looped` is where
this nearly went wrong: the loop catch reads naturally as `{i, (i % 5) + 1}`,
which would have put claim 1's modulus in front of the learner. It is written
`IF i = 5 THEN {5, 1} ELSE {i, i + 1}` instead, which builds the same five
pairs out of operators neither claim uses.

Two places the rule still reads as bent, both narrower than they look.

`Init` gives `open = {}`, and claim 2's antecedent needs `open = {}`. The
antecedent is the machine's own starting configuration, so there is nowhere
else for it to come from. What claim 2 actually turns on is the implication
and the parity of the tally, and neither is shown.

At INVENTORY-row granularity K003 is shown, since `Init` writes `open = {}`
and both claims use `=` or `#`. `grep -n '#'` over the shown files returns
nothing, so the inequality half of that row is absent and the row is still
too coarse to say so. That is the same finding
`completion/sets/01-clockface/META.md` records against K013.
