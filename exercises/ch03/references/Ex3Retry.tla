---- MODULE Ex3Retry ----
EXTENDS Integers, TLC

(*--algorithm retry {
  variables
    attempts = 0,
    linked = FALSE;

  {
    Dial:
      attempts := attempts + 1;
      if (attempts < 3) {
        goto Dial;
      } else {
        linked := TRUE;
      };
    Report:
      assert linked;
      assert attempts = 3;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "7ca0a0f8" /\ chksum(tla) = "b1d444bf")
VARIABLES pc, attempts, linked

vars == << pc, attempts, linked >>

Init == (* Global variables *)
        /\ attempts = 0
        /\ linked = FALSE
        /\ pc = "Dial"

Dial == /\ pc = "Dial"
        /\ attempts' = attempts + 1
        /\ IF attempts' < 3
              THEN /\ pc' = "Dial"
                   /\ UNCHANGED linked
              ELSE /\ linked' = TRUE
                   /\ pc' = "Report"

Report == /\ pc = "Report"
          /\ Assert(linked, "Failure of assertion at line 18, column 7.")
          /\ Assert(attempts = 3,
                    "Failure of assertion at line 19, column 7.")
          /\ pc' = "Done"
          /\ UNCHANGED << attempts, linked >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Dial \/ Report
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION
====
