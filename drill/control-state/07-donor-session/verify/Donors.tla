---------------------------- MODULE Donors -----------------------------
(* A donation session. Six labels, one nurse, a few chairs. Every step   *)
(* is a move along the procedure, so one helper carries all of them.     *)
EXTENDS Naturals, FiniteSets
CONSTANTS Donors, Chairs,
          Arrived, Screening, Cleared, Donating, Resting, Gone   \* labels

ASSUME Chairs \in Nat

ProcSet == Donors

VARIABLE pc
vars == <<pc>>

\* Everyone standing at a given point in the procedure.
At(label) == {d \in ProcSet : pc[d] = label}

\* Move one donor from one point in the procedure to the next.
Trans(d, from, to) == /\ pc[d] = from
                      /\ pc' = [pc EXCEPT ![d] = to]

Init == pc = [d \in ProcSet |-> Arrived]

\* The nurse calls the next donor over. One at the desk at a time.
CallIn(d) == /\ At(Screening) = {}
             /\ Trans(d, Arrived, Screening)

Pass(d) == Trans(d, Screening, Cleared)
Defer(d) == Trans(d, Screening, Gone)

\* Take a chair, if one is free.
Sit(d) == /\ Cardinality(At(Donating)) < Chairs
          /\ Trans(d, Cleared, Donating)

Unhook(d) == Trans(d, Donating, Resting)
Leave(d) == Trans(d, Resting, Gone)

Terminating == /\ \A d \in ProcSet : pc[d] = Gone
               /\ UNCHANGED vars

Next == \/ \E d \in ProcSet :
             CallIn(d) \/ Pass(d) \/ Defer(d) \/ Sit(d) \/ Unhook(d) \/ Leave(d)
        \/ Terminating

Spec == Init /\ [][Next]_vars

\* The nurse never has two donors at the desk.
OneAtTheDesk == Cardinality(At(Screening)) <= 1

\* Nobody donates standing up.
NoStandingDonors == Cardinality(At(Donating)) <= Chairs
=========================================================================
