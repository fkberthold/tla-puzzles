---- MODULE UndoNewestFirstAdmits ----
\* The newest-first editor against the table.
EXTENDS UndoNewestFirst, UndoRows

TInit == hist = Rows[1][1]

TNext == \E r \in DOMAIN Rows :
  /\ hist = Rows[r][1]
  /\ hist' = Rows[r][2]

TSpec == TInit /\ [][TNext]_vars

Admits == [][Next]_vars
====
