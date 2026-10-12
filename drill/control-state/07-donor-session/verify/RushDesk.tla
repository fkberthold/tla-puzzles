---------------------------- MODULE RushDesk -------------------------
(* The neighbour with the nurse guard dropped: CallIn no longer looks at *)
(* anyone else's control state.                                          *)
EXTENDS Naturals, FiniteSets
CONSTANTS Donors, Chairs,
          Arrived, Screening, Cleared, Donating, Resting, Gone

ASSUME Chairs \in Nat

ProcSet == Donors

VARIABLE pc
vars == <<pc>>

At(label) == {d \in ProcSet : pc[d] = label}

Trans(d, from, to) == /\ pc[d] = from
                      /\ pc' = [pc EXCEPT ![d] = to]

Init == pc = [d \in ProcSet |-> Arrived]

CallIn(d) == Trans(d, Arrived, Screening)               \* the slip

Pass(d) == Trans(d, Screening, Cleared)
Defer(d) == Trans(d, Screening, Gone)

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

OneAtTheDesk == Cardinality(At(Screening)) <= 1
NoStandingDonors == Cardinality(At(Donating)) <= Chairs
=========================================================================
