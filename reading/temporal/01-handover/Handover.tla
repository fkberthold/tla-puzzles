---- MODULE Handover ----
EXTENDS Naturals, FiniteSets

CONSTANT Site
ASSUME Cardinality(Site) > 1

VARIABLES holder, want
vars == <<holder, want>>

TypeOK ==
  /\ holder \in Site
  /\ want \in BOOLEAN

Init == holder \in Site /\ want = FALSE

Request ==
  /\ ~want
  /\ want' = TRUE
  /\ UNCHANGED holder

Grant ==
  /\ want
  /\ \E s \in Site \ {holder} : holder' = s
  /\ want' = FALSE

Next == Request \/ Grant

Spec == Init /\ [][Next]_vars /\ WF_vars(Grant)

Served == want ~> ~want

MovesOnlyWhenAsked ==
  [][holder' # holder => want]_vars
====
