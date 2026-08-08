----------------------------- MODULE LedgerWeak -----------------------------
(***************************************************************************)
(* A SUBMISSION TOO WEAK FOR THE PARAMETERISED MATRIX.                      *)
(*                                                                          *)
(* A type invariant with no upper bound.  It holds of the reference and it  *)
(* holds of `over-by-one` too, so the matrix must report PROPERTY_TOO_WEAK. *)
(*                                                                          *)
(* This is the row that keeps the constants channel honest in the other     *)
(* direction.  A channel that assigned constants and then somehow made      *)
(* every run pass would show up as BUGS_CAUGHT here; grading has to still   *)
(* discriminate once the constants are in place.                            *)
(*                                                                          *)
(* Note it is NOT `Inv == TRUE`.  It mentions `Accounts`, so an unassigned  *)
(* constant would break this module too -- which is what makes its rc=0     *)
(* against the variant evidence about the grading rather than evidence that *)
(* the property was trivially true.                                         *)
(***************************************************************************)
EXTENDS Ledger

Inv == \A a \in Accounts : balance[a] \in Nat

=============================================================================
