---------------------------- MODULE DepotCover ----------------------------
(* The reference. cover is the standing list of stand-ins, a partial      *)
(* function from routes. The roster the depot runs is cover laid over the  *)
(* defaults, and in a merge the LEFT side wins on a shared key, so cover   *)
(* goes on the left. When a driver falls sick, the new stand-ins go on the *)
(* left of cover for the same reason.                                       *)
EXTENDS Naturals, TLC

Routes == 1..3
Drivers == 1..4
Default == [r \in Routes |-> r]

VARIABLES sick, cover
vars == <<sick, cover>>

Roster == cover @@ Default
Drives(d) == {r \in Routes : Roster[r] = d}
Fit == Drivers \ sick

TypeOK == /\ sick \subseteq Drivers
          /\ DOMAIN cover \subseteq Routes
          /\ \A r \in DOMAIN cover : cover[r] \in Drivers

Init == /\ sick = {}
        /\ cover = [r \in {} |-> 0]

FallSick(d) == /\ d \notin sick
               /\ sick' = sick \cup {d}
               /\ \/ /\ Drives(d) = {}
                     /\ UNCHANGED cover
                  \/ /\ Drives(d) /= {}
                     /\ \E s \in Fit \ {d} :
                          cover' = [r \in Drives(d) |-> s] @@ cover

Recover(d) == /\ d \in sick
              /\ sick' = sick \ {d}
              /\ cover' = [r \in {q \in DOMAIN cover : Default[q] /= d} |-> cover[r]]

Next == \E d \in Drivers : FallSick(d) \/ Recover(d)

Spec == Init /\ [][Next]_vars

NoSickDriverRostered == \A r \in Routes : Roster[r] \notin sick
==========================================================================
