# A05: Apalache — Folds (ApaFoldSet) ⭐⭐

## Lesson: Fold Instead of Recurse

In TLA+, you can write recursive operators:

```tla
RECURSIVE Sum(_)
Sum(S) == IF S = {} THEN 0
          ELSE LET x == CHOOSE y \in S: TRUE IN x + Sum(S \ {x})
```

TLC accepts this. **Apalache does not.** Apalache's symbolic encoding cannot unfold an unbounded recursion — it would generate infinite SMT constraints. Even bounded recursion only sometimes works, and the Apalache team strongly recommends a different idiom: **folds**.

A fold reduces a collection to a single value by repeatedly applying a 2-argument operator. The Apalache standard library gives you two:

```tla
ApaFoldSet(Op(_,_), base, S)        \* fold a SET S
ApaFoldSeqLeft(Op(_,_), base, seq)  \* fold a SEQUENCE seq, left-to-right
```

Reading: "Start from `base`. For each element of the collection, call `Op(accumulator, element)` and feed the result back as the new accumulator."

For sets, the iteration order is unspecified — so `Op` MUST be associative and commutative for the result to be deterministic. (Sum, max, count, AND, OR, set-union all qualify. Subtraction, division, list-append do not.)

You define `Op` with `LET-IN`:

```tla
Sum(S) == LET Plus(acc, x) == acc + x
          IN  ApaFoldSet(Plus, 0, S)
```

That's it. Three lines, no recursion, accepted by both TLC and Apalache.

**Worked example — a grade book.**

A class has a set of grades. We want three reductions: total points, top score, count of passing grades (>= 60). All three are folds.

```tla
---- MODULE GradeBook ----
EXTENDS Integers, Apalache

\* @type: Set(Int);
VARIABLE grades

vars == << grades >>

Init == grades = { 72, 88, 55, 91, 60 }

\* (no actions; this is a one-state spec for demonstration)
Next == UNCHANGED grades

Spec == Init /\ [][Next]_vars

Total ==
  LET Plus(acc, g) == acc + g
  IN  ApaFoldSet(Plus, 0, grades)

Top ==
  LET Max(acc, g) == IF g > acc THEN g ELSE acc
  IN  ApaFoldSet(Max, 0, grades)

PassingCount ==
  LET BumpIfPass(acc, g) == IF g >= 60 THEN acc + 1 ELSE acc
  IN  ApaFoldSet(BumpIfPass, 0, grades)

GradeBookOK ==
  /\ Total = 366
  /\ Top = 91
  /\ PassingCount = 4
====
```

Three reductions, three two-argument operators, three `ApaFoldSet` calls. No `RECURSIVE`. Apalache encodes each fold as a bounded SMT iteration; TLC computes it directly. Same answer.

**Patterns to remember.**

| Reduction         | Base | Op                                                 |
|-------------------|------|----------------------------------------------------|
| Sum               | `0`  | `LET Plus(a, x) == a + x`                          |
| Product           | `1`  | `LET Mul(a, x) == a * x`                           |
| Max (over Nat)    | `0`  | `LET Max(a, x) == IF x > a THEN x ELSE a`          |
| Count where pred  | `0`  | `LET Bump(a, x) == IF P(x) THEN a + 1 ELSE a`      |
| Set union         | `{}` | `LET Union(a, x) == a \cup F(x)`                   |
| All / forall flag | `TRUE` | `LET AndP(a, x) == a /\ P(x)`                    |

For sequences (where order matters), use `ApaFoldSeqLeft` instead, with the same shape: `Op(acc, elem)`.

**The key idea.** Whenever you reach for `RECURSIVE`, stop. Ask: am I reducing a collection to one value? If yes, use a fold. If no, you might want to refactor what you're computing.

## Setup

A warehouse tracks a set of `boxes`, each box with fields `weight` (integer) and `fragile` (boolean). We want three derived numbers, all defined in TLA+ (not as actions, just as operator expressions):

