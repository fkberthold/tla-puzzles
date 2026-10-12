---------------------------- MODULE Patrol -----------------------------
(* One guard, a ring of checkpoints, one night. The guard's position is  *)
(* control state: it says where in the round the guard is.               *)
EXTENDS Naturals
CONSTANT N                       \* checkpoints 1..N, walked in order
ASSUME N \in Nat /\ N >= 1

Checkpoints == 1..N

VARIABLES pos, logged
vars == <<pos, logged>>

Init == /\ pos = 1
        /\ logged = {}

\* Log the checkpoint the guard is standing at.
Log == /\ pos \notin logged
       /\ logged' = logged \cup {pos}
       /\ UNCHANGED pos

\* Walk on to the next checkpoint. Only after logging this one.
Walk == /\ pos \in logged
        /\ pos' = (pos % N) + 1
        /\ UNCHANGED logged

Next == Log \/ Walk

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

\* Every checkpoint gets logged.
WholeRound == <>(logged = Checkpoints)
=========================================================================
