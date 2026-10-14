--------------------------- MODULE DepotCoverTotal ------------------------
(* Variant: the stand-in list as a total function with a hole value. Every *)
(* route always has an entry, NoCover when nobody is standing in, so the   *)
(* domain never moves and no merge is needed. Same states.                 *)
EXTENDS Naturals
CONSTANT NoCover

Routes == 1..3
Drivers == 1..4
Default == [r \in Routes |-> r]

VARIABLES sick, cover
vars == <<sick, cover>>

Roster == [r \in Routes |-> IF cover[r] = NoCover THEN Default[r] ELSE cover[r]]
Drives(d) == {r \in Routes : Roster[r] = d}
Fit == Drivers \ sick

TypeOK == /\ sick \subseteq Drivers
          /\ cover \in [Routes -> Drivers \cup {NoCover}]

Init == /\ sick = {}
        /\ cover = [r \in Routes |-> NoCover]

FallSick(d) == /\ d \notin sick
               /\ sick' = sick \cup {d}
               /\ \/ /\ Drives(d) = {}
                     /\ UNCHANGED cover
                  \/ /\ Drives(d) /= {}
                     /\ \E s \in Fit \ {d} :
                          cover' = [r \in Routes |-> IF r \in Drives(d) THEN s ELSE cover[r]]

Recover(d) == /\ d \in sick
              /\ sick' = sick \ {d}
              /\ cover' = [r \in Routes |-> IF Default[r] = d THEN NoCover ELSE cover[r]]

Next == \E d \in Drivers : FallSick(d) \/ Recover(d)

Spec == Init /\ [][Next]_vars

NoSickDriverRostered == \A r \in Routes : Roster[r] \notin sick
==========================================================================
