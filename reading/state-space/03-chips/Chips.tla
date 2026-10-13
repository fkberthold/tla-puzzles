---- MODULE Chips ----
EXTENDS Naturals, FiniteSets

CONSTANTS Player, Stake
ASSUME Stake % Cardinality(Player) # 0

VARIABLE pile
vars == <<pile>>

RECURSIVE Held(_, _)
Held(f, S) ==
  IF S = {} THEN 0
  ELSE LET p == CHOOSE q \in S : TRUE
       IN f[p] + Held(f, S \ {p})

TypeOK == pile \in [Player -> 0..Stake]

Init ==
  \E p \in Player :
    pile = [q \in Player |-> IF q = p THEN Stake ELSE 0]

Pass(p, q) ==
  /\ pile[p] > pile[q]
  /\ pile' = [pile EXCEPT ![p] = pile[p] - 1,
                          ![q] = pile[q] + 1]

Next == \E p, q \in Player : Pass(p, q)

Spec == Init /\ [][Next]_vars

Conserved == Held(pile, Player) = Stake

SomeoneCanPass == \E p, q \in Player : pile[p] > pile[q]
====
