---- MODULE PortsFlatMgmt ----
\* Wrong neighbor on the broken model. The management guard is gone from
\* Add and Open is unflattened, with only rule 1 in the config. Whether a
\* number is ever found in a set of intervals decides what TLC reports.
EXTENDS Naturals, FiniteSets

CONSTANTS Lo, Hi, Mgmt, MaxRules

Allowed == Lo..Hi
Typed == (Lo - 1)..(Hi + 1)

VARIABLES rules, maint

vars == <<rules, maint>>

Covered(r) == r[1]..r[2]

Open == {Covered(r) : r \in rules}

TypeOK ==
  /\ rules \subseteq Typed \X Typed
  /\ maint \in BOOLEAN

Init == rules = {} /\ maint = FALSE

Add ==
  /\ ~maint
  /\ Cardinality(rules) < MaxRules
  /\ \E a, b \in Typed :
       /\ a <= b
       /\ a..b \subseteq Allowed
       /\ rules' = rules \cup {<<a, b>>}
  /\ UNCHANGED maint

Remove ==
  /\ \E r \in rules : rules' = rules \ {r}
  /\ UNCHANGED maint

Toggle == maint' = ~maint /\ UNCHANGED rules

Next == Add \/ Remove \/ Toggle

Spec == Init /\ [][Next]_vars

ManagementClosed == Mgmt \notin Open

WithinAllowed == Open \subseteq Allowed
====
