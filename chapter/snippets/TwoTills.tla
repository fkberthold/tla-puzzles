---------------------------- MODULE TwoTills ----------------------------
(***************************************************************************)
(* The concrete shop: two tills, and a staff member who moves cash from    *)
(* one to the other.  A sweep is not a sale.                               *)
(***************************************************************************)
EXTENDS Naturals

CONSTANT Max

VARIABLES a, b
cvars == << a, b >>

Init == a = 0 /\ b = 0

RingA == /\ a + b < Max
         /\ a' = a + 1
         /\ UNCHANGED b

RingB == /\ a + b < Max
         /\ b' = b + 1
         /\ UNCHANGED a

Sweep == /\ a > 0
         /\ a' = a - 1
         /\ b' = b + 1

Next == RingA \/ RingB \/ Sweep

Spec == Init /\ [][Next]_cvars

(***************************************************************************)
(* The mapping.  A sweep changes both a and b but not a + b, so under this *)
(* mapping a sweep is a stuttering step of Till.                           *)
(***************************************************************************)
T == INSTANCE Till WITH takings <- a + b

Refines == T!Spec

\* And the same check with the mapping nailed to the floor.
TFrozen == INSTANCE Till WITH takings <- 0

RefinesFrozen == TFrozen!Spec
=========================================================================
