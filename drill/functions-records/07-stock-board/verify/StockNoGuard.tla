---------------------------- MODULE StockNoGuard --------------------------
(* The row layout handled right. Promise never looks at the on-hand       *)
(* column, so a line is promised past what is on the bench.                *)
EXTENDS Naturals
CONSTANTS Lines, Cap

VARIABLE line
vars == <<line>>

TypeOK == line \in [Lines -> [onhand: 0..Cap, promised: 0..Cap]]

Init == line = [l \in Lines |-> [onhand |-> 0, promised |-> 0]]

Restock(l) == /\ line[l].onhand < Cap
              /\ line' = [line EXCEPT ![l].onhand = @ + 1]

Promise(l) == /\ line[l].promised < Cap
              /\ line' = [line EXCEPT ![l].promised = @ + 1]

Deliver(l) == /\ line[l].promised > 0
              /\ line' = [line EXCEPT ![l].onhand = @ - 1, ![l].promised = @ - 1]

Next == \E l \in Lines : Restock(l) \/ Promise(l) \/ Deliver(l)

Spec == Init /\ [][Next]_vars

NeverOverPromised == \A l \in Lines : line[l].promised <= line[l].onhand
==========================================================================
