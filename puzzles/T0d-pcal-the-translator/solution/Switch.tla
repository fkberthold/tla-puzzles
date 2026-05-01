---- MODULE Switch ----

(*--algorithm Switch {
  variables on = FALSE;

  fair process (toggler = "Toggler") {
    flip:
      on := ~on;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "89eb4d73" /\ chksum(tla) = "4b49c6a5")
VARIABLES pc, on

vars == << pc, on >>

ProcSet == {"Toggler"}

Init == (* Global variables *)
        /\ on = FALSE
        /\ pc = [self \in ProcSet |-> "flip"]

flip == /\ pc["Toggler"] = "flip"
        /\ on' = ~on
        /\ pc' = [pc EXCEPT !["Toggler"] = "Done"]

toggler == flip

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == toggler
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(toggler)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
