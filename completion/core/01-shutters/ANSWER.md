# ANSWER: completion/core/01-shutters

## The two claims

```tla
EvenOpen == Cardinality(open) % 2 = 0

ShutEvenly == (open = {} /\ pulls # 0) => pulls % 2 = 0
```

## Why claim 1 holds on the real shopfront

Every catch flips both shutters of its pair, so one pull moves the open count
by +2, 0 or -2. The shop starts with nothing open, which is even, and no step
can change that parity.

## Why claim 2 holds on the real shopfront

A shutter is back where it started only if it has been flipped an even number
of times. Work through the row from the end. Shutter 1 is flipped by catch 1
and by nothing else, so catch 1 has been worked an even number of times.
Shutter 2 is flipped by catch 1 and catch 2, and catch 1's count is already
even, so catch 2's is even too. The same step walks the row to catch 4. Every
catch has been worked an even number of times, so the tally is even.

That argument is about the shape of the row rather than about parity in
general, which is what `Looped` is there to show. Closing the row into a loop
of five gives the catches a cycle, and working each of the five once flips
every shutter exactly twice. The shopfront is back to all shut with the tally
at 5.

`Single` fails claim 1 and survives claim 2, for the same end-of-the-row
reason: coming back to all shut still needs every shutter flipped an even
number of times, and a pull that flips one shutter contributes one flip, so
the tally is even.

The guard `pulls # 0` keeps the initial state out. All shut with nothing
worked yet is not a return.

## Accepted variants

For claim 1, `Cardinality(open) \in {0, 2, 4}` says the same thing at this
size, and so does `\E k \in 0..2 : Cardinality(open) = 2 * k`.

For claim 2, the two conjuncts of the antecedent in either order. For the
consequent, `(pulls \div 2) * 2 = pulls` is the same test. The implication is
not optional: a bare `pulls % 2 = 0` is false the moment a catch is worked
once.

Both variants together score 0, 12, 12, measured. Mind the parentheses in the
`\div` form. Written `pulls \div 2 * 2 = pulls` it reports 150 on all three
machines, because `\div` and `*` sit at the same precedence and TLA+ will not
pick an order for you. That is a parse error reading as an unfilled marker,
and it is the one way a correct idea scores the bottom row of the table.

## What each machine measures

Limit = 6 throughout, from the three .cfg files. Every cell below is a
`completion/verify-item.sh` run.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only |
|---|---|---|---|---|
| `Shutters` | 0, 44 distinct | 0 | 0 | 0 |
| `Single` | 12 | 0 | 12 | 0 |
| `Looped` | 12 | 0 | 0 | 12 |

Unfilled, all three report 150. That gives five distinct signatures, so the
three codes separate every half-right answer from the full one. It is the
whole verification contract for this item, and it is why there are two broken
machines rather than one.

`Single` is the machine that makes claim 1 necessary, and `Looped` is the one
that makes claim 2 necessary. Neither catches the other's claim, which is the
measured point of the table.

## Two things measured about the claims themselves

Claim 2 is not vacuous on the real shopfront. Replacing its body with
`~(open = {} /\ pulls # 0)` gives exit code 12 on `Shutters` at 6 distinct
states, so the antecedent is reached rather than merely guarded against.

Claim 1 is checked on `Looped` too and holds there, since a loop catch still
flips a pair. That is the only reason `Looped` reports 12 for claim 2 alone.

## Where the module comes from

`reading/core/03-cups` is the sibling, published at
<https://fkberthold.github.io/tla-puzzles/reading/core/>. It flips two cups
with one cup between them, and its two parity invariants are about the odd
places and the even places separately.

Those invariants are false here, measured rather than argued. Claim 1 set to
the cups shape, `Cardinality({i \in open : i % 2 = 1}) % 2 = 0`, gives exit
code 12 on `Shutters` at 2 distinct states. Neighboring flips mix the two
place classes, which is the whole difference between the two machines. So the
page tells you flips are worth counting modulo something, and it hands over
neither claim.
