------------------------- MODULE BallastTwoExcepts ------------------------
(* Two single-clause updates conjoined. Each one says what the WHOLE new   *)
(* function is, and the two disagree on both tanks, so no next state       *)
(* satisfies Pump. The barge never pumps. With deadlock checking on, TLC   *)
(* says so.                                                                 *)
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
              /\ level' = [level EXCEPT ![a] = @ - 1]
              /\ level' = [level EXCEPT ![b] = @ + 1]

Next == \E a, b \in Tanks : Pump(a, b)

Spec == Init /\ [][Next]_vars

Conserved == Aboard = 6
==========================================================================
