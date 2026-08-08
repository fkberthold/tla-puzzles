------------------------------ MODULE MCCustody ------------------------------
EXTENDS Custody, TLC

MCBase == [d \in Days |-> IF d <= 7 THEN A ELSE B]

MCHol == (4 :> B) @@ (11 :> A)

MCHolIdle == (2 :> A) @@ (4 :> B) @@ (11 :> A)

MCSched(d) == IF d \in DOMAIN MCHol THEN MCHol[d] ELSE MCBase[d]

MCSchedIdle(d) == IF d \in DOMAIN MCHolIdle THEN MCHolIdle[d] ELSE MCBase[d]

===============================================================================
