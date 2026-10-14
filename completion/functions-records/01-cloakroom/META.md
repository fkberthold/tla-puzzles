# META

- **shape**: two missing invariants in a given machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, minus the two claim bodies
- **time**: 10 to 20 minutes
- **verify**: `bash completion/verify-item.sh completion/functions-records/01-cloakroom`
- **reading sibling**: `reading/functions-records/01-matching`, varied rather than reused

## What changed from the sibling, and why its page is a hint

Matching moves a function from a four-element set to itself with `EXCEPT`,
exactly as this item does, and its moves pair two unpaired nodes or unpair a
pair. The change here is that the move swaps two entries whatever they hold,
with no pairing guard, and a tally counts the swaps. That turns the state from
an involution into an arbitrary permutation, which retires both of the
sibling's facts. `Involution`, written here as
`\A c \in Coat : hangs[hangs[c]] = c`, reports exit code 12 on `Cloakroom` at
9 distinct states, and `EvenlyPaired`, the parity of the displaced count,
reports 12 at 9 as well. Two swaps reach a three-coat rotation, which is
neither.

So the published page gives a learner the vocabulary, the `EXCEPT` idiom, and
the habit of counting the displaced entries. It gives neither claim, and
copying either one off it scores a 12 on the machine it is supposed to pass.

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the two claim bodies and their accepted variants use.

- `\A (universal quantifier, "forall")`
- `Implication`
- `Equality and inequality`
- `Set filter`
- `Cardinality`
- `Integers`
- `Set map`
- `DOMAIN`

## Roles

| id | construct | role |
|---|---|---|
| K037 | `\A (universal quantifier, "forall")` | claim 1, absent from the shown code |
| K009 | `Implication` | claim 1, absent from the shown code |
| K003 | `Equality and inequality` | both claims, and `#` is shown in the guards |
| K019 | `Set filter` | claim 2, absent from the shown code |
| K014 | `Cardinality` | claim 2, absent from the shown code |
| K005 | `Integers` | `<=` and `*` in claim 2, absent from the shown code |
| K018 | `Set map` | a variant of claim 1, not shown |
| K046 | `DOMAIN` | a variant of claim 2, not shown |

`EXCEPT` (K087), `function set` (K050) and `function literal` (K047) are what
the machine is built from rather than what the holes exercise, so they are not
claimed above.

## What the no-telegraph rule caught, and where it does not reach

`tla-rmuf`'s RED asks that the shown code not contain the operator the hole
needs. This is the sharp case the authoring brief warns about, because
`EXCEPT` and `DOMAIN` turn up in almost any action over a function. Measured
over the four modules and three configs the learner sees,
`grep -n 'Cardinality\|%\|=>\|<=\|\A '` returns three lines, all of them the
`\E a, b \in Coat :` in a `Next`. So no `\A`, no implication, no
`Cardinality`, no `<=`, and no set filter. `DOMAIN` is absent as well, which
is why the `DOMAIN`-filter form of claim 2 counts as a variant rather than as
a hand-out.

Two places the rule reads as bent, both narrower than they look.

The guards show `a # b`, and claim 1 is `a # b => hangs[a] # hangs[b]`. The
shown half is the move's own precondition, and what claim 1 turns on is the
quantifier and the implication over the pair. Neither is shown. I think this
is the same shape as the K013 finding in
`completion/sets/01-clockface/META.md` rather than a new one: the operator
appears, the claim it belongs to does not.

`Own` is given and shown in `Init`, and claim 2 compares against it. That is
the machine's starting configuration, so it has nowhere else to come from, and
the accepted variants treat `hangs[c] # c` as the same test.
