------------------------- MODULE BallastAtApplied -------------------------
(* @ read as "the function" rather than "this tank's old value". In the    *)
(* second clause @ is level[b], a number, and a number cannot be applied.  *)
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
              /\ level' = [level EXCEPT ![a] = @ - 1, ![b] = @[b] + 1]

Next == \E a, b \in Tanks : Pump(a, b)

Spec == Init /\ [][Next]_vars

Conserved == Aboard = 6
==========================================================================
