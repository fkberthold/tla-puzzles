----------------------------- MODULE ParseGood -----------------------------
(* The same implied action with the antecedent parenthesised. One pair of
   brackets is the whole difference from ParseBad.tla. *)
VARIABLE s
CONSTANTS A, B

Good == [][(s \in {A, B}) => s' = s]_s

Init == s = A
Next == s' = B
Spec == Init /\ [][Next]_s
=============================================================================
