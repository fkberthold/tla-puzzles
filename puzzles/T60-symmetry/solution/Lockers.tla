---- MODULE Lockers ----
EXTENDS FiniteSets, TLC

CONSTANT Students

VARIABLE assigned

Init == assigned = {}

Assign == \E s \in Students \ assigned : assigned' = assigned \cup {s}
          /\ assigned # Students

Next == Assign

vars == << assigned >>

Spec == Init /\ [][Next]_vars

TypeOK == assigned \subseteq Students

\* Symmetry: any permutation of Students yields an equivalent behavior.
\* TLC will use this to skip exploring redundant states.
StudentSym == Permutations(Students)

================================
