---------------------------- MODULE RebootLate -------------------------
(* The off-by-one neighbour: the count is tested before it is bumped, so  *)
(* escalation waits for a fourth red.                                     *)
EXTENDS Naturals
CONSTANTS Start, Waiting, Booting, Fixed, Escalated

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

SeeRed == /\ pc = Booting
          /\ reds' = reds + 1
          /\ pc' = IF reds = 3 THEN Escalated ELSE Start     \* the slip

Terminating == /\ pc \in {Fixed, Escalated}
               /\ UNCHANGED vars

Work == CutPower \/ PowerUp \/ SeeGreen \/ SeeRed

Next == Work \/ Terminating

BareSpec == Init /\ [][Work]_vars
Spec == Init /\ [][Next]_vars

AtMostThreeReds == reds <= 3
ThreeRedsExactly == (pc = Escalated) <=> (reds = 3)
HandsOff == [][pc = Escalated => pc' = Escalated]_vars
=========================================================================
