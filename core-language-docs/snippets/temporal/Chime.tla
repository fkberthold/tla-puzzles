---- MODULE Chime ----
EXTENDS Integers
VARIABLE strike
vars == <<strike>>

Init == strike = 0
Sound == strike' = (strike + 1) % 2
Next == Sound

\* Weak fairness keeps the bell going, so Sound recurs forever.
Spec == Init /\ [][Next]_vars /\ WF_vars(Sound)

\* The one-shot reading: the bell sounds at some point.
Once == <><<Sound>>_vars

\* The recurrence reading: the bell sounds again and again.
Again == []<><<Sound>>_vars

\* The settling reading: from some point on, every step is a Sound step. Note
\* the square bracket. An angle action here is a semantic error, because the
\* box admits only [A]_v.
Forever == <>[][Sound]_vars
======================
