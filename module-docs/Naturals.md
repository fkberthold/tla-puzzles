# `Naturals`

Standard library. Brings the natural numbers `0, 1, 2, ...` and arithmetic.

```tla
EXTENDS Naturals
```

`Naturals` is a strict subset of `Integers` — same operators, but `Nat` is non-negative. If you need negatives, use `Integers` instead.

## Operators

Same as [`Integers`](Integers.md): `+ - * \div % ^`, `<` `<=` `>` `>=`, `..`. The semantics are identical for non-negative arguments.

## Special set

`Nat` — the set of natural numbers `{0, 1, 2, ...}` (infinite; bound your state with `..` for TLC).

## When to choose `Naturals` over `Integers`

- The spec only ever uses non-negative quantities (counts, queue lengths, sizes).
- You want the type to document "this never goes negative."
- You want the slightly leaner module if you're not extending other things.

In practice, most curriculum specs use `Integers` because `..` works there too and arithmetic stays valid through subtractions.

## First introduced

Tier 3 (T26+) when puzzles start using pure TLA+ without PlusCal — many use `Naturals` for the explicit non-negative count semantics.
