---- MODULE Squares ----
EXTENDS Naturals
\* The real algorithm. It walks r up one at a time and carries s alongside
\* it, stopping as soon as s has passed n.

(* --fair algorithm squares {
     variables n \in 0..15, r = 0, s = 1;
     { grow: while (s <= n) { s := s + 2 * r + 3; r := r + 1 } }
   } *)
\* BEGIN TRANSLATION (chksum(pcal) = "7c28162a" /\ chksum(tla) = "41df1be2")
VARIABLES pc, n, r, s

vars == << pc, n, r, s >>

Init == (* Global variables *)
        /\ n \in 0..15
        /\ r = 0
        /\ s = 1
        /\ pc = "grow"

grow == /\ pc = "grow"
        /\ IF s <= n
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
