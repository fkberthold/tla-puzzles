---- MODULE LbSubseteqInit ----
\* Accepted variant, and a measurement I expected to go the other way. Init
\* states that the health list is a subset of the upstreams, which reads as
\* a sentence about a value rather than a set to draw one from. TLC takes it
\* as a draw from the powerset anyway and finds the same 398 states.

CONSTANTS Upstreams, Ids

VARIABLES healthy, waiting, inflight

vars == <<healthy, waiting, inflight>>

InFlightIds == {p[1] : p \in inflight}

TypeOK ==
  /\ healthy \subseteq Upstreams
  /\ waiting \subseteq Ids
  /\ inflight \subseteq Ids \X Upstreams

Init ==
  /\ healthy \subseteq Upstreams
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
