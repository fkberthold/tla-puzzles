# The car wash trace

A self-service car wash with one bay. A customer arrives, pays at the
kiosk, enters the bay when it is free, washes, and leaves, and the bay is
free again. The till counts payments.

Two rules.

- **One car in the bay at a time.**
- **Every customer who is past the kiosk is covered by a payment in the
  till.**

Somebody has written a specification of this in raw TLA+, with one label
per step of the visit, and TLC reports that the first rule is violated.
Here is the trace, for two customers. Each customer's column is where they
are in the visit.

| state | what happened | customer 1 | customer 2 | bay | till |
|---|---|---|---|---|---|
| 1 | start | arrived | arrived | free | 0 |
| 2 | customer 1 pays | washing | arrived | free | 1 |
| 3 | customer 2 pays | washing | washing | free | 2 |

Say which action is wrong, and what exactly is wrong in it. Then write
that action correctly, in raw TLA+, so that it would fit the rest of a
specification you have not seen.

Finally, name one other mistake in a specification of this shape that
would also violate the first rule, and say how its trace would differ from
the one above.
