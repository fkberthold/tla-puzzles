----------------------- MODULE BaysTwoFnsNoParkedGuard --------------------
(* Encoding A with the obligation it owes left unguarded: DriveIn never     *)
(* asks whether the van is already in a bay, so one van ends up in two.    *)
CONSTANTS Bays, Vans, Empty

VARIABLES van, plugged
vars == <<van, plugged>>

TypeOK == /\ van \in [Bays -> Vans \cup {Empty}]
          /\ plugged \in [Bays -> BOOLEAN]

Init == /\ van = [b \in Bays |-> Empty]
        /\ plugged = [b \in Bays |-> FALSE]

DriveIn(v, b) == /\ van[b] = Empty
                 /\ van' = [van EXCEPT ![b] = v]
                 /\ UNCHANGED plugged

DriveOut(b) == /\ van[b] /= Empty
               /\ ~plugged[b]
               /\ van' = [van EXCEPT ![b] = Empty]
               /\ UNCHANGED plugged

PlugIn(b) == /\ van[b] /= Empty
             /\ ~plugged[b]
             /\ plugged' = [plugged EXCEPT ![b] = TRUE]
             /\ UNCHANGED van

Unplug(b) == /\ plugged[b]
             /\ plugged' = [plugged EXCEPT ![b] = FALSE]
             /\ UNCHANGED van

Next == \/ \E v \in Vans, b \in Bays : DriveIn(v, b)
        \/ \E b \in Bays : DriveOut(b) \/ PlugIn(b) \/ Unplug(b)

Spec == Init /\ [][Next]_vars

NeverPlugEmpty == \A b \in Bays : plugged[b] => van[b] /= Empty

OneBayPerVan == \A b1, b2 \in Bays :
                  (b1 /= b2 /\ van[b1] /= Empty) => van[b1] /= van[b2]
==========================================================================
