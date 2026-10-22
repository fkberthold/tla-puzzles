---- MODULE FlumeTwo ----
EXTENDS Integers

(*--algorithm flumetwo {
  variables x = 0, y = 0;
  {
    Pour:
      x := 1;
    Settle:
      y := 1;
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "f804a3cb" /\ chksum(tla) = "ee9ea8b6")
VARIABLES pc, x, y

vars == << pc, x, y >>

Init == (* Global variables *)
        /\ x = 0
        /\ y = 0
        /\ pc = "Pour"

Pour == /\ pc = "Pour"
        /\ x' = 1
        /\ pc' = "Settle"
        /\ y' = y

Settle == /\ pc = "Settle"
          /\ y' = 1
          /\ pc' = "Done"
          /\ x' = x

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Pour \/ Settle
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

Level == x = y
=========================
