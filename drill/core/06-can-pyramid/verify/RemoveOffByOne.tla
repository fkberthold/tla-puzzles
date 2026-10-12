---- MODULE RemoveOffByOne ----
\* Seeded defect: RemoveRow takes away the count of the row below the
\* one being removed.
EXTENDS Naturals

CONSTANTS Width, MaxRows

VARIABLES style, rows, cans

vars == <<style, rows, cans>>

RECURSIVE Total(_, _)
Total(RowCount(_), n) ==
  IF n = 0 THEN 0 ELSE RowCount(n) + Total(RowCount, n - 1)

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
  /\ cans' = cans - RowCount(rows - 1)
  /\ UNCHANGED style

Next == AddRow \/ RemoveRow

Spec == Init /\ [][Next]_vars

CansMatchRule ==
  cans = IF style = "pyramid" THEN Total(LAMBDA k : k, rows)
                              ELSE Total(LAMBDA k : Width, rows)
====
