# ANSWER: completion/sets/02-twohands

## The two claims

```tla
Tracks == gaps \subseteq Orbit(Ahead(aStep, bStep))

Shared == met \subseteq Orbit(aStep) \cap Orbit(bStep)
```

## Why claim 1 holds on the real clock

After `k` ticks hand a sits at `(k * aStep) % Face` and hand b at
`(k * bStep) % Face`, so the gap between them is `(k * d) % Face` where `d` is
`Ahead(aStep, bStep)`. The gap is a third hand, and its step size is the gap
between the two step sizes.

`Orbit(d)` ranges `k` over `Hour`, which is `0..(Face - 1)`. The tick count
can run past that, and it does not matter: `(k * d) % Face` depends on `k` only
through `k % Face`, and `k % Face` is in `Hour`.

## Why claim 2 holds on the real clock

When the hands share an hour after `k` ticks, that hour is `(k * aStep) % Face`
and it is also `(k * bStep) % Face`. The first form puts it in `Orbit(aStep)`
and the second puts it in `Orbit(bStep)`, so it is in both. The same
`k % Face` argument covers the range of `k`.

## Why neither claim is an equality

Both sets grow as the clock runs, so at every state before the walk closes
they are proper subsets. Writing claim 1 as `gaps = Orbit(Ahead(aStep,
bStep))` gives exit code 12 on the real clock.

Claim 2 stays a containment even after the walk closes, which is the sharper
case. With `Face = 12`, `aStep = 2` and `bStep = 3` the hands meet at hour 0
and nowhere else, while `Orbit(2) \cap Orbit(3)` is `{0, 6}`. Writing claim 2
as an equality gives exit code 12 on the real clock.

## Accepted variants

For claim 1, `gaps \in SUBSET Orbit(Ahead(aStep, bStep))` and
`\A g \in gaps : g \in Orbit(Ahead(aStep, bStep))`. Both score the reference
signature.

For claim 2, `\A h \in met : h \in Orbit(aStep) /\ h \in Orbit(bStep)` and
`met \subseteq Orbit(aStep) /\ met \subseteq Orbit(bStep)`. Both score the
reference signature.

`Ahead(bStep, aStep)` in place of `Ahead(aStep, bStep)` is not a variant. It
names the orbit of `Face - d` rather than of `d`, and those two orbits are the
same set, so it happens to score the reference signature as well. I would mark
it right and say why it works, because the reasoning that gets there is the
reasoning the item is after.

## What each machine measures

`Face = 12` throughout. Codes taken from `harness/verdict.sh`.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only |
|---|---|---|---|---|
| `TwoHands` | 0, 2169 distinct | 0 | 0 | 0 |
| `Fudge` | 12 | 0 | 12 | 0 |
| `Alone` | 12 | 0 | 0 | 12 |

With both markers still in place, all three machines report 150.

Four distinct signatures, so the three codes separate every half-right answer
from the full one. That is the whole verification contract for this item, and
it is why there are two broken machines rather than one.

The two holes separate without the vacuity trick that
`completion/sets/01-clockface` needed. Each claim is about its own carried
set, so a machine that corrupts one set leaves the other claim untouched.
`Fudge` writes a wrong gap down and records shared hours correctly, and
`Alone` does the reverse.

## Near misses, measured

| what the learner wrote | signature |
|---|---|
| claim 1 about the current gap only | 0, 0, 12 |
| claim 1 as `gaps \subseteq Hour` | 0, 0, 12 |
| claim 2 about the current meeting only | 0, 12, 0 |
| claim 2 over one hand's orbit only | 0, 12, 0 |
| claim 1 over `Orbit(aStep)` | 12, 12, 12 |

The first four all read as a weak claim rather than a wrong one, which is what
the signature table promises. The last one is wrong about the real clock, and
the 12 in the first column says so.

## Where the module comes from

`reading/sets/01-clockface` is the one-hand version of this machine, published
at <https://fkberthold.github.io/tla-puzzles/reading/sets/>. Its `Walked` and
`Closes` are on that page, and neither is a claim this item asks for.
