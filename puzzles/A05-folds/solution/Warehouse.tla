---- MODULE Warehouse ----
EXTENDS Integers, Apalache

\* @typeAlias: box = { weight: Int, fragile: Bool };
WarehouseTypes == TRUE

\* @type: Set($box);
VARIABLE boxes

vars == << boxes >>

Init ==
  boxes := {
    [ weight |-> 5,  fragile |-> FALSE ],
    [ weight |-> 8,  fragile |-> TRUE  ],
    [ weight |-> 3,  fragile |-> TRUE  ],
    [ weight |-> 12, fragile |-> FALSE ]
  }

Next == UNCHANGED boxes

Spec == Init /\ [][Next]_vars

TotalWeight ==
  LET Plus(acc, b) == acc + b.weight
  IN  ApaFoldSet(Plus, 0, boxes)

HeaviestWeight ==
  LET Max(acc, b) == IF b.weight > acc THEN b.weight ELSE acc
  IN  ApaFoldSet(Max, 0, boxes)

FragileCount ==
  LET Bump(acc, b) == IF b.fragile THEN acc + 1 ELSE acc
  IN  ApaFoldSet(Bump, 0, boxes)

WarehouseOK ==
  /\ TotalWeight    = 28
  /\ HeaviestWeight = 12
  /\ FragileCount   = 2
====
