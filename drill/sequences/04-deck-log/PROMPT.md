# Deck log

A ship's deck log is written one entry at a time, and the entries are
numbered 1, 2, 3 and so on in the order they're written. Now and then the
mate archives some of the oldest entries: they move from the log to the
end of the harbour copy in one go, still in order. This voyage has five
entries in it.

The table shows the voyage. Each row is the log and the harbour copy after
one step, oldest entry on the left.

| step | log | harbour copy | what happened |
|---|---|---|---|
| 0 | empty | empty | cast off |
| 1 | 1 | empty | an entry was written |
| 2 | 1, 2 | empty | an entry was written |
| 3 | 1, 2, 3 | empty | an entry was written |
| 4 | 3 | 1, 2 | the mate archived |
| 5 | 3, 4 | 1, 2 | an entry was written |
| 6 | 3, 4, 5 | 1, 2 | an entry was written |
| 7 | empty | 1, 2, 3, 4, 5 | the mate archived |

Write a module from an empty file that admits this voyage. State the rule
that the harbour copy always reads 1, 2, 3 and so on from the start, and
the log carries on from wherever the copy stops. Say what bounds the
model.
