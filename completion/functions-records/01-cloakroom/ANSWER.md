# ANSWER: completion/functions-records/01-cloakroom

## The two claims

```tla
OnePerPeg == \A a, b \in Coat : a # b => hangs[a] # hangs[b]

FewMoved == Cardinality({c \in Coat : hangs[c] # Own[c]}) <= 2 * swaps
```

## Why claim 1 holds on the real cloakroom

`hangs` starts as `Own`, which gives every coat its own peg, so no two coats
share one. A swap exchanges the pegs of two coats and touches nothing else,
so the four pegs in use before a swap are the four in use after it. An
injective function on a four-coat set stays injective.

## Why claim 2 holds on the real cloakroom

One swap can move at most two coats away from the peg they came in on,
because it writes two entries. So the count of displaced coats climbs by at
most 2 a swap, and it starts at 0.

The bound is tight rather than slack, which is what makes it a claim worth
writing. One swap displaces exactly 2 coats, and two disjoint swaps displace
exactly 4.

`Threeway` is what makes claim 2 necessary. It writes three entries and books
one swap, so three coats are displaced with the tally at 1. It leaves claim 1
alone, since rotating three coats round their own three pegs is still a
permutation of the rail.

`Doubled` fails claim 1 and survives claim 2. It writes one entry a move, so
the displaced count climbs by at most 1 and never reaches the bound.

## Accepted variants

For claim 1, `{hangs[c] : c \in Coat} = Peg` says the same thing as an image
equality, and so does the surjective form
`\A p \in Peg : \E c \in Coat : hangs[c] = p`, since there are as many pegs as
coats. Any form that rules out two coats on one peg counts.

For claim 2, `hangs[c] # c` in place of `hangs[c] # Own[c]`, since `Own` is
the identity on `1..4`. Writing the set as a filter over `DOMAIN hangs`
rather than over `Coat` is also the same set.

The image form for claim 1 and the `DOMAIN`-filter form for claim 2 together
score 0, 12, 12, measured.

## What each machine measures

Limit = 3 throughout, from the three .cfg files. Every cell below is a
`completion/verify-item.sh` run.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only |
|---|---|---|---|---|
| `Cloakroom` | 0, 31 distinct | 0 | 0 | 0 |
| `Doubled` | 12 | 0 | 12 | 0 |
| `Threeway` | 12 | 0 | 0 | 12 |

Unfilled, all three report 150. That gives five distinct signatures, so the
three codes separate every half-right answer from the full one. Neither broken
machine catches the other's claim, which is the measured point of the table.

## Two things measured about the claims themselves

The bound in claim 2 is attained. Tightening it to
`swaps # 0 => Cardinality(...) < 2 * swaps` gives exit code 12 on `Cloakroom`
at 2 distinct states, so the reference answer sits exactly on the edge of what
the machine can do.

Claim 1 holds on `Threeway` and claim 2 holds on `Doubled`, both at exit code
0, which is the pair of cells that keeps the two holes independent.

## Where the module comes from

`reading/functions-records/01-matching` is the sibling, published at
<https://fkberthold.github.io/tla-puzzles/reading/functions-records/>. It
carries the same state shape, a function from a four-element set to itself
moved by `EXCEPT`, and its moves pair and unpair nodes rather than swap them.

Both of its properties are false here, measured rather than argued. Its
`Involution`, written `\A c \in Coat : hangs[hangs[c]] = c`, gives exit code
12 on `Cloakroom` at 9 distinct states. Its `EvenlyPaired`, the parity of the
displaced count, gives 12 at 9 distinct states as well. Two swaps reach a
three-coat rotation, which is neither an involution nor an even displacement.
So the page gives you the vocabulary and none of the answer.
