# USES: sequences/02-josephus

Subject: People standing in a circle, counted round, where every
second one leaves until a single survivor is left. Where that survivor
stands is named twice over, by a recurrence and by a binary trick.

rc: 0

## What the properties rest on

rc 0 over 28 distinct states, 28 generated, depth 7. The 28 is
1 + 2 + ... + 7. `Init` picks a circle size and no action ever changes
it, so the run is seven separate chains. A chain for size k is k states
long, because one place leaves on every step. The search is complete
because `size` is fixed by the initial predicate and `ring` only ever
gets shorter.

`Recurrence` and `Binary` say nothing at 21 of those 28 states. Both
are implications guarded by `Len(ring) = 1`, which holds once per
chain. So TLC is checking seven facts, and the guard is what makes the
other 21 states free. That's the shape to notice before any of the
arithmetic, a claim about the last state written as an invariant.

The seven facts are the same seven, twice over. `Survivor` is a
recurrence and `Closed` is a binary trick, the two look unrelated, and
neither invariant compares them to each other. They agree because each
one agrees with `ring`, which simulates the count and knows nothing
about either formula.

The `+ 1` inside `Survivor`'s modulus is where to push. Move it
outside, to `(Survivor(k - 1) % k) + 1`, and the run gives rc 12 with
`Recurrence` named, at `size = 2`. Those parentheses are load-bearing
rather than decorative. `Survivor(k - 1) % k + 1` isn't a weaker spec,
it's a parse error, because TLA+ gives `%` and `+` conflicting
precedence and won't guess between them.

`Closed` breaks on its recursive argument. Write
`Pow2Below((k - 1) \div 2)` and the run gives rc 12 with `Binary`
named, at `size = 4`. That's the first size where a halving short by
one lands on the wrong power of two.

`Shrinks` is the obligation that watches every step rather than the
last one. Drop one `Tail` from `Eliminate`, so the place at the front
goes to the back and nobody leaves. The run then gives rc 13 against
`Shrinks` at `size = 2`. Both invariants stay quiet there, because a
circle that never shortens never reaches the state they talk about.

Last, the reason the front place goes to the back at all. Keep it at
the front instead, with `<<Head(ring)>> \o Tail(Tail(ring))`. The count
then restarts from the same place every time, rather than carrying on
from the one who just left. That gives rc 12 against `Recurrence` at
`size = 3`, the smallest circle where the two rules part ways.

## Constructs

- Sequences
- Sequence module operators
- RECURSIVE
- IF-THEN-ELSE
- Integers
- Implication
- function literal
- action property
- Invariant (as a TLA+ operator, checked at every state)

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Equality and inequality
- Bullet-point boolean notation
- BOOLEAN and integer interval as sets
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- ASSUME
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- ' (prime, next-state value)
- [P]_x (box action formula)
- deadlock (checking)
- PROPERTY (TLC model config: register a temporal property)
