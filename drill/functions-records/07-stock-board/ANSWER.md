# The stock board: answer

A table has two readings. By rows it's a function from lines to records.
By columns it's a record of functions from lines. Both are right, both
reach 216 states, and the two access paths are mirror images.

## By rows

`verify/StockRows.tla`.

```tla
---- MODULE StockRows ----
EXTENDS Naturals
CONSTANTS Lines, Cap

VARIABLE line
vars == <<line>>

TypeOK == line \in [Lines -> [onhand: 0..Cap, promised: 0..Cap]]

Init == line = [l \in Lines |-> [onhand |-> 0, promised |-> 0]]

Restock(l) == /\ line[l].onhand < Cap
              /\ line' = [line EXCEPT ![l].onhand = @ + 1]

Promise(l) == /\ line[l].promised < line[l].onhand
              /\ line' = [line EXCEPT ![l].promised = @ + 1]

Deliver(l) == /\ line[l].promised > 0
              /\ line' = [line EXCEPT ![l].onhand = @ - 1, ![l].promised = @ - 1]

Next == \E l \in Lines : Restock(l) \/ Promise(l) \/ Deliver(l)

Spec == Init /\ [][Next]_vars

NeverOverPromised == \A l \in Lines : line[l].promised <= line[l].onhand
====
```

```
SPECIFICATION Spec
INVARIANTS TypeOK NeverOverPromised
CHECK_DEADLOCK TRUE
CONSTANTS
  Lines = {rose, fern, ivy}
  Cap = 2
```

Reading ivy's promised count: `line[ivy].promised`, row first, then column.
Writing it: `[line EXCEPT ![ivy].promised = @ + 1]`, and the write path
mirrors the read path step for step.

Hand count. One line has six readable pairs with promised at most on hand
and on hand at most 2. Three lines, 216. TLC found 216.

## By columns

`verify/StockColumns.tla`. One record of two functions.

```tla
VARIABLE board

TypeOK == board \in [onhand: [Lines -> 0..Cap], promised: [Lines -> 0..Cap]]

Init == board = [onhand |-> [l \in Lines |-> 0], promised |-> [l \in Lines |-> 0]]

Promise(l) == /\ board.promised[l] < board.onhand[l]
              /\ board' = [board EXCEPT !.promised[l] = @ + 1]

Deliver(l) == /\ board.promised[l] > 0
              /\ board' = [board EXCEPT !.onhand[l] = @ - 1, !.promised[l] = @ - 1]
```

Reading ivy's promised count: `board.promised[ivy]`, column first, then
row. Writing it: `[board EXCEPT !.promised[ivy] = @ + 1]`. Same cell, the
path reversed, and again the write mirrors the read. rc 0 at 216.

## Flat

`verify/StockFlat.tla`. No container, two variables, each a function from
lines. Reading: `promised[ivy]`. Writing: `[promised EXCEPT ![ivy] = @ + 1]`
with `UNCHANGED onhand` beside it. rc 0 at 216.

| reading of the table | module | ivy's promised count | rc | states |
|---|---|---|---|---|
| by rows | `StockRows` | `line[ivy].promised` | rc 0 | 216 |
| by columns | `StockColumns` | `board.promised[ivy]` | rc 0 | 216 |
| flat | `StockFlat` | `promised[ivy]` | rc 0 | 216 |

Which to pick. Rows when the thing you move around is a line, and a line's
two numbers travel together, as they do in `Deliver`. Columns when you'll
want a whole column at once, say to sum what's promised across the board.
Here `Deliver` touches both columns of one row, so I'd tend to go with
rows. The flat form is what I'd write if the two columns had nothing to do
with each other, and the rule says they do.

## The neighbour that crosses the paths

`StockCrossPath` lays the board out by columns and reads it by rows:
`board[l].promised` on a record of functions. rc 75 on the first state,
evaluating the invariant: "Attempted to access record by a non-string
argument: rose". A record is a function on strings, and `board[rose]` asks
it for a key it doesn't have. The message is the whole lesson in one line.
A record's keys are its field names, and nothing else goes in the
brackets.

`StockNoGuard` has the rows right and lets `Promise` run up to the cap
without looking at the on-hand column. rc 12 on `NeverOverPromised`, three
states in.

## Acceptable variants

- Columns or flat, as measured.
- `Deliver` as two nested updates instead of two clauses. Same thing, not measured.
- A cancel action that drops a promise without delivering. Adds moves, not states, I'd expect. Not measured.

## Elimination table

| neighbour answer | what kills it |
|---|---|
| the row path on a column layout | rc 75 on the first state, measured |
| the column path on a row layout | the same message with the roles swapped. Not measured |
| no on-hand check in `Promise` | rc 12, measured |
| one function from lines to on-hand, promised kept as a total | the rule can't be written per line. Not measured |

## Why not in prompt

The prompt shows the board as a table, which is neutral between row-major
and column-major. The reader picks a reading, and the sample numbers are
there to show the shape and nothing else.

The honest caveat is the closing question. Asking how one cell is read and
written points at access paths, and a reader who has written both shapes
before will answer from memory. What that reader doesn't have is the
crossed-path message, and the fact that it fires on the first state in the
invariant and not in an action, since the invariant is the first thing to
read a cell.

## Measured runs

Each row is a line of `bash drill/functions-records/verify-all.sh 07`, with
`-d` passed because every config here asks for deadlock checking.

| module | config | rc | distinct states |
|---|---|---|---|
| `StockRows.tla` | `StockRows.cfg` | rc 0 | 216 |
| `StockColumns.tla` | `StockColumns.cfg` | rc 0 | 216 |
| `StockFlat.tla` | `StockFlat.cfg` | rc 0 | 216 |
| `StockCrossPath.tla` | `StockCrossPath.cfg` | rc 75 | 1 |
| `StockNoGuard.tla` | `StockNoGuard.cfg` | rc 12 | 3 |
