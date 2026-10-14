# META

- **shape**: two missing invariants in a given machine, checked against one correct machine and two broken ones
- **TLA+ in the prompt**: the whole machine, minus the two claim bodies
- **time**: 15 to 25 minutes
- **verify**: `bash completion/verify-item.sh completion/sequences/01-rungs`
- **source module**: `reading/sequences/01-brackets`, varied rather than reused

## What changed from the reading sibling, and why the page is a hint

`reading/sequences/01-brackets` builds a bracket string one character at a
time and carries `open`, a counter of how many brackets are still open. This
item keeps that machine and adds `rungs`, the set of depths the string has
stood at. The counter stays, so the mechanism change is one carried set rather
than a new machine.

Both facts are about `rungs`, and neither is on the page. The page's `Surplus`
ties `open` to the text's own bracket counts, and its `PrefixSound` says no
prefix closes more than it opens. Claim 1 here is that the depths reached form
an unbroken run from 0, which is a fact about how a one-step-at-a-time walk
moves. Claim 2 is that nothing the walk passed through got left out.

`PrefixSound` does hand over the quantify-over-prefixes shape that claim 2
needs, and that is the strongest hint the page gives. I think that is the right
side of the line: the shape is the vocabulary, and what claim 2 asserts inside
it is not on the page.

Frank chose vary over reuse on 2026-10-13.

## Constructs

One per bullet, named as `drill/INVENTORY.md` field 4 writes them. These are
what the two claim bodies and their accepted variants use.

- `Cardinality`
- `BOOLEAN and integer interval as sets`
- `Sequence module operators`
- `\A (universal quantifier, "forall")`
- `Set relational and algebraic operators`
- `Set map`
- `Implication`

## Roles

| id | construct | role |
|---|---|---|
| K014 | `Cardinality` | claim 1, absent from every shown file |
| K015 | `BOOLEAN and integer interval as sets` | both claims, and shown in `TypeOK` |
| K011 | `Sequence module operators` | claim 2 needs `SubSeq`, which no shown file has |
| K037 | `\A (universal quantifier, "forall")` | claim 2, absent from every shown file |
| K013 | `Set relational and algebraic operators` | variants of both claims |
| K018 | `Set map` | variant of claim 2 |
| K009 | `Implication` | variant of claim 1 |

## No telegraph, and where it does not reach

At operator granularity this item holds on the operators that matter.
`Cardinality`, `SubSeq`, `\A` and `\subseteq` appear in no file the learner
sees. `TypeOK` types the text as `text \in Seq(Mark)` rather than with a
quantifier over its positions, which is where the reading sibling puts a `\A`
and where this item would otherwise hand claim 2 its shape.

`Seq(Mark)` as a typing is checked rather than decorative. A probe that
appends a character outside `Mark` reports exit code 12 against it.

Two rows are shown and cannot sensibly be hidden. K015 is `0..Limit` in
`TypeOK` and `1..Len(text)` is not there, but the interval operator is
unavoidable in any machine with a bounded counter. K011 is `Len` and `Append`
in every action, and a sequences item whose machine builds a sequence cannot
avoid that row. The narrow statement for K011 is the useful one: `SubSeq` is in
no shown file.

So a gate that checks this rule per row will flag this item on K015 and K011,
the same way it flags `completion/sets/01-clockface` on K013. That is a finding
about the granularity of the gate, and `tla-rmuf` already carries it.
