---- MODULE Jig ----
EXTENDS Integers

(*--algorithm jig {
  variables bore = 0;
  {
    Start:
      bore := 1;
    Ream:
      while (bore < 3) {
        bore := bore + 1;
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "d2a480bb" /\ chksum(tla) = "a4235cfc")
VARIABLES pc, bore

vars == << pc, bore >>

Init == (* Global variables *)
        /\ bore = 0
        /\ pc = "Start"

Start == /\ pc = "Start"
         /\ bore' = 1
         /\ pc' = "Ream"

Ream == /\ pc = "Ream"
        /\ IF bore < 3
              THEN /\ bore' = bore + 1
                   /\ pc' = "Ream"
              ELSE /\ pc' = "Done"
                   /\ bore' = bore

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Start \/ Ream
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====================
