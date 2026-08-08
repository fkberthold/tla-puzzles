------------------------------- MODULE Ledger -------------------------------
(***************************************************************************)
(* A PLACEHOLDER, NEVER MODEL-CHECKED.  Bead tla-40y.                       *)
(*                                                                          *)
(* This directory exists for the constants.cfg beside it, which carries     *)
(* directives a constants fragment may not carry.  seeded-bugs.sh refuses   *)
(* that fragment as MATRIX_MALFORMED before it stages anything, so no TLC   *)
(* run ever reads this module and it does not need to say anything.         *)
(*                                                                          *)
(* It is deliberately NOT a copy of ../parameterized/reference/Ledger.tla.  *)
(* A copy would rot the first time that file changed, and the row does not  *)
(* need one -- it only needs a `.tla` for --reference to resolve to, under  *)
(* the module name the variants supply.                                     *)
(*                                                                          *)
(* If the refusal is ever removed, this module is what the row runs into,   *)
(* and the assertion fails loudly rather than passing for a new reason.     *)
(***************************************************************************)
CONSTANTS Accounts, MaxBalance

=============================================================================
