---------------------------- MODULE Lockbox ----------------------------
(***************************************************************************)
(* SUBMISSION: too strong, and it says nothing about why.                   *)
(*                                                                          *)
(* The cap is 1, exactly as in `too-strong` -- but this submission ships NO *)
(* obligations module at all, so it states no requirement psi_j and         *)
(* obligation 2 has nothing to refute. Over-constraint BY OMISSION is the   *)
(* dominant real form: a learner does not usually declare a rule that is    *)
(* too tight, they just leave a transition out.                             *)
(*                                                                          *)
(* Only the landmark member of the Relational suite can catch this, which   *)
(* is what this fixture exists to prove. Deleting the landmark loop from    *)
(* grade.sh leaves every other assertion in the selftest green; this one    *)
(* goes red.                                                                *)
(*                                                                          *)
(* It doubles as the fixture for the optional-obligations path: a           *)
(* submission package with a spec module and nothing else must grade, not   *)
(* error.                                                                   *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Put  == level < 1 /\ level' = level + 1
Take == level > 0 /\ level' = level - 1

Next == Put \/ Take

Spec == Init /\ [][Next]_level

(* The `full` flag is part of the graded interface (see LockboxRef.tla).     *)
Observe == [level |-> level, full |-> (level = 3)]

=============================================================================
