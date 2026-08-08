--------------------------- MODULE Stepwise ---------------------------
(***************************************************************************)
(* SUBMISSION: correct, and it must PASS.                                   *)
(*                                                                          *)
(* A step obligation is a new way for a grader to be WRONG as well as a new *)
(* thing for it to catch, and this fixture is the half that watches for     *)
(* that. If the step channel ever starts refusing honest work, this goes    *)
(* red before anything else does.                                           *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Put  == level < 3 /\ level' = level + 1
Take == level > 0 /\ level' = level - 1

Next == Put \/ Take

Spec == Init /\ [][Next]_level

Observe == [level |-> level]

=============================================================================
