# T49: Tier 5 Capstone — Request/Response System ⭐⭐⭐

## Lesson: Capstone — Composing Tier 5

No new concept. This puzzle asks you to use everything from Tier 5 in a single spec:

- **R08** — quantifiers inside temporal properties (`\A c \in Clients : ...`)
- **R09** — `fair process` so weak-fairness conjuncts get added
- **T42** — conjunctions of `<>` properties for multiple eventualities
- **T43** — `[]Inv` as PROPERTY when invariant-style claims live alongside richer temporal claims
- **T44** — `~>` leads-to for request/response
- **T45** — `[]<>` infinitely often for periodic behavior
- **T46** — `<>[]` eventually always for stabilization-style claims (we won't need this one in the spec — it's a contrast point)
- **T47** — `fair+ process` (strong fairness) for actions whose enabledness flickers
- **T48** — read a liveness violation, identify which process needs which fairness, fix

**Worked recap — a coffee shop with a barista and named customers.**

Customers in `{"Ana", "Bo"}` walk up to the counter, place an order, wait, get served, and leave. The barista works one order at a time. The shop's claims:

```
\* every order eventually served (leads-to, quantified over customers)
EachOrderServed ==
  \A c \in Customers : (orderFor = c) ~> (served[c] = TRUE)

\* the barista returns to idle infinitely often (so they're not stuck)
BaristaResets == []<>(busy = FALSE)
```

Mechanics:

- The customer `c` action `place` requires `orderFor = NULL`; it sets `orderFor := c`. This action's enabledness flickers (other customers' orders disable it). Customer is `fair+ process`.
- The barista `serve` action requires `orderFor # NULL`; it sets `served[orderFor] := TRUE`, then `orderFor := NULL`. The barista's enabledness flickers (only enabled when an order is pending). Barista is `fair+ process`.
- Cap each customer at one order so the state space is finite.

Both actions need SF because each one disables itself by firing. With WF only, TLC could find unfair behaviors where the same customer monopolizes the slot or where the barista never picks up a particular order. SF guarantees: any action repeatedly enabled fires.

In the cfg:

```
SPECIFICATION Spec
INVARIANT TypeOK
PROPERTY EachOrderServed
PROPERTY BaristaResets
CHECK_DEADLOCK FALSE
```

This composition uses leads-to (T44), infinitely-often (T45), and strong fairness (T47) together. If you write any one of them with the wrong shape, TLC catches it: `=>` instead of `~>` makes leads-to vacuous (T44 strip test); `<>` instead of `[]<>` allows the barista to stop after one order (T45 strip test); `fair` instead of `fair+` lets one customer starve (T47 strip test).

The puzzle below is the same kind of composition — different domain, same toolkit.

## Setup

A small web server handles requests from two clients. Each client puts in a request when it has none in flight; the server picks up a pending request, processes it, and clears the slot. The server has a single processing slot.

Properties to verify:

- **Type**: variables stay in their declared types.
- **EveryRequestServed**: for each client, every request `c` makes leads to a response `c` receives. (`\A c : pending[c] ~> served[c]`)
- **ServerStaysAvailable**: the server returns to idle infinitely often.

## Task

Write a PlusCal spec with:

- `Clients == {"c1", "c2"}` (CONSTANT-style, but defined as a literal set in the `define` block)
- Variables:
  - `pending = [c \in {"c1", "c2"} |-> FALSE]` — has client `c` an outstanding request?
  - `served = [c \in {"c1", "c2"} |-> FALSE]` — has client `c` been served at least once?
  - `slot = "empty"` — the server's single processing slot, holds a client id when occupied
- A `define` block with:
  - `Clients == {"c1", "c2"}`
  - `TypeOK == /\ pending \in [Clients -> BOOLEAN] /\ served \in [Clients -> BOOLEAN] /\ slot \in (Clients \cup {"empty"})`
  - `EveryRequestServed == \A c \in Clients : (pending[c] = TRUE) ~> (served[c] = TRUE)`
  - `ServerStaysAvailable == []<>(slot = "empty")`
- A client process indexed over `Clients`. Use `fair+ process` (SF) because each client's action gets disabled while their request is in flight. The client loop:
  - `await pending[self] = FALSE /\ served[self] = FALSE` (only ask once until served)
  - `pending[self] := TRUE`
  - `await served[self] = TRUE` (wait for the response — handled by the server clearing pending and setting served)
