---- MODULE PileWholeAdmits ----
\* The whole-pile neighbour against the table.
EXTENDS PileWhole, PileRows

TInit == pile = Rows[1][1]

TNext == \E r \in DOMAIN Rows :
  /\ pile = Rows[r][1]
  /\ pile' = Rows[r][2]

TSpec == TInit /\ [][TNext]_vars

Admits == [][Next]_vars
====
