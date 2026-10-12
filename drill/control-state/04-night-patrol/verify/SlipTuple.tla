---------------------------- MODULE SlipTuple -------------------------
(* The same spec with one slip: the subscript tuple leaves out pos.      *)
EXTENDS Naturals
CONSTANT N
ASSUME N \in Nat /\ N >= 1

Checkpoints == 1..N

VARIABLES pos, logged
vars == <<logged>>                 \* the slip

Init == /\ pos = 1
        /\ logged = {}

Log == /\ pos \notin logged
       /\ logged' = logged \cup {pos}
       /\ UNCHANGED pos

Walk == /\ pos \in logged
        /\ pos' = (pos % N) + 1
        /\ UNCHANGED logged

Next == Log \/ Walk

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

WholeRound == <>(logged = Checkpoints)
=========================================================================
