--------------------------- MODULE MCWarehouse ---------------------------
EXTENDS Warehouse

CONSTANTS a, b

\* Named in a .cfg as CONSTANT Items <- MCItems and Stock <- MCStock.
MCItems == {a, b}
MCStock == [i \in MCItems |-> IF i = a THEN 1 ELSE 2]

==========================================================================
