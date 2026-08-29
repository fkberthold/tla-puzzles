---- MODULE Drawbridge ----
\* Exercise 4 reference answer.
\*
\* The starter ships this same module without the comments below. The `\A` form
\* is what makes `BridgeRaised` hold, and the exercise is a prediction about
\* this file and about swapping that one quantifier for `\E`.
EXTENDS Integers

Winches == {"north", "south"}
Target == 2

VARIABLE turns

vars == << turns >>

Init == turns = [w \in Winches |-> 0]

Raise(w) == /\ turns[w] < Target
            /\ turns' = [turns EXCEPT ![w] = @ + 1]

Next == \E w \in Winches : Raise(w)

\* `\A`: every winch is fair, so every winch keeps turning while it still can.
\* `\E` says only that SOME winch is fair, which one winch alone can satisfy
\* while the other stands still forever.
Spec == /\ Init
        /\ [][Next]_vars
        /\ \A w \in Winches : WF_vars(Raise(w))

BridgeRaised == <>(\A w \in Winches : turns[w] = Target)
====
