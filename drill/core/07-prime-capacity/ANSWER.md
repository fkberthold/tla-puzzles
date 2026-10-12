# Hash table capacity: answer

## The answer

```tla
---- MODULE HashTable ----
EXTENDS Naturals

CONSTANT MaxCap

VARIABLES cap, load

vars == <<cap, load>>

IsPrime(n) ==
  /\ n >= 2
  /\ \A k \in 2..(n - 1) : n % k /= 0

TypeOK ==
  /\ cap \in 2..MaxCap
  /\ load \in 0..cap

Init ==
  /\ cap = 2
  /\ load = 0

Insert ==
  /\ load < cap
  /\ load' = load + 1
  /\ UNCHANGED cap

Remove ==
  /\ load > 0
  /\ load' = load - 1
  /\ UNCHANGED cap

Grow ==
  /\ 2 * load > cap
  /\ \E p \in (cap + 1)..(2 * cap) :
       /\ p <= MaxCap
       /\ IsPrime(p)
       /\ cap' = p
  /\ UNCHANGED load

Next == Insert \/ Remove \/ Grow

Spec == Init /\ [][Next]_vars

CapacityIsPrime == IsPrime(cap)

LoadFits == load <= cap
====
```

```
SPECIFICATION Spec
CONSTANTS
  MaxCap = 20
INVARIANTS
  TypeOK
  CapacityIsPrime
  LoadFits
```

`IsPrime` is a universal statement over a range. For `n = 2` the range `2..1`
is empty, so the `\A` is true with nothing to check, which is what you want.
`Grow` is an existential choice from a range, with the conditions on the
choice inside the quantifier and `cap' = p` as its last conjunct. TLC
enumerates the range and keeps the `p` that pass.

Bertrand's postulate says there's a prime between n and 2n for every n above
1, so `Grow` is enabled whenever the ceiling allows it. At the ceiling `Grow`
goes quiet and `Remove` is still there, so the model has no deadlock without
any special handling.

## Measurements

From `verify/`, `tlc -workers 1 -noGenerateSpecTE -metadir states/<name>
<Module>.tla -config <Module>.cfg`.

| module | what | rc | generated | distinct | TLC says |
|---|---|---|---|---|---|
| `HashTable` | reference | rc 0 | 210 | 85 | no error |
| `GrowAnywhere` | `Grow` without the primality check | rc 12 | 7 | 5 | the prime invariant is violated, at the first growth to 4 |

85 is the sum of `cap + 1` over the eight primes up to 20: 3, 4, 6, 8, 12, 14,
18 and 20. Every load is reachable at every capacity, since growth keeps the
load and the load can then go either way.

## Acceptable variants

- `n > 1` in place of `n >= 2`. Same.
- `~(n % k = 0)` in place of `n % k /= 0`. Same, with `~` doing the work.
- `\A k \in 2..n-1`. Same range, fewer brackets.
- The three conditions in `Grow` on one line with `/\`. Same.
- `Grow` picking the smallest prime with `CHOOSE`. One successor instead of several. Fewer states, same rules hold.

The last is the sets family's operator, and a different model. The prompt says
"may grow to a prime", which is a choice, so the `\E` is the closer reading.

## Wrong neighbours

| neighbour | what kills it |
|---|---|
| `Grow` without the primality check | the prime invariant goes red at the first growth to 4 |
| `\A k \in 2..n` (range includes `n`) | every `n` divides itself, so nothing is prime. The prime invariant fails in `Init` at `cap = 2`, rc 12 (not measured) |
| `\E` where `\A` belongs in `IsPrime` | every `n` from 4 up counts as prime, since some `k` doesn't divide it. The invariant uses the same wrong definition, so TLC passes. More than 85 states is the only tell (not measured). |
| `Grow` without `p <= MaxCap` | `TypeOK` red at `cap = 23`, rc 12 (not measured) |

The third row is the one to sit with. A definition that's wrong the same way
in the action and in the rule is self-consistent, and TLC checks consistency.
The count in the prompt is what catches it.

## Why not in prompt

"Define what a prime is yourself" is the nudge toward `\A`. A reader could
instead write the primes under 20 out as a set, and the check would pass. The
honest caveat: "more than half full" and "no more than double it" are two
inequalities the reader spells in arithmetic, not in quantifiers, so the `\A`
is forced only by the sentence. The `\E` is forced by the domain, since the
choice is among several primes, and that one I think the prompt does make the
reader retrieve.
