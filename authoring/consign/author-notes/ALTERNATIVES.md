# Consign reference: the representations I didn't pick

The spec holds one variable, `standing`, a function from item to one of the
five standings. This note records the alternatives I weighed and where each
one lost. Author-only output (V2-PLAN §9.4). Keep it off every path a blind
agent can reach.

## Five sets, one per standing

Five variables, each the set of items in that standing. The draw is that
"one standing each" becomes a live partition invariant instead of a typing
fact, and on the chosen form that check is close to vacuous on the reference.
I don't think that's a loss worth paying for. The cost side is five variables,
an `UNCHANGED` clause in every action, and a partition an author can break by
forgetting one set. The reference should make the rules hard to state wrongly.
Property 2 earns its keep against learner specs, not against mine.

## A place field beside a ledger

Where the item sits (home, floor, gone) in one variable, what the shop owes
in another. It mirrors how the shop would talk, and it was the tempting one.
The gap: two variables now track one fact, so the model admits states where
the ledger and the places disagree. The observable can't show the drift (the
interface stops at the book's face, by design). A representation that
can't express the drift beats one that has to carry an invariant forbidding
it. Sold-means-owed and settled-means-paid fold the ledger into the standing
for free.

## An event log

A sequence of intake, sale, return, and settlement events, with standings
derived by folding the log. History would make the till's wholeness readable
straight off the trace. TLC pays for that in state: the log grows without
bound and any cap is an artifact of the checker, not the shop. The standing
function is the quotient of the log that the properties actually need.

## Collapsing the terminal standings

Fold `returned` and `settled` into one done state, since neither moves again.
It shrinks the state space a little and costs the `sold` to `settled` edge
that must-be-trues 4 and 5 name outright. A per-item till mutant gets harder
to catch, not easier. Rejected fast.

One smaller choice worth recording: the standings are strings, not model
values. Strings keep `Observe` printable and comparable across specs that
never share a module, which I suspect the grading harness will lean on.
