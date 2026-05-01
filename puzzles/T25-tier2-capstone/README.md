# T25: Tier 2 Capstone — Order System ⭐⭐

## Lesson: Capstone — Tier 2 in One Spec

No new concept. This puzzle asks you to reach for Tier 2 in a single spec:

- **T09** — records: constructor, dot access, EXCEPT update
- **T10–T11** — sequences: literal, append, head/tail, len
- **T12–T15** — functions: constructor, application, EXCEPT, EXCEPT with `@`
- **T16** — function-set `[S -> T]` (in TypeOK)
- **T17–T18** — set comprehension: filter, map
- **T20** — Cardinality
- **T22–T23** — IF/THEN/ELSE expressions, LET-IN
- **T24** — `\A` and `\E` in invariants

**Recap — what each piece does:**

```
\* Records (T09): constructor, dot, EXCEPT
order == [id |-> 1, qty |-> 5, status |-> "pending"]
order.qty                                          \* 5
[order EXCEPT !.status = "shipped"]                \* new record with status changed
[order EXCEPT !.qty = @ + 1]                       \* relative update with @

\* Sequences (T10-T11): literal, Append, Head/Tail, Len
hist == <<"opened", "paid">>
Append(hist, "shipped")                            \* <<"opened", "paid", "shipped">>
Head(hist)                                         \* "opened"
Len(hist)                                          \* 2

\* Functions (T12-T15): constructor, application, EXCEPT, @
prices == [item \in {"apple", "bread"} |-> 0]
prices["apple"]                                    \* 0
[prices EXCEPT !["apple"] = @ + 5]                 \* function update with @

\* Function set (T16): used in TypeOK
balances \in [Customers -> 0..1000]                \* "balances is some function from customers to dollars"

\* Set comprehensions (T17-T18)
{c \in Customers : balance[c] > 100}               \* filter
{balance[c] : c \in Customers}                     \* map

\* Cardinality (T20)
Cardinality({c \in Customers : active[c]})

\* IF/THEN/ELSE (T22)
status == IF qty = 0 THEN "empty" ELSE "stocked"

\* LET-IN (T23)
LET tax == (sub * 7) \div 100 IN sub + tax

\* Quantifiers (T24)
\A c \in Customers : balance[c] >= 0               \* universal
\E c \in Customers : balance[c] = 0                \* existential
```

The puzzle below composes all of them. There's no new syntax — just the discipline of choosing the right tool for each sub-task.

## Setup

A small order-processing system tracks two customers (`"alice"` and `"bob"`) and three product items (`"apple"`, `"bread"`, `"coffee"`). The state is a function from customer to a record describing their current order:

- `id` — order ID (an integer)
- `cart` — a function from item → quantity
- `history` — a sequence of strings (status events: `"opened"`, `"paid"`, `"shipped"`)

The system runs three actions in sequence (one label each):

1. **stockApple** — add 2 apples to alice's cart, using `EXCEPT` with `@` on the nested `cart` function.
2. **payAlice** — append `"paid"` to alice's `history`, using `EXCEPT` with `@` on the sequence and `Append`.
3. **summarize** — derive a SUMMARY record:
   - `total` (sum of all alice's apple+bread+coffee quantities) using `LET`
   - `paidCustomers` — set comprehension filter: customers whose history contains `"paid"`
   - `nPaid` — `Cardinality(paidCustomers)`
   - `allItems` — set comprehension map: produce the SET of item names that are stocked (qty > 0) in alice's cart. (You'll define this with both filter and map.)

Each action increments `phase`. After all three, the summary record describes the final state.

## Task

Write a PlusCal spec with:

```
EXTENDS Integers, Sequences, FiniteSets, TLC
```

Variables:

- `orders` — initial value: a function from customer to record:
  ```
  [c \in {"alice", "bob"} |->
    [id |-> IF c = "alice" THEN 1 ELSE 2,
     cart |-> [i \in {"apple", "bread", "coffee"} |-> 0],
     history |-> <<"opened">>]]
  ```
- `summary` — initial value `[total |-> 0, paidCustomers |-> {}, nPaid |-> 0, allItems |-> {}]`
- `phase` starting at `0`

In the `define` block:

