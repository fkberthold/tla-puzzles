---------------------------- MODULE TwoStep ----------------------------
(* The faithful encoding: seeing the slip and pulling the item are two   *)
(* steps with a control point between them.                              *)
CONSTANTS Pickers,
          Idle, Fetching, Done,       \* labels
          OnSpike, Taken              \* where the slip is

VARIABLES pc, slip
vars == <<pc, slip>>

Init == /\ pc = [p \in Pickers |-> Idle]
        /\ slip = OnSpike

\* Glance at the spike from the aisle. If the slip is there, go.
Glance(p) == /\ pc[p] = Idle
             /\ slip = OnSpike
             /\ pc' = [pc EXCEPT ![p] = Fetching]
             /\ UNCHANGED slip

\* Pull the item and take the slip down in the same trip.
Fetch(p) == /\ pc[p] = Fetching
            /\ pc' = [pc EXCEPT ![p] = Done]
            /\ slip' = Taken

Next == \E p \in Pickers : Glance(p) \/ Fetch(p)

Spec == Init /\ [][Next]_vars

\* The order is never picked twice.
PickedOnce == \A p, q \in Pickers :
                 pc[p] = Done /\ pc[q] = Done => p = q
=========================================================================
