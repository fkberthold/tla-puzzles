# `FiniteSets`

Standard library. Brings cardinality and finiteness checks for sets.

```tla
EXTENDS FiniteSets
```

## Operators

| Operator | Type | Meaning |
|---|---|---|
| `Cardinality(S)` | Set → Nat | the number of elements in `S` (only meaningful for finite `S`) |
| `IsFiniteSet(S)` | Set → Bool | `TRUE` iff `S` is finite |

## Why this is a separate module

TLA+'s base set theory allows infinite sets (`Nat`, `Int`, `Seq(T)`). TLC can't enumerate those, and "size" only makes sense when `S` is finite. `FiniteSets` provides the operators that need that finiteness assumption.

## Example

```tla
TypeOK ==
  /\ pending \subseteq Tasks
  /\ Cardinality(pending) <= MaxConcurrent

ASSUME IsFiniteSet(Tasks)
```

## First introduced

T20 (Cardinality and FiniteSets) — the puzzle that explicitly teaches both operators.
