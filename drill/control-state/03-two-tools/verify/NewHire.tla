---------------------------- MODULE NewHire ----------------------------
(* The same day, except technician b takes the meter first.              *)
CONSTANTS Techs, Nobody,
          Ladder, Meter,
          Idle, HasLadder, HasMeter, HasBoth, Done

ASSUME Nobody \notin Techs

ProcSet == Techs

\* The new hire reaches for the meter first. Everyone else, the ladder.
CONSTANT Rookie
ASSUME Rookie \in Techs

FirstTool(t) == IF t = Rookie THEN Meter ELSE Ladder
Other(tool) == IF tool = Ladder THEN Meter ELSE Ladder

VARIABLES pc, holder
vars == <<pc, holder>>

Init == /\ pc = [t \in ProcSet |-> Idle]
        /\ holder = [tool \in {Ladder, Meter} |-> Nobody]

TakeFirst(t) == /\ pc[t] = Idle
                /\ holder[FirstTool(t)] = Nobody
                /\ holder' = [holder EXCEPT ![FirstTool(t)] = t]
                /\ pc' = [pc EXCEPT ![t] =
                            IF FirstTool(t) = Ladder THEN HasLadder ELSE HasMeter]

TakeSecond(t) == /\ pc[t] \in {HasLadder, HasMeter}
                 /\ holder[Other(FirstTool(t))] = Nobody
                 /\ holder' = [holder EXCEPT ![Other(FirstTool(t))] = t]
                 /\ pc' = [pc EXCEPT ![t] = HasBoth]

Finish(t) == /\ pc[t] = HasBoth
             /\ holder' = [tool \in {Ladder, Meter} |-> Nobody]
             /\ pc' = [pc EXCEPT ![t] = Done]

Terminating == /\ \A t \in ProcSet : pc[t] = Done
               /\ UNCHANGED vars

Work == \E t \in ProcSet : TakeFirst(t) \/ TakeSecond(t) \/ Finish(t)

Next == Work \/ Terminating

BareSpec == Init /\ [][Work]_vars
Spec == Init /\ [][Next]_vars

\* With fairness, for the liveness comparison in the answer.
FairSpec == Spec /\ WF_vars(Work)

BothInHand == \A t \in ProcSet :
                 pc[t] = HasBoth => holder[Ladder] = t /\ holder[Meter] = t

DayEnds == <>(\A t \in ProcSet : pc[t] = Done)
=========================================================================
