------------------------- MODULE DepotCoverOldWins ------------------------
(* The roster merge is right. The sick-day merge is the wrong way round:   *)
(* cover on the left, so an existing stand-in entry beats the new one. The *)
(* first driver to fall sick is covered fine. When the stand-in then falls *)
(* sick, the route keeps its old entry, which names the stand-in.          *)
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
                          cover' = cover @@ [r \in Drives(d) |-> s]

Recover(d) == /\ d \in sick
              /\ sick' = sick \ {d}
              /\ cover' = [r \in {q \in DOMAIN cover : Default[q] /= d} |-> cover[r]]

Next == \E d \in Drivers : FallSick(d) \/ Recover(d)

Spec == Init /\ [][Next]_vars

NoSickDriverRostered == \A r \in Routes : Roster[r] \notin sick
==========================================================================
