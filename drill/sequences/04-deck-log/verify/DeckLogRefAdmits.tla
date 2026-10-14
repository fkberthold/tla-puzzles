---- MODULE DeckLogRefAdmits ----
\* Does the reference admit every row of the table? TSpec walks the table
\* and nothing else. Admits asks that each of its steps be a step of Next.
EXTENDS DeckLogRef, DeckLogRows

TInit ==
  /\ log = Rows[1][1][1]
  /\ archive = Rows[1][1][2]
  /\ next = 1

TNext == \E r \in DOMAIN Rows :
  /\ log = Rows[r][1][1]
  /\ archive = Rows[r][1][2]
  /\ log' = Rows[r][2][1]
  /\ archive' = Rows[r][2][2]
  /\ next' = Len(Rows[r][2][1]) + Len(Rows[r][2][2]) + 1

TSpec == TInit /\ [][TNext]_vars

Admits == [][Next]_vars
====
