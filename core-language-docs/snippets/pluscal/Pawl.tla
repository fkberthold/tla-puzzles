---- MODULE Pawl ----
EXTENDS Integers

(*--algorithm pawl {
  variables notch = 0;
  {
    Climb:
      while (notch < 3) {
        notch := notch + 1;
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "a9436a6" /\ chksum(tla) = "d1ab0a3")
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

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
=====================
