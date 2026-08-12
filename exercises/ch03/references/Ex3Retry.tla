---- MODULE Ex3Retry ----
EXTENDS Integers, TLC

(*--algorithm retry
  variables
    attempts = 0,
    linked = FALSE;

begin
  Dial:
    attempts := attempts + 1;
    if attempts < 3 then
      goto Dial;
    else
      linked := TRUE;
    end if;
  Report:
    assert linked;
    assert attempts = 3;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "7ca0a0f8" /\ chksum(tla) = "636d6c98")
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
          /\ Assert(linked, "Failure of assertion at line 18, column 5.")
          /\ Assert(attempts = 3, 
                    "Failure of assertion at line 19, column 5.")
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
