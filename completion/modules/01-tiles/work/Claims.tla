---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Naturals, FiniteSets

CONSTANT Wall
ASSUME Wall \in 2..12

VARIABLES size, next, laid

---- MODULE Tile ----
\* One tile, clipped to the corridor it is laid in. Far is LOCAL, so a
\* caller reaches the clipped Cells and never the raw far end.
CONSTANTS At, Size, Wall
LOCAL Far == At + Size - 1
Cells == {c \in 1..Wall : At <= c /\ c <= Far}
Count == Cardinality(Cells)
====

\* Two instances of that one library. Here is the tile about to be laid.
\* Whole is the corridor read as a single tile the full way across. Both
\* leave Wall out of the WITH clause, so it binds to the Wall above.
Here  == INSTANCE Tile WITH At <- next, Size <- size
Whole == INSTANCE Tile WITH At <- 1,    Size <- Wall

TypeOK ==
  /\ size \in 1..4
  /\ next \in Nat
  /\ laid \in SUBSET (1..Wall)

\* CLAIM 1. The tile about to be laid covers no cell that has been laid
\* already.
Clear == FILL_IN_CLAIM_1

\* CLAIM 2. Once the next tile would start past the end of the corridor,
\* every cell of the corridor has been laid.
Filled == FILL_IN_CLAIM_2
====
