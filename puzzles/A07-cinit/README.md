# A07: Apalache — `--cinit` for Constants ⭐⭐

## Lesson: Symbolic Constants via `ConstInit`

A spec with `CONSTANT N` needs `N` filled in before model checking. With TLC you write `CONSTANT N = 3` in the `.cfg`. Apalache supports the same `.cfg` style — but it also supports something more powerful: **`--cinit`**, a "constant initializer" predicate that lets the solver pick the value symbolically.

```tla
CONSTANT
  \* @type: Int;
  N

ConstInit ==
  /\ N \in 1..5
```

When you run `apalache-mc check --cinit=ConstInit Spec.tla`, Apalache picks `N` from `1..5` symbolically and proves the spec for ALL such N. It's effectively quantifying the constant — one check, parameterized over all valid values.

Compare:

| Approach              | What you write                        | What gets verified            |
|-----------------------|---------------------------------------|-------------------------------|
| `.cfg` with one value | `CONSTANT N = 3`                       | Just N = 3                    |
| `.cfg` loop manually  | rerun TLC for N = 1, 2, 3, 4, 5       | All five separately           |
| `ConstInit` + `--cinit` | predicate `N \in 1..5`              | All N in 1..5, in one run      |

Apalache exploits its symbolic backend to do (3) more efficiently than (2). For finite domains, `ConstInit` is a one-line generalization.

**Anatomy of a `ConstInit` predicate.** It's just a TLA+ predicate that constrains the constants. Anything you'd put into a `.cfg` `CONSTANT` line generalizes:

```tla
ConstInit ==
  /\ N \in 1..5                      \* numeric range
  /\ Workers \subseteq { "a", "b", "c" }   \* set of strings
  /\ Cardinality(Workers) > 0        \* nonempty
  /\ ColorOf \in [ Workers -> {"red","blue"} ]   \* a function
```

You can express any constraint expressible in TLA+. Apalache enforces it before exploring the spec.

**Worked example — a queue capacity.**

A queue spec has constants `Capacity` (positive integer) and `Items` (set of items that may be enqueued). We want Apalache to check the spec for all reasonable capacities, not just one.

```tla
---- MODULE BoundedQueue ----
EXTENDS Integers, Sequences, Apalache

CONSTANTS
  \* @type: Int;
  Capacity,
  \* @type: Set(Str);
  Items

\* @type: Seq(Str);
VARIABLE q

vars == << q >>

Init == q := << >>

Enqueue ==
  /\ Len(q) < Capacity
  /\ \E i \in Items:
       q' := Append(q, i)

Dequeue ==
  /\ Len(q) > 0
  /\ q' := Tail(q)

Next == Enqueue \/ Dequeue

Spec == Init /\ [][Next]_vars

TypeOK == Len(q) <= Capacity

\* The cinit predicate constrains Capacity and Items symbolically.
ConstInit ==
  /\ Capacity \in 1..3
  /\ Items = { "a", "b" }
====
```

Run with TLC (no `cinit` support, so we fall back to fixing the constants in a `.cfg`):

```
CONSTANTS Capacity = 3
          Items   = { "a", "b" }
SPECIFICATION Spec
INVARIANT TypeOK
```

Run with Apalache, parameterized:

```bash
apalache-mc check --cinit=ConstInit --inv=TypeOK BoundedQueue.tla
```

Apalache verifies `TypeOK` for every `Capacity \in 1..3` and the fixed `Items` set, in a single invocation.

**The key idea.** `ConstInit` lets you express *what counts as a valid configuration* in the spec itself. Apalache then quantifies over those configurations symbolically. TLC can't do this, so for TLC runs you keep using a `.cfg` with concrete constant values.

## Setup

A small bank account spec with a constant `Limit` (the overdraft floor — a *negative* integer, e.g. -100). The account starts at 0; you can `Deposit` (any amount in 1..50) or `Withdraw` (any amount in 1..50, but only if the resulting balance stays ≥ `Limit`).

We want to check the invariant `Balance >= Limit` for *all* `Limit \in -50..-10`, not just one specific limit.

## Task

Write `Account.tla`:

- `EXTENDS Integers, Apalache`
- One constant `Limit`, type-annotated `Int`.
- One variable `balance`, type-annotated `Int`. Init `balance := 0`.
- `Deposit`: nondeterministically pick `amt \in 1..50`, add `amt` to balance (only fires when `balance < 100`, to keep the state space bounded).
- `Withdraw`: nondeterministically pick `amt \in 1..50`, subtract from balance, but only if the result is ≥ `Limit`.
- `Done`: stutter when `balance = 100` (caps the state space).
- `Next == Deposit \/ Withdraw \/ Done`
- `Spec == Init /\ [][Next]_vars`
- Invariant: `BalanceFloor == balance >= Limit`
- A `ConstInit` operator: `ConstInit == Limit \in -50..-10`

Provide a `.cfg` for TLC with a concrete `Limit` (e.g. -50). The `ConstInit` operator is unused by TLC — but it sits in the spec for Apalache.

## Check

```bash
cd solution
tlc Account
```

If you have Apalache:

```bash
apalache-mc check --cinit=ConstInit --inv=BalanceFloor Account.tla
```

## Expected Result

- TLC (with `Limit` overridden to `-50` via the cfg): about 200 distinct states, no error. (`Deposit` and `Withdraw` each branch over 50 amounts, so the state graph is wide. The invariant holds throughout.)
- Apalache with `--cinit=ConstInit`: verifies `BalanceFloor` for all `Limit \in -50..-10` symbolically in one run. Same answer (no violation), proven over the entire range of limits.

**A note on the cfg.** TLC's `.cfg` grammar does not accept negative-integer literals on `CONSTANT N = ...` lines. The workaround used here is a helper operator `LimitVal == -50` in the spec plus `CONSTANTS Limit <- LimitVal` in the cfg (the `<-` syntax overrides a constant with an operator's value). This is a TLC quirk; Apalache's `--cinit` sidesteps it entirely because the constraint is in the spec.

**To see TLC's "one constant at a time" limitation.** Edit `LimitVal == -50` to `LimitVal == -10`, rerun. It's a separate run with a different state space. Apalache's `--cinit` collapses both runs into one.

## What you learned

- `ConstInit` is a TLA+ predicate that constrains the spec's constants.
- Apalache's `--cinit=Op` flag tells the symbolic checker to pick constants that satisfy `Op` and verify the spec parameterized over them.
- A finite, nontrivial range of constants in one solver run beats N separate TLC runs.
- TLC has no `--cinit` equivalent. For TLC, you set concrete constant values in the `.cfg` file. The `ConstInit` operator simply sits unused in the spec when TLC runs.

## Hints

??? hint "💡 Hint 1 — Constants are symbolic in ConstInit"
    The lesson shows that `ConstInit` is a predicate that constrains the constants. You're asked to write a `ConstInit` that lets Apalache pick `Limit` from a range. What's the TLA+ syntax for "this constant is in a range of integers"?

??? hint "💡 Hint 2 — ConstInit lives in the spec"
    `ConstInit` is an operator you define in the spec (like any TLA+ operator). It's a predicate that Apalache reads when you pass `--cinit=ConstInit`. TLC ignores it entirely — TLC still needs a `.cfg` with a concrete value. The lesson example shows `Limit \in -50..-10`.

??? hint "💡 Hint 3 — One Deposit guard, one Withdraw guard"
    Both `Deposit` and `Withdraw` should be guarded by a cap (`balance < 100` for `Deposit` to avoid huge state spaces). `Withdraw` must check that the result stays above `Limit`. Use the constant in the guard: `balance - amt >= Limit`.
