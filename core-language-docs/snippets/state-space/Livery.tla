---- MODULE Livery ----
EXTENDS TLC
CONSTANT Cars
VARIABLE loaded

Init == loaded = {}
Load == \E c \in Cars \ loaded : loaded' = loaded \cup {c}
Done == loaded = Cars /\ UNCHANGED loaded
Next == Load \/ Done
Spec == Init /\ [][Next]_<<loaded>>
FairSpec == Spec /\ WF_<<loaded>>(Load)

\* Permutations comes from TLC and needs every element to be a model value.
Perms == Permutations(Cars)

\* A liveness property and a safety-shaped action property, so the pair can be
\* run under SYMMETRY and the two answers compared.
Fills == <>(loaded = Cars)
Grows == [][loaded \subseteq loaded']_<<loaded>>
Shrinks == [][loaded' \subseteq loaded]_<<loaded>>

\* A state predicate under a box, which TLC lifts to the invariant channel.
Held == [](loaded \subseteq Cars)
=======================
