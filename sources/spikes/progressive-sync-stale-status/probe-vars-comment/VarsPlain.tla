----------------------------- MODULE VarsPlain ------------------------------
(* The control: the same two variables with the comments moved off the      *)
(* declaration lines.  Everything else is byte-for-byte the same shape.     *)
EXTENDS Naturals

VARIABLES alpha, beta

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat

=============================================================================
