---------------------------- MODULE CraneUnguarded ---------------------
(* Crane.tla with the one guard a hurried author drops: Lift no longer   *)
(* checks that nobody is still Hooked.                                   *)
CONSTANTS Riggers,
          Idle, Hooked, Clear,
          Parked, Lifting

VARIABLES rig, crane
vars == <<rig, crane>>

Init == /\ rig = [r \in Riggers |-> Idle]
        /\ crane = Parked

Hook(r) == /\ rig[r] = Idle
           /\ crane = Parked
           /\ rig' = [rig EXCEPT ![r] = Hooked]
           /\ UNCHANGED crane

StepBack(r) == /\ rig[r] = Hooked
               /\ rig' = [rig EXCEPT ![r] = Clear]
               /\ UNCHANGED crane

Return(r) == /\ rig[r] = Clear
             /\ crane = Parked
             /\ rig' = [rig EXCEPT ![r] = Idle]
             /\ UNCHANGED crane

Lift == /\ crane = Parked
        /\ \E r \in Riggers : rig[r] = Clear
        /\ crane' = Lifting
        /\ UNCHANGED rig

Park == /\ crane = Lifting
        /\ crane' = Parked
        /\ UNCHANGED rig

Next == \/ \E r \in Riggers : Hook(r) \/ StepBack(r) \/ Return(r)
        \/ Lift \/ Park

Spec == Init /\ [][Next]_vars

NobodyUnderTheHook == crane = Lifting => \A r \in Riggers : rig[r] /= Hooked
=========================================================================
