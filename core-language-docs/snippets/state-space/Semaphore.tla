---- MODULE Semaphore ----
EXTENDS Integers
VARIABLE aspect

Init == aspect = 2
Up == aspect > 0 /\ aspect' = aspect - 1
Down == aspect < 2 /\ aspect' = aspect + 1
Next == Up \/ Down
Spec == Init /\ [][Next]_<<aspect>>

\* A state predicate. The INVARIANT slot takes this one.
Valid == aspect \in 0..2

\* An action formula. The PROPERTY slot takes this one, and the INVARIANT slot
\* does not.
NeverSkips == [][aspect' - aspect \in {-1, 1}]_<<aspect>>

\* Two claims with no variable in them. Both are legal in the INVARIANT slot
\* and they report through different channels.
Arithmetic == 2 > 1
Backwards == 1 > 2
=========================
