---- MODULE LbChoose ----
\* The trap. Forward picks the upstream with CHOOSE, which is a value, not a
\* branch. Every forward over the same health list gets the same upstream,
\* so the colleague's claim holds on this model and TLC says so.

CONSTANTS Upstreams, Ids

VARIABLES healthy, waiting, inflight

vars == <<healthy, waiting, inflight>>

InFlightIds == {p[1] : p \in inflight}

TypeOK ==
  /\ healthy \subseteq Upstreams
  /\ waiting \subseteq Ids
  /\ inflight \subseteq Ids \X Upstreams

Init ==
  /\ healthy \in SUBSET Upstreams
  /\ healthy /= {}
  /\ waiting = {}
  /\ inflight = {}

Arrive ==
  /\ \E r \in Ids \ (waiting \cup InFlightIds) :
       waiting' = waiting \cup {r}
  /\ UNCHANGED <<healthy, inflight>>

Forward ==
  /\ \E r \in waiting :
       LET u == CHOOSE x \in healthy : TRUE
       IN /\ waiting' = waiting \ {r}
          /\ inflight' = inflight \cup {<<r, u>>}
  /\ UNCHANGED healthy

Complete ==
  /\ \E p \in inflight : inflight' = inflight \ {p}
  /\ UNCHANGED <<healthy, waiting>>

Next == Arrive \/ Forward \/ Complete

Spec == Init /\ [][Next]_vars

OnlyHealthy == \A p \in inflight : p[2] \in healthy

NoDoubleBooking ==
  /\ waiting \cap InFlightIds = {}
  /\ \A p, q \in inflight : p[1] = q[1] => p = q

Claim == \A p, q \in inflight : p[2] = q[2]
====
