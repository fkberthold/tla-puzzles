-------------------------- MODULE TroughsHardcoded ------------------------
(* The sum written out for three troughs by hand. Right at N = 3. At N = 4 *)
(* water poured into the fourth trough leaves the sum, and the farm's      *)
(* conservation rule goes red on a model that has no bug.                   *)
EXTENDS Naturals
CONSTANTS N, Cap, Supply

Troughs == 1..N

VARIABLES bowser, trough, drunk
vars == <<bowser, trough, drunk>>

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

Conserved == bowser + trough[1] + trough[2] + trough[3] + drunk = Supply
==========================================================================
