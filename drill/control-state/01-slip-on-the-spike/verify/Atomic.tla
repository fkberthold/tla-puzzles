---------------------------- MODULE Atomic -----------------------------
(* The other encoding: seeing the slip and taking it are one step. This  *)
(* is faithful only once the spike has been moved onto the shelf.        *)
CONSTANTS Pickers,
          Idle, Done,                 \* labels
          OnSpike, Taken              \* where the slip is

VARIABLES pc, slip
vars == <<pc, slip>>

Init == /\ pc = [p \in Pickers |-> Idle]
        /\ slip = OnSpike

\* See the slip and take it, with the item, in one motion.
SeeAndTake(p) == /\ pc[p] = Idle
                 /\ slip = OnSpike
                 /\ pc' = [pc EXCEPT ![p] = Done]
                 /\ slip' = Taken

Next == \E p \in Pickers : SeeAndTake(p)

Spec == Init /\ [][Next]_vars

PickedOnce == \A p, q \in Pickers :
                 pc[p] = Done /\ pc[q] = Done => p = q
=========================================================================
