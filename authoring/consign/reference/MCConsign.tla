--------------------------- MODULE MCConsign ---------------------------
EXTENDS Naturals

CONSTANTS o1, o2, i1, i2, i3, i4

VARIABLE standing

MCOwners == {o1, o2}
MCItems == {i1, i2, i3, i4}
MCOwnerOf == [i \in MCItems |-> IF i \in {i1, i2} THEN o1 ELSE o2]

INSTANCE Consign WITH
    Owners <- MCOwners,
    Items <- MCItems,
    OwnerOf <- MCOwnerOf,
    Floor <- 2

=========================================================================
