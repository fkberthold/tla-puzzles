--------------------------- MODULE StockCrossPath -------------------------
(* The column layout, read with the row path. board is a record whose     *)
(* keys are the two column names, so board[l] asks a record for a key it  *)
(* does not have.                                                           *)
EXTENDS Naturals
CONSTANTS Lines, Cap

VARIABLE board
vars == <<board>>

TypeOK == board \in [onhand: [Lines -> 0..Cap], promised: [Lines -> 0..Cap]]

Init == board = [onhand |-> [l \in Lines |-> 0], promised |-> [l \in Lines |-> 0]]

Restock(l) == /\ board[l].onhand < Cap
              /\ board' = [board EXCEPT ![l].onhand = @ + 1]

Promise(l) == /\ board[l].promised < board[l].onhand
              /\ board' = [board EXCEPT ![l].promised = @ + 1]

Deliver(l) == /\ board[l].promised > 0
              /\ board' = [board EXCEPT ![l].onhand = @ - 1, ![l].promised = @ - 1]

Next == \E l \in Lines : Restock(l) \/ Promise(l) \/ Deliver(l)

Spec == Init /\ [][Next]_vars

NeverOverPromised == \A l \in Lines : board[l].promised <= board[l].onhand
==========================================================================
