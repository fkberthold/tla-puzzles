--------------------------- MODULE StockColumns ---------------------------
(* The board read by columns: one record of two functions, each line to a *)
(* number. A cell is board.onhand[l], and an update names the column       *)
(* first, then the row. The mirror image of StockRows, cell for cell.      *)
EXTENDS Naturals
CONSTANTS Lines, Cap

VARIABLE board
vars == <<board>>

TypeOK == board \in [onhand: [Lines -> 0..Cap], promised: [Lines -> 0..Cap]]

Init == board = [onhand |-> [l \in Lines |-> 0], promised |-> [l \in Lines |-> 0]]

Restock(l) == /\ board.onhand[l] < Cap
              /\ board' = [board EXCEPT !.onhand[l] = @ + 1]

Promise(l) == /\ board.promised[l] < board.onhand[l]
              /\ board' = [board EXCEPT !.promised[l] = @ + 1]

Deliver(l) == /\ board.promised[l] > 0
              /\ board' = [board EXCEPT !.onhand[l] = @ - 1, !.promised[l] = @ - 1]

Next == \E l \in Lines : Restock(l) \/ Promise(l) \/ Deliver(l)

Spec == Init /\ [][Next]_vars

NeverOverPromised == \A l \in Lines : board.promised[l] <= board.onhand[l]
==========================================================================
