------------------------------ MODULE MCSeedLib ------------------------------
EXTENDS SeedLib

MCMembers == {"m1", "m2"}
MCVarieties == {"beans", "lettuce"}
MCOpeningStock == [v \in MCVarieties |-> IF v = "beans" THEN 2 ELSE 1]

=============================================================================
