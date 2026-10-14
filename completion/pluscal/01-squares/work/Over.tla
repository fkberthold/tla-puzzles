---- MODULE Over ----
EXTENDS Naturals
\* A broken algorithm. It moves r and carries s exactly as the real one
\* does, and it takes one turn of the loop too many before it stops.

(* --fair algorithm over {
     variables n \in 0..15, r = 0, s = 1;
     { grow: while (s <= n + 1) { s := s + 2 * r + 3; r := r + 1 } }
   } *)
\* BEGIN TRANSLATION (chksum(pcal) = "7c28162a" /\ chksum(tla) = "5b0fb22b")
VARIABLES pc, n, r, s

vars == << pc, n, r, s >>

Init == (* Global variables *)
        /\ n \in 0..15
        /\ r = 0
        /\ s = 1
        /\ pc = "grow"

grow == /\ pc = "grow"
        /\ IF s <= n + 1
              THEN /\ s' = s + 2 * r + 3
                   /\ r' = r + 1
                   /\ pc' = "grow"
              ELSE /\ pc' = "Done"
                   /\ UNCHANGED << r, s >>
        /\ n' = n

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == grow
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Next)

Termination == <>(pc = "Done")

\* END TRANSLATION

\* How this machine reads the claims you wrote. No WITH clause, so every
\* parameter of Claims binds to the name of the same spelling up above.
C == INSTANCE Claims

TypeOK == C!TypeOK
Tied   == C!Tied
Landed == C!Landed
====
