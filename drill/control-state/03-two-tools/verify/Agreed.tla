---------------------------- MODULE Agreed -----------------------------
(* Two technicians, two tools, the agreed order: ladder first.           *)
CONSTANTS Techs, Nobody,
          Ladder, Meter,                     \* the tools
          Idle, HasLadder, HasBoth, Done     \* labels

ASSUME Nobody \notin Techs

ProcSet == Techs

VARIABLES pc, holder
vars == <<pc, holder>>

Init == /\ pc = [t \in ProcSet |-> Idle]
        /\ holder = [tool \in {Ladder, Meter} |-> Nobody]

TakeLadder(t) == /\ pc[t] = Idle
                 /\ holder[Ladder] = Nobody
                 /\ holder' = [holder EXCEPT ![Ladder] = t]
                 /\ pc' = [pc EXCEPT ![t] = HasLadder]

TakeMeter(t) == /\ pc[t] = HasLadder
                /\ holder[Meter] = Nobody
                /\ holder' = [holder EXCEPT ![Meter] = t]
                /\ pc' = [pc EXCEPT ![t] = HasBoth]

\* Do the job and put both tools back.
Finish(t) == /\ pc[t] = HasBoth
             /\ holder' = [tool \in {Ladder, Meter} |-> Nobody]
             /\ pc' = [pc EXCEPT ![t] = Done]

\* The intended end of the day. Only when every technician is done.
Terminating == /\ \A t \in ProcSet : pc[t] = Done
               /\ UNCHANGED vars

Work == \E t \in ProcSet : TakeLadder(t) \/ TakeMeter(t) \/ Finish(t)

Next == Work \/ Terminating

\* The spec without the Terminating disjunct, for the measured comparison.
BareSpec == Init /\ [][Work]_vars

Spec == Init /\ [][Next]_vars

\* Nobody does the job without both tools in hand.
BothInHand == \A t \in ProcSet :
                 pc[t] = HasBoth => holder[Ladder] = t /\ holder[Meter] = t
=========================================================================