- A server process. Use `fair+ process` (SF) because the server's action requires SOME pending request, an intermittent condition. The server loop:
  - `await slot = "empty" /\ \E c \in Clients : pending[c] = TRUE`
  - `with (c \in {c \in Clients : pending[c] = TRUE}) { slot := c }` (pick a pending client)
  - `served[slot] := TRUE`
  - `pending[slot] := TRUE`  ← wait, this is wrong; we need to clear it
  - The right shape: clear `pending[slot]`, set `served[slot]`, then `slot := "empty"`. Order them across labels carefully.

The server flow in three labels:

```
pick:    await slot = "empty" /\ \E c \in Clients : pending[c];
         with (c \in {x \in Clients : pending[x]}) { slot := c };
respond: served[slot] := TRUE;
         pending[slot] := FALSE;
free:    slot := "empty";
```

(Or, for less label proliferation, fold the three statements into one label since they don't race. `pick` plus `respond` plus `free` all in one labeled block is fine — pcal will treat them as atomic.)

In `Server.cfg`:

```
SPECIFICATION Spec
INVARIANT TypeOK
PROPERTY EveryRequestServed
PROPERTY ServerStaysAvailable
CHECK_DEADLOCK FALSE
```

`CHECK_DEADLOCK FALSE` because each client only requests ONCE (we cap to keep the state space finite); after both clients have been served, the system goes quiescent.

## Check

1. **TypeOK** holds.
2. **EveryRequestServed** holds — every request from every client leads to a response.
3. **ServerStaysAvailable** holds — server returns to idle infinitely often (in particular, eventually-always, since once both clients are done, slot is empty forever).

## Expected Result

- TLC should report `No error has been found`. The canonical solution explores 40 distinct states with the three-label server (`spick`, `srespond`, `sfree`) and two clients; your spec may produce more if you adjust label boundaries — that's fine, the behavior is what matters.
- All three checks pass with `fair+ process` on both client and server.
- **Composition checks (do these to convince yourself the puzzle is honest):**
  - **T44 strip**: replace `~>` with `=>` in `EveryRequestServed`. The check becomes vacuous (passes for the wrong reason — the implication is checked only at the initial state where nothing is pending). The result still passes; the property became toothless.
  - **T45 strip**: replace `[]<>(slot = "empty")` with `<>(slot = "empty")`. Still passes — but now allows behaviors where the server processes one request and then halts forever with `slot = "empty"` (which is technically still <>"empty" satisfied). To see a real difference, swap to `<>[](slot = "empty")` (eventually always) — passes too because `slot` does end up "empty" forever after both clients done. The genuine `[]<>` shape catches mid-behavior re-occupations, which are present here while requests are in flight.
  - **T47 strip**: change `fair+ process (server ...)` to `fair process (server ...)`. With WF, TLC may find a behavior where the server is enabled infinitely often (a request keeps appearing) but never serves. The lasso shape depends on TLC's exact fairness analysis; the source change is the lesson.
- The capstone shows leads-to, infinitely-often, and strong fairness composing into one spec. Each piece carries weight: removing any one breaks a real property.

## Hints

??? hint "💡 Hint 1 — Quantified leads-to"
    Your `EveryRequestServed` property is a UNIVERSAL claim: for each client, their pending request leads to a response. That's `\A c \in Clients : (pending[c] = TRUE) ~> (served[c] = TRUE)`. Why does the quantifier sit OUTSIDE the `~>`?

??? hint "💡 Hint 2 — Two processes, both `fair+`"
    Both the client and server processes should use `fair+` (strong fairness). Why? Each action disables itself when it fires: the client's action clears `pending` (disables itself), and the server's action clears `slot` (disables itself). That's the pattern that needs SF.

??? hint "💡 Hint 3 — Correct server flow across labels"
    The server's three-label sequence must: (1) pick a pending client and put them in `slot`, (2) set `served[slot]` and clear `pending[slot]`, (3) reset `slot` to "empty." The order matters. Why must `pending` be cleared BEFORE `slot`?

??? hint "💡 Hint 4 — The property checklist"
    Before submitting, verify your spec contains: (a) `TypeOK` as an invariant, (b) `EveryRequestServed` as a property with `~>`, (c) `ServerStaysAvailable` with `[]<>`, and (d) `fair+ process` on both client and server.
