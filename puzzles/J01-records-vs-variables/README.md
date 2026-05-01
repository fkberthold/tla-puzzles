# J01: Judgment — Records vs Separate Variables ⭐

**Judgment puzzle.** No new syntax. The goal is to develop a reflex for *when* to bundle related state into a record vs *when* to leave it as separate top-level variables.

## The choice

You have a chunk of state — say, the four fields of an `Order`: id, quantity, paid, shipped. Two ways to model it in TLA+:

- **Side A — scattered:** four top-level variables (`orderId`, `orderQty`, `orderPaid`, `orderShipped`).
- **Side B — bundled:** one variable `order` whose value is a record `[id, qty, paid, shipped]`, accessed via `order.id` and updated via `[order EXCEPT !.paid = TRUE]`.

Both are valid. Both pass the same invariants. The difference is *cost of change* and *cost of reading*.

The two specs in `solution/` model exactly the same workflow — placing, paying, and shipping an order — one as scattered variables, one as a record. Run both and compare them.

## Run both sides

```bash
cd solution
tlc -pcal Scattered.tla && tlc Scattered
tlc -pcal Bundled.tla   && tlc Bundled
```

Both finish with **4 distinct states** and "No error has been found." Same model, same state space, same invariants pass.

## Read both sides side-by-side

The body of each `process` is the same workflow (place, pay, ship). What differs is the assignment syntax:

| Step  | Scattered                              | Bundled                                       |
|-------|----------------------------------------|-----------------------------------------------|
| place | `orderId := 1; orderQty := 2;`         | `order := [order EXCEPT !.id = 1, !.qty = 2]` |
| pay   | `orderPaid := TRUE;`                   | `order := [order EXCEPT !.paid = TRUE]`       |
| ship  | `orderShipped := TRUE;`                | `order := [order EXCEPT !.shipped = TRUE]`    |

And the invariants:

```
\* Scattered
NoUnpaidShip == orderShipped => orderPaid

\* Bundled
NoUnpaidShip == order.shipped => order.paid
```

Same content. Different cost of *adding a fifth field*.

## When to choose scattered (Side A)

- Each piece of state has its **own life cycle** and is updated independently — variables are rarely modified together.
- The "thing" doesn't really exist as a unit in your domain. Two of the variables happen to live near each other but aren't siblings.
- You only have **2–3 pieces** and they'll never grow.
- You want each variable to stand out individually in TLC error traces (TLC prints scattered variables as separate lines).

## When to choose bundled / record (Side B)

- The fields **belong together** as a unit in the domain — they're describing one entity (an Order, a Request, a Connection, a Page).
- You'll frequently want to talk about "the whole thing" — pass it to operators, compare two of them, or store many of them in a function `requests \in [RequestId -> Request]`.
- The set of fields **will probably grow**. Adding `order.priority` is a one-line change to the record literal; adding `orderPriority` requires touching every `UNCHANGED` clause and every `vars` tuple.
- You want operators to read like the domain: `IsReady(order) == order.paid /\ ~order.shipped` reads naturally.

## The trade-off

**Scattered** wins on *distinctness*: each variable is its own thing in the spec, in the cfg's `INVARIANT` lines, and in the TLC trace. You don't pay the EXCEPT/dot-access syntax tax. The cost shows up later: every new field rewires several `UNCHANGED` lists and the `vars` tuple, and any operator that "operates on the whole thing" has to take all four pieces as parameters.

**Bundled** wins on *grouping*: one variable, one place to add fields, one parameter to pass. The cost is syntactic — `order.field` to read, `[order EXCEPT !.field = ...]` to update — and TLC traces show one big record per state instead of four crisp fields. With only one or two fields, that overhead isn't worth it.

A useful rule of thumb: **if you'd put it in a struct in code, put it in a record in TLA+.** If two pieces of state are unrelated and just happen to live in the same spec, leave them apart.

## Generalize the reflex

Apply the same lens whenever you see scattered state:

- A `Connection` with `host`, `port`, `state`, `lastSeen` → **record**, almost always. These travel together.
- A spec with `serverUp` (boolean) and `requestsPending` (number) → **scattered**. Different lifecycles, different shapes; bundling adds friction with no win.
- An array of structured items: `requests` indexed by id, each with several fields → **function from id to record**, e.g. `requests \in [RequestId -> [status: ..., body: ...]]`. This is bundled-by-default for free.

When in doubt, ask: *"would I want to add a fifth field next month?"* If yes, bundle. If the four fields are independent and the answer is "what fifth field?", scatter is fine.

Done. The next judgments concern bigger choices — PlusCal vs pure TLA+ (J02), TLC vs Apalache (J03), and so on.
