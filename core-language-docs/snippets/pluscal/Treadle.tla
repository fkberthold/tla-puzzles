---- MODULE Treadle ----
(***************************************************************************)
(* DRIFT ON PURPOSE.  One line of the generated block below was changed by  *)
(* hand after the translator ran, so the block no longer says what the      *)
(* source above it says.  `Lift` reads `stroke' = 2` where the source sets  *)
(* it to 0.  Nothing in the command-line toolchain reports the gap, which   *)
(* is the whole point of the section that quotes this module.               *)
(*                                                                         *)
(* Do NOT re-run the translator over this file.  That regenerates the block *)
(* and removes the finding.                                                 *)
(***************************************************************************)

(*--algorithm treadle {
  variables stroke = 0;
  {
    Press:
      stroke := 1;
    Lift:
      stroke := 0;
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "af8a3129" /\ chksum(tla) = "8d92c760")
VARIABLES pc, stroke

vars == << pc, stroke >>

Init == (* Global variables *)
        /\ stroke = 0
        /\ pc = "Press"

Press == /\ pc = "Press"
         /\ stroke' = 1
         /\ pc' = "Lift"

Lift == /\ pc = "Lift"
        /\ stroke' = 2
        /\ pc' = "Done"

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Press \/ Lift
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

Stroke == stroke \in {0, 1}
========================
