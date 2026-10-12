# Flaky link

A sender holds one message for a peer across a link. The link goes down and
comes back up on its own, at any time. Nothing in the system can hold it up
or bring it back. Delivery takes one step and is possible only while the
link is up.

The specifier has decided what the sender owes the message. Below are three
behaviours, written as (link, message) over time. "Then forever" means the
last state repeats without end. "Cycling" means the bracketed run repeats
without end.

| # | behaviour | verdict |
|---|---|---|
| L1 | (up, pending), then (up, pending) forever | forbidden |
| L2 | ((up, pending), (down, pending)) cycling | forbidden |
| L3 | (down, pending), then (down, pending) forever | allowed |

Write the single fairness conjunct that, added to the specification, rules
out the two forbidden behaviours and keeps the allowed one. Then write, in
one line, the delivery guarantee that conjunct buys.
