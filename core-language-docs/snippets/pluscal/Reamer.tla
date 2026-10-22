---- MODULE Reamer ----
CONSTANT Bits

(*--algorithm reamer {
  variables fitted = "none";
  {
    Fit:
      with (b \in Bits) {
        fitted := b;
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "e5aee8e2" /\ chksum(tla) = "8cf16463")
VARIABLES pc, fitted

vars == << pc, fitted >>

Init == (* Global variables *)
        /\ fitted = "none"
        /\ pc = "Fit"

Fit == /\ pc = "Fit"
       /\ \E b \in Bits:
            fitted' = b
       /\ pc' = "Done"

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Fit
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

Fitted == fitted = "none"
=======================
