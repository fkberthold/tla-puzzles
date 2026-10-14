# Help desk

A help desk has one counter. A customer arrives when nobody is waiting. The
clerk may step away from the counter at any time and come back at any time.
While at the counter, the clerk may serve the waiting customer, who leaves
in the same step.

The specifier has decided what the clerk owes a waiting customer, and no
more. Below are three behaviors, written as (customer, clerk) over time.
"Then forever" means the last state repeats without end. "Cycling" means
the bracketed run repeats without end.

| # | behavior | verdict |
|---|---|---|
| L1 | (waiting, present), then (waiting, present) forever | forbidden |
| L2 | ((waiting, present), (waiting, absent)) cycling | allowed |
| L3 | (nobody, present), then (nobody, present) forever | allowed |

Write the single fairness conjunct that, added to the specification, rules
out L1 and keeps L2 and L3. Then write one line saying what that conjunct
guarantees a customer, and one more saying what it doesn't.
