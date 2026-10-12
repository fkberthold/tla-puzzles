---------------------------- MODULE Reboot -----------------------------
(* One technician, one procedure with a loop and a branch. The label is  *)
(* where in the procedure the technician is. Reds is what they have seen.*)
EXTENDS Naturals
CONSTANTS Start, Waiting, Booting, Fixed, Escalated     \* labels

VARIABLES pc, reds
vars == <<pc, reds>>

Init == /\ pc = Start
        /\ reds = 0

CutPower == /\ pc = Start
            /\ pc' = Waiting
            /\ UNCHANGED reds

PowerUp == /\ pc = Waiting
           /\ pc' = Booting
           /\ UNCHANGED reds

SeeGreen == /\ pc = Booting
            /\ pc' = Fixed
            /\ UNCHANGED reds

\* The branch: a third red escalates, an earlier one loops back.
SeeRed == /\ pc = Booting
          /\ reds' = reds + 1
          /\ pc' = IF reds' = 3 THEN Escalated ELSE Start

\* Amber is "still booting, keep watching". It changes nothing, so it is
\* a stuttering step and needs no action of its own.

Terminating == /\ pc \in {Fixed, Escalated}
               /\ UNCHANGED vars

Work == CutPower \/ PowerUp \/ SeeGreen \/ SeeRed

Next == Work \/ Terminating

BareSpec == Init /\ [][Work]_vars
Spec == Init /\ [][Next]_vars

\* Never a fourth power cycle.
AtMostThreeReds == reds <= 3

\* Escalation means three reds, and three reds mean escalation.
ThreeRedsExactly == (pc = Escalated) <=> (reds = 3)

\* Once escalated, the technician stays out of it.
HandsOff == [][pc = Escalated => pc' = Escalated]_vars
=========================================================================