1. `TotalWeight` — sum of all weights
2. `HeaviestWeight` — the maximum weight in `boxes`
3. `FragileCount` — how many boxes have `fragile = TRUE`

## Task

Write `Warehouse.tla`:

- `EXTENDS Integers, Apalache`
- A `box` type alias: `\* @typeAlias: box = { weight: Int, fragile: Bool };`
- One state variable: `\* @type: Set($box);` `VARIABLE boxes`
- `Init` sets `boxes` to a small constant set (use `:=`):
  ```
  boxes := {
    [ weight |-> 5, fragile |-> FALSE ],
    [ weight |-> 8, fragile |-> TRUE  ],
    [ weight |-> 3, fragile |-> TRUE  ],
    [ weight |-> 12, fragile |-> FALSE ]
  }
  ```
- `Next == UNCHANGED boxes` (one-state spec)
- `Spec == Init /\ [][Next]_vars`
- Three derived operators using `ApaFoldSet`:
  - `TotalWeight` — fold with `Plus(acc, b) == acc + b.weight`, base `0`
  - `HeaviestWeight` — fold with a `Max` op, base `0`
  - `FragileCount` — fold counting boxes where `b.fragile`, base `0`
- An invariant `WarehouseOK == TotalWeight = 28 /\ HeaviestWeight = 12 /\ FragileCount = 2`

## Check

```bash
cd solution
tlc Warehouse
```

If you have Apalache:

```bash
apalache-mc check --inv=WarehouseOK Warehouse.tla
```

## Expected Result

- TLC: 1 distinct state, no error. (Single-state spec — `boxes` never changes, so the only behavior is `Init` then stuttering forever.)
- Apalache: invariant holds.
- All three folds compute their answers without `RECURSIVE`. Apalache accepts the spec; if you rewrote any of them with `RECURSIVE`, Apalache would reject the spec (TLC would still accept).

**Try the rewrite.** Replace `TotalWeight` with the recursive version below, then run TLC — it still works. Then conceptually compare: Apalache rejects the recursive form. The fold version is the portable answer.

```tla
RECURSIVE SumW(_)
SumW(S) == IF S = {} THEN 0
           ELSE LET b == CHOOSE x \in S: TRUE
                IN b.weight + SumW(S \ {b})
```

## What you learned

- `ApaFoldSet(Op, base, S)` reduces a set; `ApaFoldSeqLeft(Op, base, seq)` reduces a sequence.
- The reducer `Op` takes two args: `(accumulator, element)`. Define it with `LET-IN`.
- For sets, `Op` must be associative + commutative (no order guarantee).
- Common patterns: sum, max, count-if, set-union, forall-flag.
- Folds replace `RECURSIVE` everywhere it's a reduction. Apalache requires this; TLC tolerates both, so writing fold-style is portable.

## Hints

??? hint "💡 Hint 1 — Replace RECURSIVE with a fold"
    The lesson says: when you reach for `RECURSIVE`, stop and ask whether you're reducing a collection to one value. Your three operators (`TotalWeight`, `HeaviestWeight`, `FragileCount`) each take `boxes` and compute a single number. That's a fold pattern. Look up `ApaFoldSet` in the lesson: what are its three arguments?

??? hint "💡 Hint 2 — Define Op with LET-IN"
    Each fold needs a two-argument operator `Op(accumulator, element)`. The lesson shows: `LET Plus(acc, x) == acc + x IN ApaFoldSet(Plus, 0, S)`. For `TotalWeight`, your element is a box record. Access `b.weight` to get the weight field.

??? hint "💡 Hint 3 — Three different Op functions"
    `TotalWeight` uses `Plus` (sum weights). `HeaviestWeight` uses `Max` (track largest). `FragileCount` uses an `IF` check (count how many pass a predicate). Each fold has a different reducer; the pattern table in the lesson shows all three.
