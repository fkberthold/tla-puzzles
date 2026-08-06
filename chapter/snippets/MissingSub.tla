--------------------------- MODULE MissingSub ---------------------------
(***************************************************************************)
(* What happens if you forget to substitute for one of the instantiated    *)
(* module's variables.  Till has a variable `takings` and this module does *)
(* not, so `INSTANCE Till` on its own has nothing to bind it to.           *)
(***************************************************************************)
EXTENDS Naturals

CONSTANT Max

VARIABLES a, b

Init == a = 0 /\ b = 0

Next == /\ a' = a
        /\ b' = b

Spec == Init /\ [][Next]_<< a, b >>

T == INSTANCE Till

Refines == T!Spec
=========================================================================
