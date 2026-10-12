# 08 wrong-label: answer

The paying action is wrong, and what is wrong is the label it writes. A
customer goes from `arrived` to `washing` in the step that takes their
money, and the bay stays `free` while they do. The update that advances
the customer's control state names the label two steps ahead. Everything
else in the trace follows from that: nobody is ever `paid`, so the entry
action never fires, so the bay is never marked busy, so the second
customer's payment puts a second car in a bay the model thinks is empty.

## The wrong action and the right one

`verify/WrongLabel.tla` is the spec that produced the trace. Its paying
action:

```tla
Pay(c) == /\ pc[c] = Arrived
          /\ till' = till + 1
          /\ pc' = [pc EXCEPT ![c] = Washing]       \* should be Paid
          /\ UNCHANGED bay
```

The corrected action, `verify/CarWash.tla`:

```tla
Pay(c) == /\ pc[c] = Arrived
          /\ till' = till + 1
          /\ pc' = [pc EXCEPT ![c] = Paid]
          /\ UNCHANGED bay
```

To fit a spec he has not seen, the action needs: a guard on the payer's
own label, an update to the payer's own entry and nobody else's, the
till bumped, and the bay left alone. The rest of the spec is in
`verify/CarWash.tla` for reference, with `Enter` guarded on `pc[c] =
Paid /\ bay = Free` and `Leave` on `pc[c] = Washing`.

**Measured.** The trace in the prompt is TLC's own, with the model values
lower-cased and the action names paraphrased (`verify-all.sh` row
`08-WrongLabel`: rc 12, `OneInTheBay` violated, 5 distinct states found at
the point of failure). The corrected spec: rc 0, 15 distinct states (row
`08-CarWash`).

## Reading the trace

What the trace says, column by column.

- Customer 1 is `washing` in state 2, and the action that got them there
  is "customer 1 pays". So the paying action writes `washing`.
- The bay is `free` in state 2 with a customer washing. So the paying
  action does not touch the bay, which is right for a paying action, and
  no entry action has run, which means no entry action was enabled. The
  entry action is guarded on `paid`, and nobody is ever `paid`.
- The till is 1, then 2. The second rule holds throughout: one customer
  past the kiosk per payment. So the till update is right and the bug is
  not in the money.
- Nothing in the trace shows `paid` at all. A label the procedure has and
  the trace never visits is the label being skipped.

That last point is the general tool. In a hand-rolled control-state
spec, the labels the trace never shows are the first thing to list.

## The other mistakes, and their traces

Every neighbour is a one-line change to `CarWash.tla`, measured. The
config is shared, with `OneInTheBay` listed before `PaidFor`, so TLC
reports the first rule when both fail in the same state.

| module | the mistake | first rule violated | trace length | how the trace differs from the prompt's |
|---|---|---|---|---|
| `NoGuard` | `Enter` has no `pc[c] = Paid` guard | `PaidFor`, rc 12 | 2 states | customer 1 is `washing` with the **bay busy** and the **till at 0**. The entry action ran. Nobody paid. The second rule fails, not the first. |
| `Rebuilt` | `Pay` rebuilds `pc` for every customer, `[d \in Customers \|-> Paid]`, instead of `EXCEPT` | `PaidFor`, rc 12 | 2 states | **both** customers are `paid` after one payment, bay free, till 1. The second rule fails, not the first. |
| `BayFree` | `Enter` forgets `bay' = Busy` | `OneInTheBay`, rc 12 | 5 states | the first rule fails, as in the prompt, and the bay is `free` throughout, as in the prompt. The difference is that each customer is `paid` before `washing`. The trace visits the label the prompt's never does. |
| `WrongLabel` | `Pay` writes `Washing` | `OneInTheBay`, rc 12 | 3 states | the prompt's trace. |

So the one other mistake that violates the *first* rule is `BayFree`, and its
trace differs by passing through `paid`. `NoGuard` and `Rebuilt` violate the second
rule first. A reader who answered "the entry action lacks its guard" has
not read the bay column: the bay is `free`, so no entry action ran.

| state | `BayFree` | c1 | c2 | bay | till |
|---|---|---|---|---|---|
| 1 | | Arrived | Arrived | Free | 0 |
| 2 | Pay(c1) | Paid | Arrived | Free | 1 |
| 3 | Enter(c1) | Washing | Arrived | Free | 1 |
| 4 | Pay(c2) | Washing | Paid | Free | 2 |
| 5 | Enter(c2) | Washing | Washing | Free | 2 |

## Why this mistake and not the translator's

The translator cannot write this bug. A PlusCal label's successor is the
next label in the text, and the translator computes it. By hand, every
`pc' = [pc EXCEPT ![c] = L]` names its successor explicitly, and a
copy-paste from the entry action into the paying action leaves `Washing`
where `Paid` should be. Neighbour `Rebuilt` is the other bug the translator
cannot write: the function constructor in place of `EXCEPT`, which
advances everyone. Both are raw-TLA+-only mistakes, and this item exists
because the decision to write raw TLA+ makes them his.

## Acceptable variants

- **Naming the mistake as "the label after `Arrived` should be `Paid`"**
  without the word `EXCEPT`. The mechanism is the point, and that names it.
- **Writing the corrected action with `UNCHANGED <<bay>>`** or a
  `Trans(c, Arrived, Paid)` helper. Equivalent.
- **Naming `Rebuilt` as the other mistake** is half right: it is a real
  raw-TLA+ bug, and it is one the trace rules out, because customer 2 is
  still `arrived` in state 2. It violates the second rule first, not the
  first.
- **Naming `NoGuard`** is wrong for the reason in the table, and the bay column
  is what says so.

## why-not-in-prompt

This item shows a trace, and the trace is most of the answer. The honest
caveat is that a reader who reads the second row carefully has the bug
in under a minute: "pays" and "washing" in the same row is the
diagnosis. What the item adds is the second and third questions. Writing
the corrected action from nothing is production, and it is where the
`EXCEPT`-on-the-payer shape has to come from his hand. Naming another
mistake and its trace is the elimination step, and it is the part that
takes the ten minutes, because `NoGuard` is the tempting wrong answer and the
bay column is the only thing that refutes it.

No TLA+ appears in the prompt. The labels are lower-cased English and the
action names are paraphrased. The trace was transcribed from TLC's output
and the transcription was checked against `verify-all.sh` row
`08-WrongLabel`.

## Measured runs

Every row is a line of `drill/control-state/verify-all.sh`. One config per
module, run with one worker, no trace spillage. The five configs are
identical.

| module | config | rc | distinct states |
|---|---|---|---|
| WrongLabel.tla | WrongLabel.cfg | rc 12 | 5 |
| NoGuard.tla | NoGuard.cfg | rc 12 | 3 |
| Rebuilt.tla | Rebuilt.cfg | rc 12 | 2 |
| BayFree.tla | BayFree.cfg | rc 12 | 12 |
| CarWash.tla | CarWash.cfg | rc 0 | 15 |
