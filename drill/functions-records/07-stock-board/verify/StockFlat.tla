----------------------------- MODULE StockFlat ----------------------------
(* No container at all: the two columns as two variables, each a function *)
(* from lines. A cell is onhand[l]. Every one-column update now has to say *)
(* the other column is held.                                                *)
EXTENDS Naturals
CONSTANTS Lines, Cap

VARIABLES onhand, promised
vars == <<onhand, promised>>

TypeOK == /\ onhand \in [Lines -> 0..Cap]
          /\ promised \in [Lines -> 0..Cap]

Init == /\ onhand = [l \in Lines |-> 0]
        /\ promised = [l \in Lines |-> 0]

Restock(l) == /\ onhand[l] < Cap
              /\ onhand' = [onhand EXCEPT ![l] = @ + 1]
              /\ UNCHANGED promised

Promise(l) == /\ promised[l] < onhand[l]
              /\ promised' = [promised EXCEPT ![l] = @ + 1]
              /\ UNCHANGED onhand

Deliver(l) == /\ promised[l] > 0
              /\ onhand' = [onhand EXCEPT ![l] = @ - 1]
              /\ promised' = [promised EXCEPT ![l] = @ - 1]

Next == \E l \in Lines : Restock(l) \/ Promise(l) \/ Deliver(l)

Spec == Init /\ [][Next]_vars

NeverOverPromised == \A l \in Lines : promised[l] <= onhand[l]
==========================================================================
