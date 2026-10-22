---- MODULE ChimeRecur ----
EXTENDS Integers
VARIABLE strike
vars == <<strike>>

Init == strike = 0
Sound == strike' = (strike + 1) % 2
Next == Sound
Spec == Init /\ [][Next]_vars /\ WF_vars(Sound)

\* A box action under []<>, which is the other wrong bracket. The outer shape
\* is admitted and the inner one is not, the mirror of ChimeHold.
Recurs == []<>[Sound]_vars
===========================
