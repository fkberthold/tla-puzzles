---- MODULE TriageFifoAdmits ----
\* The queue neighbour against the table.
EXTENDS TriageFifo, TriageRows

TInit == board = Rows[1][1][1] /\ treated = Rows[1][1][2]

TNext == \E r \in DOMAIN Rows :
           /\ <<board, treated>> = Rows[r][1]
           /\ board' = Rows[r][2][1]
           /\ treated' = Rows[r][2][2]

TSpec == TInit /\ [][TNext]_vars

Admits == [][Next]_vars
====
