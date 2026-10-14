# Undo history

A drawing program keeps a short undo history. There are four kinds of
edit, a, b, c and d, and the same kind can happen any number of times.

The table shows one session. Each row is the history after one step,
oldest edit on the left.

| step | history | what happened |
|---|---|---|
| 0 | empty | the program opened |
| 1 | a | an edit |
| 2 | a, b | an edit |
| 3 | a, b, c | an edit |
| 4 | b, c, d | an edit |
| 5 | b, c | undo |
| 6 | b, c, a | an edit |
| 7 | b, c | undo |
| 8 | b | undo |

Write a module from an empty file that admits this session. State the rule
that the history never holds more than three edits.
