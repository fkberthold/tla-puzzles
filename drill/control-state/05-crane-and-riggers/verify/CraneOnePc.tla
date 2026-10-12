---------------------------- MODULE CraneOnePc -------------------------
(* The same site with the translator's shape: one pc over the union of  *)
(* every process identity, riggers and crane alike.                      *)
CONSTANTS Riggers, TheCrane,
          Idle, Hooked, Clear,
          Parked, Lifting

ASSUME TheCrane \notin Riggers

ProcSet == Riggers \cup {TheCrane}

VARIABLE pc
vars == <<pc>>

Init == pc = [p \in ProcSet |-> IF p = TheCrane THEN Parked ELSE Idle]

Hook(r) == /\ pc[r] = Idle
           /\ pc[TheCrane] = Parked
           /\ pc' = [pc EXCEPT ![r] = Hooked]

StepBack(r) == /\ pc[r] = Hooked
               /\ pc' = [pc EXCEPT ![r] = Clear]

Return(r) == /\ pc[r] = Clear
             /\ pc[TheCrane] = Parked
             /\ pc' = [pc EXCEPT ![r] = Idle]

Lift == /\ pc[TheCrane] = Parked
        /\ \E r \in Riggers : pc[r] = Clear
        /\ \A r \in Riggers : pc[r] /= Hooked
        /\ pc' = [pc EXCEPT ![TheCrane] = Lifting]

Park == /\ pc[TheCrane] = Lifting
        /\ pc' = [pc EXCEPT ![TheCrane] = Parked]

Next == \/ \E r \in Riggers : Hook(r) \/ StepBack(r) \/ Return(r)
        \/ Lift \/ Park

Spec == Init /\ [][Next]_vars

NobodyUnderTheHook ==
    pc[TheCrane] = Lifting => \A r \in Riggers : pc[r] /= Hooked
=========================================================================
