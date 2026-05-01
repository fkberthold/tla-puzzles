# A09: Apalache Capstone — Full Type-Annotated Spec ⭐⭐⭐

## Recap of the Apalache Track

This capstone composes **every Apalache technique** introduced so far. There is no new concept — the lesson is putting the pieces together on a non-trivial spec.

| From | Technique                                                       |
|------|-----------------------------------------------------------------|
| A01  | `\* @type:` annotations on every variable; base types `Int`, `Bool`, `Str` |
| A02  | Composite types `Set(T)`, `Seq(T)`, `<<T1, T2>>`, `{ field: T, ... }`, `T -> U` |
| A03  | `\* @typeAlias: name = T;` and `$name` references                |
| A04  | `:=` from `EXTENDS Apalache`; assign every variable in every action |
| A05  | `ApaFoldSet` / `ApaFoldSeqLeft` instead of `RECURSIVE`           |
| A06  | A `Done` stutter action so terminal states are not deadlocks      |
| A07  | `ConstInit` predicate for `--cinit` symbolic constants            |
| A08  | One spec runnable on both TLC and Apalache                       |

## Setup — A Pizza-Shop Order Flow

A pizza shop runs a small fulfillment loop:

1. Customers submit **orders**. Each order has an integer `id`, a string `topping`, a positive integer `size`.
2. Submitted orders sit in a `pendingQueue` (sequence — FIFO).
3. The shop has two ovens, each either `idle` or holding an order in progress.
4. The first idle oven picks up the front of the queue (`Assign`).
5. After some bake time, the oven outputs the order — it becomes `done` (`Bake`).
6. Done orders accumulate in a `completed` set.
7. We track per-oven counts of orders each has handled.
8. Two derived metrics matter: `TotalCompleted` (count) and `TotalSizeBaked` (sum of sizes — fold).

We bound the state space with `MaxOrders` (constant): at most `MaxOrders` orders are ever submitted.

## Task — Author the spec

Write `Pizzeria.tla`. Every variable must carry a `\* @type:` annotation. Use type aliases for the `order` shape and ovens. Use `:=` for every primed-variable assignment. Use `ApaFoldSet` for the `TotalSizeBaked` derived value. Provide a `ConstInit` for Apalache and a concrete-constant cfg for TLC. Have a `Done` action that stutters once all orders are submitted, all ovens idle, and `pendingQueue` empty.

### Required components

**Type aliases:**

```tla
\* @typeAlias: order = { id: Int, topping: Str, size: Int };
\* @typeAlias: oven  = { id: Int, holding: $order, busy: Bool };
```

**Constants:**
```tla
CONSTANTS
  \* @type: Int;
  MaxOrders,
  \* @type: Set(Str);
  Toppings
```

**Variables:**

| Variable      | Annotation                        | Meaning                           |
|---------------|-----------------------------------|------------------------------------|
| `nextId`      | `\* @type: Int;`                  | next order ID to issue            |
| `pendingQueue`| `\* @type: Seq($order);`         | FIFO of orders awaiting an oven   |
| `ovens`       | `\* @type: Int -> $oven;`        | oven id (1, 2) → oven record      |
| `completed`   | `\* @type: Set($order);`         | finished orders                   |
| `handled`     | `\* @type: Int -> Int;`          | oven id → count of orders done    |

**Actions** (each must use `:=` for every primed variable, including unchanged):

- `Submit`: when `nextId <= MaxOrders`, pick `t \in Toppings` and `s \in 1..3`. Append the new order to `pendingQueue`, advance `nextId`, leave `ovens`, `completed`, `handled` unchanged (write the unchanged ones via `:=`, e.g. `ovens' := ovens`).
- `Assign`: when an oven is idle and `pendingQueue` nonempty, pick the first idle oven `i`, take the head of `pendingQueue`, set `ovens[i]` to `[id |-> i, holding |-> head, busy |-> TRUE]`, drop the head from `pendingQueue`, leave others unchanged.
- `Bake`: when an oven `i` is busy, move its `holding` order into `completed`, increment `handled[i]`, set `ovens[i]` back to idle (use a sentinel `idleOrder`), leave the queue and `nextId` unchanged.
- `Done`: when `nextId > MaxOrders` AND `pendingQueue = << >>` AND no oven is busy, `UNCHANGED vars`.

**Sentinels (so the spec stays type-clean):**

```tla
idleOrder == [ id |-> 0, topping |-> "none", size |-> 0 ]
IdleOven(i)  == [ id |-> i, holding |-> idleOrder, busy |-> FALSE ]
```

(Apalache requires every record field to have a value at all times — even an idle oven must carry an `order` in `holding`. The sentinel keeps the type fixed.)

**Derived values (folds — A05):**

```tla
TotalCompleted == Cardinality(completed)
TotalSizeBaked ==
  LET Plus(acc, o) == acc + o.size
  IN  ApaFoldSet(Plus, 0, completed)
```

**Invariants:**

- `TypeOK` — written as a conjunction asserting every variable has the shape its annotation promises (e.g. `nextId \in 0..MaxOrders + 1`, `Len(pendingQueue) <= MaxOrders`, etc.).
- `BakedFitsCompleted` — `TotalSizeBaked <= MaxOrders * 3` (each order has size ≤ 3).

**ConstInit:**
```tla
ConstInit ==
  /\ MaxOrders \in 1..3
  /\ Toppings  = { "cheese", "pepperoni" }
```

**.cfg for TLC:**
```
CONSTANTS MaxOrders = 2
          Toppings  = { "cheese", "pepperoni" }
SPECIFICATION Spec
INVARIANT TypeOK
INVARIANT BakedFitsCompleted
```

## Check

```bash
cd solution
tlc Pizzeria
```

If you have Apalache:

```bash
apalache-mc typecheck Pizzeria.tla
apalache-mc check --cinit=ConstInit --inv=TypeOK --inv=BakedFitsCompleted --length=20 Pizzeria.tla
```

## Expected Result

- TLC with `MaxOrders = 2`: about 343 distinct states (depth 7), both invariants hold, no deadlock (because `Done` is always enabled at terminal states), no error.
- Apalache `typecheck`: `Type checker [OK]` — every annotation consistent.
- Apalache `check`: invariants hold for all `MaxOrders \in 1..3` and the fixed `Toppings` set.

The spec should run cleanly on **both** model checkers from the same source — no edits needed between them. That portability is the goal of the Apalache track.

## What this capstone exercises

- Mixed type system: integers, strings, sets of records, sequences of records, functions from int to record, functions from int to int.
- Type aliases reused across multiple variables (clean field renames stay one-line edits).
- `:=` discipline: every action assigns every variable, no `UNCHANGED` shortcuts.
- A fold over a set of records (`TotalSizeBaked`).
- A terminal `Done` action so the model never deadlocks at the natural end-of-trace.
- A `ConstInit` predicate so Apalache can quantify `MaxOrders` symbolically.
- A `.cfg` keyed to TLC's view of the same spec.

If your spec passes both `tlc Pizzeria` (clean) and (when you have it installed) `apalache-mc typecheck Pizzeria.tla` plus `apalache-mc check`, you have written a *production-shape* TLA+ spec — typed, portable, foldable, and parameterizable. That's the Apalache track end-to-end.
