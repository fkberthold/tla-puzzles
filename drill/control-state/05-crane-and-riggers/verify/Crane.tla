---------------------------- MODULE Crane ------------------------------
(* Two kinds of process, two control variables: one per rigger, one for  *)
(* the crane.                                                            *)
CONSTANTS Riggers,
          Idle, Hooked, Clear,       \* rigger labels
          Parked, Lifting            \* crane labels

VARIABLES rig, crane
vars == <<rig, crane>>

Init == /\ rig = [r \in Riggers |-> Idle]
        /\ crane = Parked

\* Attach a load. Only while the hook is down and still.
Hook(r) == /\ rig[r] = Idle
           /\ crane = Parked
           /\ rig' = [rig EXCEPT ![r] = Hooked]
           /\ UNCHANGED crane

\* Step back from the load.
StepBack(r) == /\ rig[r] = Hooked
               /\ rig' = [rig EXCEPT ![r] = Clear]
               /\ UNCHANGED crane

\* Go back for the next load, once the hook is down again.
Return(r) == /\ rig[r] = Clear
             /\ crane = Parked
             /\ rig' = [rig EXCEPT ![r] = Idle]
             /\ UNCHANGED crane

\* Lift. Somebody has rigged a load, and nobody is still at it.
Lift == /\ crane = Parked
        /\ \E r \in Riggers : rig[r] = Clear
        /\ \A r \in Riggers : rig[r] /= Hooked
        /\ crane' = Lifting
        /\ UNCHANGED rig

Park == /\ crane = Lifting
        /\ crane' = Parked
        /\ UNCHANGED rig

Next == \/ \E r \in Riggers : Hook(r) \/ StepBack(r) \/ Return(r)
        \/ Lift \/ Park

Spec == Init /\ [][Next]_vars

\* The hook never moves while a rigger is at the load.
NobodyUnderTheHook == crane = Lifting => \A r \in Riggers : rig[r] /= Hooked
=========================================================================
