---- MODULE ChimeHold ----
EXTENDS Integers
VARIABLE strike
vars == <<strike>>

Init == strike = 0
Sound == strike' = (strike + 1) % 2
Next == Sound
Spec == Init /\ [][Next]_vars /\ WF_vars(Sound)

\* An angle action under <>[]. The outer shape is one TLC admits and the
\* inner bracket is the wrong one, so the module stops at semantic analysis.
Settles == <>[]<<Sound>>_vars
==========================
