# `TLC`

Standard library specific to **the TLC model checker**. These operators are no-ops outside TLC; they exist so a spec can talk to the checker (debug printing, runtime assertions, model values, etc.).

```tla
EXTENDS TLC
```

## Operators used in this curriculum

| Operator | Type | Meaning |
|---|---|---|
| `Permutations(S)` | Set → Set(Set) | the set of all permutations of the elements of `S`, used as the value for the cfg `SYMMETRY` directive (T60) |
| `Assert(p, msg)` | Bool × String → Bool | if `p` is false, TLC stops and prints `msg`; otherwise returns `TRUE`. Used inside actions to flag impossible runtime states |
| `PrintT(x)` | Any → Bool | prints `x` to the TLC log; returns `TRUE`. Useful for debugging — though counterexamples are usually a better debugging tool |

## Operators TLC provides that the curriculum doesn't currently use

`@@` (function override), `:>` (single-pair function), `JavaTime`, `RandomElement`, `TLCEval`, etc. See the [TLC standard module source](https://github.com/tlaplus/tlaplus/blob/master/tlatools/org.lamport.tlatools/src/tla2sany/StandardModules/TLC.tla) for the full list.

## Example — SYMMETRY

```tla
\* In TrafficLight.tla:
EXTENDS TLC

\* In TrafficLight.cfg:
CONSTANT Workers = {w1, w2, w3}
SYMMETRY WorkerSym

\* And in the spec:
WorkerSym == Permutations(Workers)
```

The `SYMMETRY` directive tells TLC: states that differ only by a permutation of `Workers` are equivalent. Reduces the state space dramatically. Requires model values (T62).

## First introduced

`Permutations` introduced in T60 (SYMMETRY for State-Space Reduction). `Assert` introduced in T05 (The Toll Booth).
