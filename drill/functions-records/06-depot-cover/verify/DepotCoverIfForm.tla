-------------------------- MODULE DepotCoverIfForm ------------------------
(* Variant: no merge operator anywhere. The roster is a conditional over   *)
(* the domain, and the sick-day update rebuilds the function over the      *)
(* union of the two domains with the same conditional. Longer, and the    *)
(* same states, because this is what the merge abbreviates.                *)
EXTENDS Naturals

Routes == 1..3
Drivers == 1..4
Default == [r \in Routes |-> r]

VARIABLES sick, cover
vars == <<sick, cover>>

Roster == [r \in Routes |-> IF r \in DOMAIN cover THEN cover[r] ELSE Default[r]]
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
                          cover' = [r \in Drives(d) \cup DOMAIN cover |->
                                      IF r \in Drives(d) THEN s ELSE cover[r]]

Recover(d) == /\ d \in sick
              /\ sick' = sick \ {d}
              /\ cover' = [r \in {q \in DOMAIN cover : Default[q] /= d} |-> cover[r]]

Next == \E d \in Drivers : FallSick(d) \/ Recover(d)

Spec == Init /\ [][Next]_vars

NoSickDriverRostered == \A r \in Routes : Roster[r] \notin sick
==========================================================================
