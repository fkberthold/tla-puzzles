# T43: `[]` Always — As Property ⭐

## Lesson: `[]` as a PROPERTY (vs `INVARIANT`)

Until now you've used `INVARIANT TypeOK` in the cfg. There's a second way to make the same kind of claim:

```
PROPERTY AlwaysTypeOK
```

where in the spec you wrote

```
AlwaysTypeOK == []TypeOK
```

The `[]` ("always", or "box") is a temporal operator. `[]P` says: in every state of every behavior, `P` is true.

**For a plain state predicate `P` (no primed variables, no nested temporal), these two are EQUIVALENT:**

```
INVARIANT P             \* state-level claim
PROPERTY []P            \* temporal claim, equivalent for plain state predicates
```

So why bother with `[]`? Because the temporal form is composable. You can't write `INVARIANT (P => <>Q)` — invariants don't allow `<>`. But you CAN write `PROPERTY [](P => <>Q)`. T44 (leads-to) uses exactly this. Once you reach for `<>`, `[]<>`, `<>[]`, you must drop into PROPERTY-land. `INVARIANT` is the special simple case.

The difference matters in two situations:

1. **The predicate references `'` (next-state values).** `INVARIANT` rejects this — invariants are state predicates, not actions. `PROPERTY [][A]_v` (a "step" formula) is the right shape.
2. **The predicate is itself temporal.** `[]<>P` is a property, not an invariant. `INVARIANT []<>P` doesn't typecheck.

For everything else — the bread-and-butter "this state predicate holds" — INVARIANT is shorter and idiomatic. Use PROPERTY `[]P` when the predicate is part of a larger temporal formula or when you're emphasizing the temporal level (T27 will name this distinction).

**Worked example — a bank account.**

A simple account model: deposits and withdrawals, but withdrawals are only allowed when the balance covers them.

```
(*--algorithm Account {
  variables balance = 100;

  define {
    NeverNegative == balance >= 0
    AlwaysNeverNegative == []NeverNegative
  }

  fair process (cust = "Customer") {
    txn:
      while (TRUE) {
        either {
          balance := balance + 10;            \* deposit
        } or {
          if (balance >= 20) {
            balance := balance - 20;          \* withdraw
          };
        };
      }
  }
}*)
```

In the cfg, two equivalent ways to assert "balance never goes negative":

```
INVARIANT NeverNegative
\* OR equivalently:
PROPERTY AlwaysNeverNegative
```

For a state predicate like `NeverNegative`, both pass. Both fail (with the same trace) if you change the withdraw branch to skip the guard. The trace shape and length are identical. The difference is purely about which level you're working at — T27 will return to this.

When you reach for `[]<>` (T45) or `<>[]` (T46) or leads-to (T44), only the PROPERTY form is available. `INVARIANT` doesn't accept temporal operators.

## Setup

A thermostat keeps a room temperature between 60 and 80 degrees. On each tick the heater either turns up by 1, turns down by 1, or holds. The thermostat's circuit board guards against running out of range.

## Task

Write a PlusCal spec with:

- A variable `temp` initially `70`
- A `define` block with:
  - `TypeOK == temp \in 60..80`
  - `InRange == temp \in 60..80`
  - `AlwaysInRange == []InRange`
- A `fair process` that loops forever:
  - `either` increase: if `temp < 80`, `temp := temp + 1`
  - `or` decrease: if `temp > 60`, `temp := temp - 1`
  - `or` hold: `skip`

In `Thermostat.cfg`, assert the same claim TWO ways for comparison:

```
INVARIANT TypeOK
PROPERTY AlwaysInRange
```

Both should pass. Both check the same thing.

## Check

1. **TypeOK** holds (state-level).
2. **AlwaysInRange** holds (temporal-level — equivalent claim, different cfg directive).

## Expected Result

- TLC finds **21 distinct states** (`temp` values from 60 to 80 inclusive).
- Both the `INVARIANT` and the `PROPERTY` pass. They are checking the same predicate at different syntactic levels.
- **Strip test**: drop the guard on the decrease branch (`temp := temp - 1` unconditionally). Now `temp` can fall to 59. Both `INVARIANT TypeOK` and `PROPERTY AlwaysInRange` fail with the same 2- to 3-state trace. Same diagnosis, different directive.
- **The point**: when you graduate to `<>`, `[]<>`, `<>[]`, or leads-to, only the PROPERTY form will work. `[]InRange` is the gateway: a temporal formula that happens to be equivalent to an invariant, but lives in the same grammar as the harder properties coming up.

## Hints

??? hint "💡 Hint 1 — Comparing state-level and temporal-level"
    The cfg asks for both `INVARIANT TypeOK` and `PROPERTY AlwaysInRange`. If they're equivalent, why does TLA+ let you write them both ways? When would only one form be valid?

??? hint "💡 Hint 2 — Nesting the operator"
    `AlwaysInRange` should be defined in your `define` block as `[]InRange`. The `InRange` predicate is just a name for the plain state predicate `temp \in 60..80`. Wrapping it in `[]` lifts it to the temporal level.

??? hint "💡 Hint 3 — The loop guard"
    Your process loops forever with three branches. Each branch must respect the invariant: `temp` never leaves the range 60..80. Two branches increment/decrement conditionally (with guards). The third branch does nothing (`skip`).
