------------------------- MODULE TroughsNoRecursive -----------------------
(* The sum as an operator that calls itself. An operator may not refer to  *)
(* itself unless it is declared recursive first, so this does not parse.   *)
(* A function may, with no declaration, which is why the reference uses   *)
(* one.                                                                     *)
EXTENDS Naturals
CONSTANTS N, Cap, Supply

Troughs == 1..N

VARIABLES bowser, trough, drunk
vars == <<bowser, trough, drunk>>

Total(n) == IF n = 0 THEN 0 ELSE Total(n - 1) + trough[n]

TypeOK == /\ bowser \in 0..Supply
          /\ trough \in [Troughs -> 0..Cap]
          /\ drunk \in 0..Supply

Init == /\ bowser = Supply
        /\ trough = [t \in Troughs |-> 0]
        /\ drunk = 0

Pour(t) == /\ bowser > 0
           /\ trough[t] < Cap
           /\ bowser' = bowser - 1
           /\ trough' = [trough EXCEPT ![t] = @ + 1]
           /\ UNCHANGED drunk

Drink(t) == /\ trough[t] > 0
            /\ trough' = [trough EXCEPT ![t] = @ - 1]
            /\ drunk' = drunk + 1
            /\ UNCHANGED bowser

Next == \E t \in Troughs : Pour(t) \/ Drink(t)

Spec == Init /\ [][Next]_vars

Conserved == bowser + Total(N) + drunk = Supply
==========================================================================
