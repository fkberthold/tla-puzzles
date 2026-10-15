---- MODULE Key ----
EXTENDS Naturals, FiniteSets

CONSTANT Staff

VARIABLES hook, inside
vars == <<hook, inside>>

TypeOK ==
  /\ hook \in BOOLEAN
  /\ inside \in SUBSET Staff

Init ==
  /\ hook = TRUE
  /\ inside = {}

Take(p) ==
  /\ hook
  /\ hook' = FALSE
  /\ inside' = inside \cup {p}

Hang(p) ==
  /\ ~hook
  /\ p \in inside
  /\ hook' = TRUE
  /\ inside' = inside \ {p}

Next == \E p \in Staff : Take(p) \/ Hang(p)

Spec == Init /\ [][Next]_vars

MutEx == Cardinality(inside) <= 1

Hooked == hook <=> (inside = {})

Inv == TypeOK /\ MutEx /\ Hooked

ISpec == Inv /\ [][Next]_vars
====