```
Customers == {"alice", "bob"}
Items == {"apple", "bread", "coffee"}
Statuses == {"opened", "paid", "shipped"}
PossibleQty == 0..10

\* TypeOK uses function-set, quantifiers, record fields
TypeOK ==
  /\ \A c \in Customers :
       /\ orders[c].id \in 0..10
       /\ orders[c].cart \in [Items -> PossibleQty]
       /\ \A k \in 1..Len(orders[c].history) : orders[c].history[k] \in Statuses
  /\ summary.total \in 0..30
  /\ summary.paidCustomers \subseteq Customers
  /\ summary.nPaid \in 0..2
  /\ summary.allItems \subseteq Items
  /\ phase \in 0..3

\* Helper: did this customer's history include "paid"?
HasPaid(c) == \E k \in 1..Len(orders[c].history) : orders[c].history[k] = "paid"

\* Filter set: paid customers
PaidSet == {c \in Customers : HasPaid(c)}

\* Quantifier-using invariant
EveryCartItemIsKnown == \A c \in Customers : DOMAIN orders[c].cart = Items

\* Existential-using invariant
SomeoneHasOpened ==
  \E c \in Customers : \E k \in 1..Len(orders[c].history) : orders[c].history[k] = "opened"
```

A single fair process runs three labels:

1. **stockApple**: add 2 apples to alice's cart.
   ```
   orders := [orders EXCEPT !["alice"].cart = [@ EXCEPT !["apple"] = @ + 2]];
   phase := phase + 1;
   ```

   (The nested EXCEPT updates the `cart` field of alice's record; the inner EXCEPT updates the `apple` entry of that cart function. Two `@`s, each scoped to its own EXCEPT.)

2. **payAlice**: append `"paid"` to alice's history.
   ```
   orders := [orders EXCEPT !["alice"].history = Append(@, "paid")];
   phase := phase + 1;
   ```

3. **summarize**: compute the summary record.
   ```
   summary := LET aliceCart   == orders["alice"].cart
                  totalQty    == aliceCart["apple"] + aliceCart["bread"] + aliceCart["coffee"]
                  paid        == PaidSet
                  stockedAlice == {i \in Items : aliceCart[i] > 0}
              IN [total |-> totalQty,
                  paidCustomers |-> paid,
                  nPaid |-> Cardinality(paid),
                  allItems |-> stockedAlice];
   phase := phase + 1;
   ```

## Check

1. **TypeOK** — see above. Combines function-set, record fields, sequences, quantifiers.
2. **EveryCartItemIsKnown** — every customer's cart has the same item domain.
3. **SomeoneHasOpened** — every customer's history starts with `"opened"`, so this is always true. (Existential.)
4. **EndsCorrect**:
   ```
   phase = 3 =>
     /\ summary.total = 2
     /\ summary.paidCustomers = {"alice"}
     /\ summary.nPaid = 1
     /\ summary.allItems = {"apple"}
   ```

## Expected Result

- TLC reports **4 distinct states** (one per `phase` value).
- All four invariants pass.
- After phase 3, the summary record is exactly:
  ```
  [total |-> 2, paidCustomers |-> {"alice"}, nPaid |-> 1, allItems |-> {"apple"}]
  ```

  Trace through by hand: alice gets 2 apples (total = 2 because bread and coffee are still 0), alice pays (history = `<<"opened", "paid">>`, so `HasPaid("alice") = TRUE`), bob never pays. The filter set is `{"alice"}`. The map-via-filter `stockedAlice` is `{"apple"}` (the only item with positive qty).

**Bonus.** Add a fourth label `shipAlice` that appends `"shipped"` to alice's history. Update `EndsCorrect` for `phase = 4`. The shape is the same as `payAlice`; you're testing your fluency, not learning new syntax.

## Hints

??? hint "💡 Hint 1 — Nested EXCEPT for nested records"
    Alice's cart is a FIELD of her order record, which is an ENTRY in the `orders` function. To update apple qty in alice's cart, use two EXCEPT layers: outer updates alice's record, inner updates the apple entry. The pattern `[orders EXCEPT !["alice"].cart = [@ EXCEPT !["apple"] = @ + 2]]` has TWO `@`s, each scoped to its own EXCEPT.

??? hint "💡 Hint 2 — Append for sequences"
    Alice's history is a SEQUENCE. To add an event, use `Append(@, "paid")` — the outer EXCEPT applies to the history field, and Append adds to the sequence. So `[orders EXCEPT !["alice"].history = Append(@, "paid")]` appends "paid" to alice's event log.

??? hint "💡 Hint 3 — Capstone composes all of T09–T24"
    The `summarize` label builds a RECORD (T09) with computed fields. Use `LET` (T23) to name intermediate values. The `total` sums function lookups (T13). The `paidCustomers` is a FILTER (T17) using an existential quantifier (T24). The `nPaid` uses CARDINALITY (T20). The `allItems` is a FILTER (T17) on the items with qty > 0. Every piece is a tool from earlier puzzles.
