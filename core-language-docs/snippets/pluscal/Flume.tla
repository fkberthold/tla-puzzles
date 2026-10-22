---- MODULE Flume ----
EXTENDS Integers

(*--algorithm flume {
  variables x = 0, y = 0;
  {
    Pour:
      x := 1;
      y := 1;
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "1de8cb43" /\ chksum(tla) = "6728b7a")
VARIABLES pc, x, y

vars == << pc, x, y >>

Init == (* Global variables *)
        /\ x = 0
        /\ y = 0
        /\ pc = "Pour"

Pour == /\ pc = "Pour"
        /\ x' = 1
        /\ y' = 1
        /\ pc' = "Done"

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Pour
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

Level == x = y
======================
