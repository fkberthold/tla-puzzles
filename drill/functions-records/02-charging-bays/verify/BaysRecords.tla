---------------------------- MODULE BaysRecords ---------------------------
(* Encoding B: the bay's side, one function whose range is a record set.   *)
(* Same information as BaysTwoFns, one variable instead of two, and every  *)
(* update goes through a field path.                                        *)
CONSTANTS Bays, Vans, Empty

VARIABLE bay
vars == <<bay>>

TypeOK == bay \in [Bays -> [van: Vans \cup {Empty}, plugged: BOOLEAN]]

Parked(v) == \E b \in Bays : bay[b].van = v

Init == bay = [b \in Bays |-> [van |-> Empty, plugged |-> FALSE]]

DriveIn(v, b) == /\ bay[b].van = Empty
                 /\ ~Parked(v)
                 /\ bay' = [bay EXCEPT ![b].van = v]

DriveOut(b) == /\ bay[b].van /= Empty
               /\ ~bay[b].plugged
               /\ bay' = [bay EXCEPT ![b].van = Empty]

PlugIn(b) == /\ bay[b].van /= Empty
             /\ ~bay[b].plugged
             /\ bay' = [bay EXCEPT ![b].plugged = TRUE]

Unplug(b) == /\ bay[b].plugged
             /\ bay' = [bay EXCEPT ![b].plugged = FALSE]

Next == \/ \E v \in Vans, b \in Bays : DriveIn(v, b)
        \/ \E b \in Bays : DriveOut(b) \/ PlugIn(b) \/ Unplug(b)

Spec == Init /\ [][Next]_vars

NeverPlugEmpty == \A b \in Bays : bay[b].plugged => bay[b].van /= Empty

OneBayPerVan == \A b1, b2 \in Bays :
                  (b1 /= b2 /\ bay[b1].van /= Empty) => bay[b1].van /= bay[b2].van
==========================================================================
