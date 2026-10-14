---- MODULE TriageRefAdmits ----
\* Does the reference admit every row of the table? TSpec walks the table
\* and nothing else. Admits asks that each of its steps be a step of Next.
EXTENDS TriageRef, TriageRows

TInit == board = Rows[1][1][1] /\ treated = Rows[1][1][2]

TNext == \E r \in DOMAIN Rows :
           /\ <<board, treated>> = Rows[r][1]
           /\ board' = Rows[r][2][1]
           /\ treated' = Rows[r][2][2]

TSpec == TInit /\ [][TNext]_vars

Admits == [][Next]_vars
====
