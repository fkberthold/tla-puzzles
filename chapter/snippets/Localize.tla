---------------------------- MODULE Localize ----------------------------
(***************************************************************************)
(* When a fat conjunction fails, TLC tells you the conjunction failed.     *)
(* `Inv!n` picks out the nth conjunct by position, so you can name each    *)
(* one and let TLC tell you which.                                         *)
(*                                                                         *)
(* This also shows why you have to name them: the .cfg grammar takes bare  *)
(* identifiers, so `INVARIANT Inv!2` is not something you can write.       *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES x, y

Init == x = 0 /\ y = 0

Next == /\ x' = x + 1
        /\ y' = y + 2

Spec == Init /\ [][Next]_<< x, y >>

Inv == /\ x <= 4
       /\ y <= 3
       /\ y = 2 * x

Inv1 == Inv!1
Inv2 == Inv!2
Inv3 == Inv!3
=========================================================================
