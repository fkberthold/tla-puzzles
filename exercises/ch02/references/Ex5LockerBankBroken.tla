------------------------ MODULE Ex5LockerBankBroken ------------------------
\* Seeded-wrong variant of `Ex5LockerBank`. Run this to see the check go red.
\* One edit against the reference: the two operands of the set difference in
\* `Free` are the wrong way round.

EXTENDS Integers, FiniteSets

Rows == 1..3
Cols == {"a", "b", "c"}

TakenInRow1 == {<<1, "a">>}
TakenInRow2 == {<<2, "b">>, <<2, "c">>}
Taken == TakenInRow1 \union TakenInRow2

Slot == Rows \X Cols

Free == Taken \ Slot

FreeInRow(r) == {s \in Free : s[1] = r}

TakenRows == {s[1] : s \in Taken}

Clash(wanted) == wanted \intersect Taken

OnlyFreeIn(r) == CHOOSE s \in FreeInRow(r) : TRUE

ColSets == SUBSET Cols

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

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
    /\ {<<r, r \in TakenRows>> : r \in Rows} \subseteq (Rows \X BOOLEAN)

===========================================================================
