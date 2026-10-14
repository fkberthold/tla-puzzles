---- MODULE UndoRefAdmits ----
\* Does the reference admit every row of the table?
EXTENDS UndoRef, UndoRows

TInit == hist = Rows[1][1]

TNext == \E r \in DOMAIN Rows :
  /\ hist = Rows[r][1]
  /\ hist' = Rows[r][2]

TSpec == TInit /\ [][TNext]_vars

Admits == [][Next]_vars
====
