---------------------------- MODULE CarWash ----------------------------
(* The corrected spec. Pay advances the payer to Paid and nothing else.  *)
EXTENDS Naturals, FiniteSets
CONSTANTS Customers,
          Arrived, Paid, Washing, Gone,     \* labels
          Free, Busy                        \* the bay

VARIABLES pc, bay, till
vars == <<pc, bay, till>>

Init == /\ pc = [c \in Customers |-> Arrived]
        /\ bay = Free
        /\ till = 0

Pay(c) == /\ pc[c] = Arrived
          /\ till' = till + 1
          /\ pc' = [pc EXCEPT ![c] = Paid]
          /\ UNCHANGED bay

Enter(c) == /\ pc[c] = Paid
            /\ bay = Free
            /\ bay' = Busy
            /\ pc' = [pc EXCEPT ![c] = Washing]
            /\ UNCHANGED till

Leave(c) == /\ pc[c] = Washing
            /\ bay' = Free
            /\ pc' = [pc EXCEPT ![c] = Gone]
            /\ UNCHANGED till

Terminating == /\ \A c \in Customers : pc[c] = Gone
               /\ UNCHANGED vars

Next == \/ \E c \in Customers : Pay(c) \/ Enter(c) \/ Leave(c)
        \/ Terminating

Spec == Init /\ [][Next]_vars

\* One car in the bay.
OneInTheBay == Cardinality({c \in Customers : pc[c] = Washing}) <= 1

\* Every customer past the kiosk is covered by a payment in the till.
PaidFor == Cardinality({c \in Customers : pc[c] /= Arrived}) <= till
=========================================================================
