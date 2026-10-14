-------------------------- MODULE BallastRebuild --------------------------
(* Variant: the whole function rebuilt from a constructor, every tank      *)
(* decided by a conditional. Longer, the same meaning, the same states.    *)
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
              /\ level' = [t \in Tanks |->
                             IF t = a THEN level[t] - 1
                             ELSE IF t = b THEN level[t] + 1
                             ELSE level[t]]

Next == \E a, b \in Tanks : Pump(a, b)

Spec == Init /\ [][Next]_vars

Conserved == Aboard = 6
==========================================================================
