# ANSWER: completion/sets/01-clockface

## The two claims

```tla
Walked == seen \subseteq Orbit(step)

Closes == (pos = 0 /\ seen # {0}) => seen = Orbit(step)
```

## Why claim 1 holds on the real clock

`Orbit(s)` is the set of `(k * s) % Face` over `k \in 0..(Face - 1)`, and that
is closed under adding `s`. The hand starts at 0, which is `k = 0`, and every
tick adds `step` with `step` held fixed. So `pos` is always in `Orbit(step)`,
and `seen` only ever gains the `pos` it just reached.

## Why claim 2 holds on the real clock

`Orbit(step)` is the cyclic subgroup that `step` generates, so walking it by
`step` visits all of it before returning to 0. The guard `seen # {0}` is what
keeps the initial state out: at `Init` the hand is at 0 with `seen = {0}` and
nothing has been walked yet.

Dropping that guard gives exit code 12 on `ClockFace` itself, for any `step`
whose orbit is larger than `{0}`.

## Accepted variants

`seen \in SUBSET Orbit(step)` for claim 1. `\A h \in seen : h \in
Orbit(step)` as well.

For claim 2, `(pos = 0 /\ seen # {0}) => (seen \subseteq Orbit(step) /\
Orbit(step) \subseteq seen)` is the same statement spelled out. The
implication is not optional: `seen = Orbit(step)` unguarded is false at
`Init`.

## What each machine measures

Face = 12 throughout. Taken from `harness/verdict.sh`.

| machine | reference answer | both `TRUE` | claim 1 only | claim 2 only |
|---|---|---|---|---|
| `ClockFace` | 0, 141 distinct | 0 | 0 | 0 |
| `Stray` | 12 | 0 | 12 | 0 |
| `Skip` | 12 | 0 | 0 | 12 |

Four distinct signatures, so the three codes separate every half-right answer
from the full one. That is the whole verification contract for this item, and
it is why there are two broken machines rather than one.

`Stray` is the machine that makes claim 1 necessary. An earlier draft used a
mutant whose step size drifted, and a correct claim 2 caught that one on its
own, so `Walked == TRUE` scored the reference signature. `Stray` closes that
by halting before the hand returns to hour 0, which makes claim 2 vacuous and
leaves claim 1 as the only thing that can fire.

## Where the module comes from

`reading/sets/01-clockface` is the same machine with its properties intact, and
it is published at
<https://fkberthold.github.io/tla-puzzles/reading/sets/>. `Walked` and `Closes`
are on that page as written above. The reading item also carries `OrderIsSize`
and `Divides`, which are left out of this item on purpose: both are true for
every `step` and `Face`, so no broken machine can refute them and TLC cannot
tell a correct one from `TRUE`.
