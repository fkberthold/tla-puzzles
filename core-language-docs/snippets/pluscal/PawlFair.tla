---- MODULE PawlFair ----
EXTENDS Integers

(*--fair algorithm pawlfair {
  variables notch = 0;
  {
    Climb:
      while (notch < 3) {
        notch := notch + 1;
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "7c28162a" /\ chksum(tla) = "382f02f4")
VARIABLES pc, notch

vars == << pc, notch >>

Init == (* Global variables *)
        /\ notch = 0
        /\ pc = "Climb"

Climb == /\ pc = "Climb"
         /\ IF notch < 3
               THEN /\ notch' = notch + 1
                    /\ pc' = "Climb"
               ELSE /\ pc' = "Done"
                    /\ notch' = notch

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Climb
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Next)

Termination == <>(pc = "Done")

\* END TRANSLATION 
=========================
