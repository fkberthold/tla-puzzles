------------------------------- MODULE Oracle -------------------------------
(***************************************************************************)
(* THE AUTHOR'S OWN PROPERTY -- the matrix's instrument, not a submission.   *)
(*                                                                         *)
(* Against the reference it must exit 0, or the matrix cannot certify       *)
(* anything (ORACLE_UNSOUND).  Against every variant it must exit 12, or    *)
(* the variant is semantically inert and that is OUR bug rather than the    *)
(* submission's (VARIANT_INERT).  Phase 3 runs before phase 4 for exactly   *)
(* that reason.                                                            *)
(*                                                                         *)
(* THREE ARMS UNDER ONE NAME, and this project's own corpus survey says to  *)
(* justify that rather than do it silently.  `.claude/rules/tla-practice.md` *)
(* §1 finds four non-type-invariant declarations in 666 modules that bundle  *)
(* arms over disjoint state, so bundling is the exception.  The reason here  *)
(* is mechanical: harness/seeded-bugs.sh:546 writes exactly one             *)
(* `INVARIANT <name>` line and offers no second one, so an oracle with      *)
(* three arms has one name or it is three oracles.  The cost is the one     *)
(* Lamport names at §14.5.3 p. 259 -- TLC no longer says WHICH arm broke --  *)
(* and it is paid knowingly, because the matrix only reads the exit code.   *)
(*                                                                         *)
(* The arms, and why each is here:                                         *)
(*                                                                         *)
(*   TypeOK                catches a variant that puts the counter out of   *)
(*                         range rather than merely at the wrong value      *)
(*   NoStuckTxn            the liveness requirement's safety surrogate      *)
(*   NoExhaustedEpochHeld  the defect's own signature, which the surrogate  *)
(*                         does not imply -- TxnBeginChecks.tla is the      *)
(*                         counterexample to the implication                *)
(***************************************************************************)
EXTENDS TxnCoord

Inv == /\ TypeOK
       /\ NoStuckTxn
       /\ NoExhaustedEpochHeld

=============================================================================
