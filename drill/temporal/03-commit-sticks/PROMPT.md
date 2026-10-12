# Commit sticks

A transaction has a status: pending, committed, or aborted.

Below are five behaviours of the status. "Then forever" means the last
status repeats without end.

| # | status, over time | verdict |
|---|---|---|
| 1 | pending, pending, committed, then committed forever | allowed |
| 2 | pending, then pending forever | allowed |
| 3 | pending, aborted, then aborted forever | allowed |
| 4 | pending, committed, pending, then pending forever | forbidden |
| 5 | pending, committed, aborted, then aborted forever | forbidden |

Write the one temporal property that admits every allowed behaviour and
rejects every forbidden one. Then answer in one sentence: can a finite
prefix of a behaviour refute your property?
