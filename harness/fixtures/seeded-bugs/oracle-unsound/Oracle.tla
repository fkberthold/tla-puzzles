------------------------------- MODULE Oracle -------------------------------
(***************************************************************************)
(* A BROKEN INSTRUMENT.  WRONG ON PURPOSE.                                  *)
(*                                                                          *)
(* The reference crossing violates this oracle at its second state, so      *)
(* every variant would "be caught" and every submission would be graded     *)
(* against a witness that means nothing.                                    *)
(*                                                                          *)
(* The matrix has to notice its own instrument is broken BEFORE it says     *)
(* anything about a submission, which is why the oracle-against-reference   *)
(* run comes first and why its failure is ORACLE_UNSOUND (45) rather than   *)
(* any verdict about the learner.                                           *)
(***************************************************************************)
EXTENDS Crossing

Inv == ns = "red" /\ ew = "red"

=============================================================================
