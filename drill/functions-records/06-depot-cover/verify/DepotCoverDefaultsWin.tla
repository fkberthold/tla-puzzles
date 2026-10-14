----------------------- MODULE DepotCoverDefaultsWin ----------------------
(* The roster merge the wrong way round. Default is on the left, so on     *)
(* every route that has a stand-in the default driver still wins, and the  *)
(* stand-in list is decoration. The first sick driver is still rostered.   *)
EXTENDS Naturals, TLC

Routes == 1..3
Drivers == 1..4
Default == [r \in Routes |-> r]

VARIABLES sick, cover
vars == <<sick, cover>>

Roster == Default @@ cover
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
