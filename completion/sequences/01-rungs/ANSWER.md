# ANSWER: completion/sequences/01-rungs

## The two claims

```tla
Ladder == rungs = 0..(Cardinality(rungs) - 1)

Standing ==
  \A i \in 0..Len(text) : Depth(SubSeq(text, 1, i)) \in rungs
```

## Why claim 1 holds on the real text

One character goes on at a time, and each one moves the depth by exactly one.
The text starts at depth 0, so the depths it reaches run from 0 up to the
deepest without a break. A set of `n` whole numbers that runs from 0 with no
gap is `0..(n - 1)`, which is what the claim says.

## Why claim 2 holds on the real text

Every prefix of `text` was the whole text at an earlier state, because the
machine only ever appends. At that state `open` was that prefix's depth, and
both actions put `open'` into `rungs` as they arrived. `rungs` never shrinks on
the real text, so the depth is still in it.

The `i = 0` case is the empty prefix at depth 0, and `Init` seeds `rungs` with
it.

## Accepted variants

Claim 1 says `rungs` is downward closed, and the interval form is only one way
to say it. Both of these score the reference signature:

```tla
\A d \in rungs : 0..d \subseteq rungs

0 \in rungs /\ \A d \in rungs : d > 0 => d - 1 \in rungs
```

For claim 2, the set-map form scores the reference signature too:

```tla
{Depth(SubSeq(text, 1, i)) : i \in 0..Len(text)} \subseteq rungs
```

Claim 2 with the quantifier over `1..Len(text)` also scores the reference
signature. The `i = 0` case never fires, since 0 is in `rungs` on all three
machines. I would mark it right and point at what it left out, because the
omission is harmless here and would not be on a machine that could drop 0.

## What each machine measures

`Limit = 6` throughout. Codes taken from `harness/verdict.sh`.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only |
|---|---|---|---|---|
| `Rungs` | 0, 43 distinct | 0 | 0 | 0 |
| `Topped` | 12 | 0 | 12 | 0 |
| `Shed` | 12 | 0 | 0 | 12 |

With both markers still in place, all three machines report 150.

Four distinct signatures, so the three codes separate every half-right answer
from the full one.

## The mutant that did not work, and why `Shed` replaced it

The first draft's second machine was `Frozen`, which wrote no depth down after
the first, leaving `rungs` at `{0}` forever. It scored the reference signature
against `open \in rungs`, which is a far weaker claim than claim 2 and says
nothing about any prefix. So claim 2 was unchecked at the altitude the item
asks for, which is the same failure `completion/sets/01-clockface` found in its
own first draft.

`Shed` closes it. It keeps `rungs` equal to `0..open` at every state, so
`open \in rungs` holds everywhere on it while an earlier depth has gone. The
measurement: claim 1 right and claim 2 written as `open \in rungs` gives
0, 12, 0 against `Rungs`, `Topped` and `Shed`, which reads as a weak claim 2.

`Shed` also keeps claim 1 true of itself, which is what the one-hole-per-mutant
rule needs. `rungs` is `0..open` at every state, and that is downward closed.

## Near misses, measured

| what the learner wrote | signature |
|---|---|
| claim 1 as `0 \in rungs` | 0, 0, 12 |
| claim 2 as `open \in rungs` | 0, 12, 0 |

## Where the module comes from

`reading/sequences/01-brackets` is the same text-building machine with a plain
counter and no `rungs`, published at
<https://fkberthold.github.io/tla-puzzles/reading/sequences/>. Its `Surplus`
and `PrefixSound` are on that page, and this item asks for neither.
`PrefixSound` does show the quantify-over-prefixes shape that claim 2 needs,
so the page is worth reading first.
