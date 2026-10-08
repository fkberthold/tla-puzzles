--------------------------- MODULE VarsCommented ----------------------------
(* Two declared variables, with a (* *) comment on each declaration line.   *)
(* harness/spike-measure.sh's `vars` column should read 2.                  *)
EXTENDS Naturals

VARIABLES
    alpha,     (* the first variable  *)
    beta       (* the second variable *)

vars == << alpha, beta >>

Init == alpha = 0 /\ beta = 0
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
TypeOK == alpha \in Nat /\ beta \in Nat

=============================================================================
