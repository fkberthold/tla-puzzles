---------------------------- MODULE LedgerOracle ----------------------------
(***************************************************************************)
(* THE AUTHOR'S OWN PROPERTY for the parameterised matrix (bead tla-40y).   *)
(*                                                                          *)
(* It is stated OVER THE CONSTANTS.  That is the point of the fixture: an   *)
(* oracle whose text mentions `Accounts` and `MaxBalance` cannot even be    *)
(* evaluated unless the generated .cfg assigns them, so a matrix with no    *)
(* constants channel fails at PHASE 1 -- before it grades anything -- and   *)
(* fails as a harness fault rather than as a verdict about a submission.    *)
(***************************************************************************)
EXTENDS Ledger

Inv == \A a \in Accounts : balance[a] \in 0..MaxBalance

=============================================================================
