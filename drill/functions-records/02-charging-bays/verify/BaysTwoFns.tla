---------------------------- MODULE BaysTwoFns ----------------------------
(* Encoding A: the bay's side, two functions. van says which van is in     *)
(* each bay, plugged says whether that bay's charger is connected.          *)
(* "A bay holds one van" is free, since van is a function. "A van is in     *)
(* one bay" is an obligation and has to be guarded and stated.              *)
CONSTANTS Bays, Vans, Empty

VARIABLES van, plugged
vars == <<van, plugged>>

TypeOK == /\ van \in [Bays -> Vans \cup {Empty}]
          /\ plugged \in [Bays -> BOOLEAN]

Parked(v) == \E b \in Bays : van[b] = v

Init == /\ van = [b \in Bays |-> Empty]
        /\ plugged = [b \in Bays |-> FALSE]

DriveIn(v, b) == /\ van[b] = Empty
                 /\ ~Parked(v)
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
