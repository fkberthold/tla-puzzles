--------------------------- MODULE Ex5LockerBank ---------------------------
\* Reference answer for exercise 5, "The locker bank".
\* Everything below the answer block is scaffolding. Leave it alone.

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

Slot == Rows \X Cols

Free == Slot \ Taken

FreeInRow(r) == {s \in Free : s[1] = r}

TakenRows == {s[1] : s \in Taken}

Clash(wanted) == wanted \intersect Taken

OnlyFreeIn(r) == CHOOSE s \in FreeInRow(r) : TRUE

ColSets == SUBSET Cols

\* ---------------- scaffolding below this line ----------------

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The invariant pins the answers. A wrong body makes TLC report
\* `BankIsRight` as violated.
\*
\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant before the run starts, and a wrong
\* answer comes back as a config error instead of a violation.
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
