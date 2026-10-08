--------------------- MODULE DeadlockKeyword ---------------------
(***************************************************************************)
(* THE SITE-3 FIXTURE for bead tla-hl96, and a copy of the shape           *)
(* fixtures/verdict/Deadlock.tla carries, kept local so the four           *)
(* DeadlockKeyword*.cfg files in this directory pair with a module in      *)
(* their own fixture set.                                                  *)
(*                                                                         *)
(* `Next` is enabled only while x < 2, so the state x = 2 has no successor.*)
(* That is a genuine deadlock, and whether TLC reports it depends on BOTH  *)
(* the .cfg's CHECK_DEADLOCK keyword and the command line's -deadlock      *)
(* flag. Measured on TLC 2026.07.31.184830, all six cells:                 *)
(*                                                                         *)
(*     cfg keyword    -deadlock on the command line    rc                  *)
(*     -----------    ----------------------------    ----                 *)
(*     absent         absent                            11                 *)
(*     absent         present                            0                 *)
(*     TRUE           absent                            11                 *)
(*     TRUE           present                            0   <- the defect *)
(*     FALSE          absent                             0   <- and this   *)
(*     FALSE          present                            0                 *)
(*                                                                         *)
(* TLC's -deadlock flag means "do NOT check for deadlock", so checking     *)
(* happens only when neither side switches it off: an AND, and neither     *)
(* side says a word about the other. Rows 4 and 5 are the two ways a       *)
(* stated intent is discarded in silence.                                  *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x < 2 /\ x' = x + 1
Spec == Init /\ [][Next]_x

=============================================================================
