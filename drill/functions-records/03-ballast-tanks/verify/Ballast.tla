----------------------------- MODULE Ballast ------------------------------
(* The reference. One pump moves one unit between two tanks in one step,  *)
(* and the step is one function update with two clauses. Each clause's @   *)
(* is that tank's old level.                                                *)
EXTENDS Naturals
CONSTANTS Fore, Port, Stbd, Cap

Tanks == {Fore, Port, Stbd}

VARIABLE level
vars == <<level>>

TypeOK == level \in [Tanks -> 0..Cap]

Aboard == level[Fore] + level[Port] + level[Stbd]

Init == level = [t \in Tanks |-> 2]

Pump(a, b) == /\ a /= b
              /\ level[a] > 0
              /\ level[b] < Cap
              /\ level' = [level EXCEPT ![a] = @ - 1, ![b] = @ + 1]

Next == \E a, b \in Tanks : Pump(a, b)

Spec == Init /\ [][Next]_vars

Conserved == Aboard = 6
==========================================================================
