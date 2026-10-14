--------------------------- MODULE BaysBothSides --------------------------
(* Both sides at once: van per bay AND bay per van, kept in step. Nothing  *)
(* here is wrong. The second map records what the first already says, so   *)
(* it buys a consistency obligation and no states.                          *)
CONSTANTS Bays, Vans, Empty, Away

VARIABLES van, at, plugged
vars == <<van, at, plugged>>

TypeOK == /\ van \in [Bays -> Vans \cup {Empty}]
          /\ at \in [Vans -> Bays \cup {Away}]
          /\ plugged \in [Bays -> BOOLEAN]

Init == /\ van = [b \in Bays |-> Empty]
        /\ at = [v \in Vans |-> Away]
        /\ plugged = [b \in Bays |-> FALSE]

DriveIn(v, b) == /\ van[b] = Empty
                 /\ at[v] = Away
                 /\ van' = [van EXCEPT ![b] = v]
                 /\ at' = [at EXCEPT ![v] = b]
                 /\ UNCHANGED plugged

DriveOut(b) == /\ van[b] /= Empty
               /\ ~plugged[b]
               /\ at' = [at EXCEPT ![van[b]] = Away]
               /\ van' = [van EXCEPT ![b] = Empty]
               /\ UNCHANGED plugged

PlugIn(b) == /\ van[b] /= Empty
             /\ ~plugged[b]
             /\ plugged' = [plugged EXCEPT ![b] = TRUE]
             /\ UNCHANGED <<van, at>>

Unplug(b) == /\ plugged[b]
             /\ plugged' = [plugged EXCEPT ![b] = FALSE]
             /\ UNCHANGED <<van, at>>

Next == \/ \E v \in Vans, b \in Bays : DriveIn(v, b)
        \/ \E b \in Bays : DriveOut(b) \/ PlugIn(b) \/ Unplug(b)

Spec == Init /\ [][Next]_vars

NeverPlugEmpty == \A b \in Bays : plugged[b] => van[b] /= Empty

TwoSidesAgree == \A b \in Bays, v \in Vans : van[b] = v <=> at[v] = b
==========================================================================
