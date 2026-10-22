---- MODULE MetronomeBox ----
EXTENDS Integers
VARIABLE tick
vars == <<tick>>

Init == tick = 0
Advance == tick < 3 /\ tick' = tick + 1
Done == tick = 3 /\ UNCHANGED vars
Next == Advance \/ Done
Spec == Init /\ [][Next]_vars

\* A box over a bare action, with no subscript. The module does not get as far
\* as a model: TLC refuses this definition whether or not a cfg names it.
BoxBare == [](tick' = tick + 1)
============================
