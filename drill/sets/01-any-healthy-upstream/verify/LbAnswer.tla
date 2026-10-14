---- MODULE LbAnswer ----
\* Reference answer. The balancer forwards a waiting request to any healthy
\* upstream, so the pick is an existential inside the action. Claim is the
\* colleague's assertion, and on this model it's false.

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
  /\ \E r \in waiting, u \in healthy :
       /\ waiting' = waiting \ {r}
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
