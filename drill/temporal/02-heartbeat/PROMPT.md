# Heartbeat

A monitor watches a peer. Each heartbeat the peer sends carries a sequence
number that wraps at 3, so the numbers run 0, 1, 2, 0, 1, 2. The monitor
stores the number from the most recent heartbeat it received. It can miss
heartbeats, so consecutive stored numbers need not be consecutive. A
heartbeat counts as received when the stored number changes.

Below are five behaviours of the stored number. "Then forever" means the
last value repeats without end. "Cycling" means the bracketed run repeats
without end.

| # | stored number, over time | verdict |
|---|---|---|
| 1 | (0, 1, 2) cycling | allowed |
| 2 | 0, 1, then 1 forever | forbidden |
| 3 | 0, then 0 forever | forbidden |
| 4 | (0, 1) cycling | allowed |
| 5 | 0, then (1, 2) cycling | allowed |

Write the one temporal property that says the peer keeps sending
heartbeats. It must admit every allowed behaviour and reject every
forbidden one.
