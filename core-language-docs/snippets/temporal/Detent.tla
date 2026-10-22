---- MODULE Detent ----
EXTENDS Integers
VARIABLE notch
vars == <<notch>>

Init == notch = 0
Turn == notch < 2 /\ notch' = notch + 1
Hold == notch = 2 /\ UNCHANGED vars
Next == Turn \/ Hold

\* Slip is not a disjunct of Next, so [][Next]_vars forbids every Slip step.
Slip == notch' = 99

\* Fairness on a subaction of Next. This is the sound shape.
Live == Init /\ [][Next]_vars /\ WF_vars(Turn)

\* Fairness on an action Next does not allow. No behavior satisfies this.
Dead == Init /\ [][Next]_vars /\ WF_vars(Slip)

\* A liveness obligation no behavior can satisfy, whatever the spec.
Moves == []<>(notch # notch)

\* The same falsehood said over a state, which TLC lifts to an invariant.
Stuck == [](notch = 99)
=======================
