------------------------------ MODULE Submitted -----------------------------
(***************************************************************************)
(* THE SUBMISSION the matrix grades: the one thing a learner handed the      *)
(* liveness requirement and told to write a checkable invariant would        *)
(* plausibly produce.                                                       *)
(*                                                                         *)
(* It is the surrogate alone, with neither the type arm nor the defect's own *)
(* signature.  The question the matrix answers is whether that is strong     *)
(* enough to notice each seeded ceiling bug, and the answer is worth         *)
(* measuring rather than assuming: TxnBeginChecks.tla already shows this     *)
(* predicate holding on a spec where the defect is still present.           *)
(***************************************************************************)
EXTENDS TxnCoord

Inv == NoStuckTxn

=============================================================================
