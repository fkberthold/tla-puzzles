-------------------------- MODULE MCBrokenCoverage --------------------------
(***************************************************************************)
(* The config harness/vacuity.sh is pointed at.                            *)
(*                                                                         *)
(* It names TypeOK and nothing else, ON PURPOSE. Every other config here    *)
(* names an invariant the model VIOLATES, and TLC stops exploring at the    *)
(* first violation -- TxnBroken.cfg halts at 16 of the 21 distinct states.  *)
(* A dead-action probe reads TLC's coverage block, and a coverage block from *)
(* a truncated run reports an action dead when all it was was unreached.    *)
(*                                                                         *)
(* So the dead-action probe needs a config that explores the whole space,   *)
(* which means an invariant that HOLDS. Expect exit 0.                     *)
(***************************************************************************)
EXTENDS TxnBroken

=============================================================================
