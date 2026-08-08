----------------------------- MODULE LedgerGood -----------------------------
(***************************************************************************)
(* A SUBMISSION THAT PASSES THE PARAMETERISED MATRIX.                       *)
(*                                                                          *)
(* Logically equivalent to LedgerOracle!Inv, written differently on         *)
(* purpose -- a range test instead of a set membership -- so that the row   *)
(* is not testing string equality against the oracle's own text.            *)
(*                                                                          *)
(* It mentions both constants, so it also witnesses that the constants      *)
(* channel reaches the SUBMISSION runs and not merely the oracle's.         *)
(***************************************************************************)
EXTENDS Ledger

Inv == \A a \in Accounts : balance[a] >= 0 /\ balance[a] <= MaxBalance

=============================================================================
