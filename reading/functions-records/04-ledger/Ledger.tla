---- MODULE Ledger ----
EXTENDS Naturals, TLC

CONSTANTS Key, Max
ASSUME Max \in Nat

Count == 0..Max

VARIABLES tally, sparse
vars == <<tally, sparse>>

\* The sparse map read as if it were total. A key it has never seen reads
\* as 0, which is what lets the two maps be compared as one equality.
Total == [k \in Key |-> IF k \in DOMAIN sparse THEN sparse[k] ELSE 0]

TypeOK ==
  /\ tally \in [Key -> Count]
  /\ DOMAIN sparse \subseteq Key
  /\ \A k \in DOMAIN sparse : sparse[k] \in Count

Init ==
  /\ tally = [k \in Key |-> 0]
  /\ sparse = [k \in {} |-> 0]

\* EXCEPT bumps a key the map already carries. A key it doesn't carry has
\* to be merged in, because EXCEPT can't widen a domain.
Hit(k) ==
  /\ tally[k] < Max
  /\ tally' = [tally EXCEPT ![k] = @ + 1]
  /\ sparse' = IF k \in DOMAIN sparse
                 THEN [sparse EXCEPT ![k] = @ + 1]
                 ELSE sparse @@ (k :> 1)

\* The rebuild isn't a matter of taste. Nothing in the language takes a
\* key out of a function, so the function gets written again without it.
Forget(k) ==
  /\ k \in DOMAIN sparse
  /\ tally' = [tally EXCEPT ![k] = 0]
  /\ sparse' = [j \in DOMAIN sparse \ {k} |-> sparse[j]]

Next == \E k \in Key : Hit(k) \/ Forget(k)

Spec == Init /\ [][Next]_vars

Agree == tally = Total

Logged == DOMAIN sparse = {k \in Key : tally[k] # 0}
====
