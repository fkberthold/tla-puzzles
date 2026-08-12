--------------------------- MODULE Ex5LockerBank ---------------------------
\* Starter for exercise 5, "The locker bank".
\* Fill in the answer block. Leave the given section and the scaffolding alone.
\*
\* Run it before you change anything. It should go red. That is the point.

EXTENDS Integers, FiniteSets

\* ---------------- given, do not change ----------------

\* Three rows of lockers, three columns per row.
Rows == 1..3
Cols == {"a", "b", "c"}

\* Which lockers are already in use.
TakenInRow1 == {<<1, "a">>}
TakenInRow2 == {<<2, "b">>, <<2, "c">>}
Taken == TakenInRow1 \union TakenInRow2

\* ---------------- answer block, this is what you fill in ----------------

\* Every locker in the bank, as a pair of row and column.
Slot == {}

\* Every locker that is not taken.
Free == {}

\* The free lockers in one row.
FreeInRow(r) == {}

\* The rows that have at least one taken locker in them.
TakenRows == {}

\* The lockers in `wanted` that are already taken.
Clash(wanted) == {}

\* One free locker in row `r`. Row 2 has exactly one, so there is no ambiguity.
OnlyFreeIn(r) == <<0, "">>

\* Every set of columns you could pick, including the empty one.
ColSets == {}

\* ---------------- scaffolding below this line ----------------

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The invariant pins the answers. A wrong body makes TLC report
\* `BankIsRight` as violated.
BankIsRight ==
    /\ probe = 0
    /\ Cardinality(Slot) = 9
    /\ <<2, "a">> \in Slot
    /\ Cardinality(Free) = 6
    /\ <<1, "a">> \notin Free
    /\ Free \subseteq Slot
    /\ FreeInRow(2) = {<<2, "a">>}
    /\ FreeInRow(3) = {<<3, "a">>, <<3, "b">>, <<3, "c">>}
    /\ TakenRows = {1, 2}
    /\ Clash({<<3, "a">>, <<2, "b">>}) = {<<2, "b">>}
    /\ Clash({<<3, "a">>}) = {}
    /\ OnlyFreeIn(2) = <<2, "a">>
    /\ Cardinality(ColSets) = 8
    /\ Cols \in ColSets
    \* A worked demonstration of `BOOLEAN` as the set of all booleans.
    \* Nothing to fill in here, just read it.
    /\ {<<r, r \in TakenRows>> : r \in Rows} \subseteq (Rows \X BOOLEAN)

===========================================================================
