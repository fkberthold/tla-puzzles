---- MODULE UndoRefuseFullAdmits ----
\* The refuse-when-full neighbour against the table.
EXTENDS UndoRefuseFull, UndoRows

TInit == hist = Rows[1][1]

TNext == \E r \in DOMAIN Rows :
  /\ hist = Rows[r][1]
  /\ hist' = Rows[r][2]

TSpec == TInit /\ [][TNext]_vars

Admits == [][Next]_vars
====
