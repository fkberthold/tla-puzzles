---- MODULE DeckLogHeadOnlyAdmits ----
\* The one-at-a-time neighbour against the table.
EXTENDS DeckLogHeadOnly, DeckLogRows

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
