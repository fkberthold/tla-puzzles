---- MODULE Metronome ----
EXTENDS Integers
VARIABLE tick
vars == <<tick>>

Init == tick = 0
Advance == tick < 3 /\ tick' = tick + 1
Done == tick = 3 /\ UNCHANGED vars
Next == Advance \/ Done
Spec == Init /\ [][Next]_vars

\* The step rule a reader would state first, with no box around it.
BareAct == tick' = tick + 1

\* The same rule with the box and the subscript.
Boxed == [][tick' = tick + 1]_vars

\* A state predicate, for the contrast with the two above.
Bounded == [](tick <= 3)
=========================
