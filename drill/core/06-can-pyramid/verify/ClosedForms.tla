---- MODULE ClosedForms ----
\* Acceptable variant: the closed forms in place of the recursion.
\* It passes identically and exercises none of the three constructs
\* the item is for.
EXTENDS Naturals

CONSTANTS Width, MaxRows

VARIABLES style, rows, cans

vars == <<style, rows, cans>>

RowCount(k) == IF style = "pyramid" THEN k ELSE Width

TypeOK ==
  /\ style \in {"pyramid", "wall"}
  /\ rows \in 0..MaxRows
  /\ cans \in Nat

Init ==
  /\ style \in {"pyramid", "wall"}
  /\ rows = 0
  /\ cans = 0

AddRow ==
  /\ rows < MaxRows
  /\ rows' = rows + 1
  /\ cans' = cans + RowCount(rows + 1)
  /\ UNCHANGED style

RemoveRow ==
  /\ rows > 0
  /\ rows' = rows - 1
  /\ cans' = cans - RowCount(rows)
  /\ UNCHANGED style

Next == AddRow \/ RemoveRow

Spec == Init /\ [][Next]_vars

CansMatchRule ==
  cans = IF style = "pyramid" THEN (rows * (rows + 1)) \div 2
                              ELSE Width * rows
====
