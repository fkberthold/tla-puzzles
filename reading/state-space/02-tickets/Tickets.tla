---- MODULE Tickets ----
EXTENDS Naturals, FiniteSets

CONSTANTS Player, Nil, Limit

VARIABLES ticket, next, serving
vars == <<ticket, next, serving>>

Waiting == {p \in Player : ticket[p] # Nil}
Inside  == {p \in Player : ticket[p] = serving}

TypeOK ==
  /\ ticket \in [Player -> Nat \cup {Nil}]
  /\ next \in Nat
  /\ serving \in Nat

Init ==
  /\ ticket = [p \in Player |-> Nil]
  /\ next = 0
  /\ serving = 0

Take(p) ==
  /\ ticket[p] = Nil
  /\ ticket' = [ticket EXCEPT ![p] = next]
  /\ next' = next + 1
  /\ UNCHANGED serving

Leave(p) ==
  /\ ticket[p] = serving
  /\ ticket' = [ticket EXCEPT ![p] = Nil]
  /\ serving' = serving + 1
  /\ UNCHANGED next

Next == \E p \in Player : Take(p) \/ Leave(p)

Spec == Init /\ [][Next]_vars

Bounded == next <= Limit

Issued == \A p \in Waiting : ticket[p] < next

NoSkip == \A p \in Waiting : ticket[p] >= serving

Distinct ==
  \A p, q \in Waiting : p # q => ticket[p] # ticket[q]

MutualExclusion == Cardinality(Inside) <= 1

Orderly == [][serving' \in {serving, serving + 1}]_vars
====
