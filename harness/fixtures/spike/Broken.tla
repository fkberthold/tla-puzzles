------------------------------- MODULE Broken -------------------------------
(***************************************************************************)
(* Fixture for harness/test-spike-measure.sh, the violation path.           *)
(*                                                                          *)
(* The same system as Tiny.tla, with an invariant that is false. Both       *)
(* variables can reach 2, so their sum reaches 4 and the bound of 2 breaks. *)
(* TLC exits 12 here, and the test watches for that rather than for text.   *)
(*                                                                          *)
(* This fixture also carries a fairness conjunct and a temporal property,   *)
(* which the two are here for: the measurement columns that report them     *)
(* need a module where the honest answer is yes.                            *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES x, y

vars == << x, y >>

Init == x = 0 /\ y = 0

BumpX == x < 2 /\ x' = x + 1 /\ y' = y
BumpY == y < 2 /\ y' = y + 1 /\ x' = x

Next == BumpX \/ BumpY

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

SumBounded == x + y <= 2

BothArrive == <>(x = 2 /\ y = 2)

=============================================================================
