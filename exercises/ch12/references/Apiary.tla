---- MODULE Apiary ----
\* Exercise 2 reference answer.
\*
\* Pure TLA+, written directly. The whole exercise is the update expression:
\* a function-valued variable cannot be updated one key at a time, because an
\* action has to describe the WHOLE variable in the next state and
\* `frames[a]' = ...` describes exactly one key of it.
EXTENDS Integers

Hives == {"clover", "heather", "lime"}
MaxFrames == 3

VARIABLE frames

vars == << frames >>

Init == frames = [h \in Hives |-> 1]

\* One key, changed relative to its own old value. `@` is that old value, so
\* this reads "the same function as before, except that h's entry is one
\* higher".
AddFrame(h) == /\ frames[h] < MaxFrames
               /\ frames' = [frames EXCEPT ![h] = @ + 1]

\* Two keys, ONE EXCEPT. Each `@` is the old value of the key its own `!`
\* selected, so the two do not have to agree, and the whole thing is still a
\* single claim about `frames'`.
MoveFrame(a, b) == /\ a # b
                   /\ frames[a] > 0
                   /\ frames[b] < MaxFrames
                   /\ frames' = [frames EXCEPT ![a] = @ - 1, ![b] = @ + 1]

Next == \/ \E h \in Hives : AddFrame(h)
        \/ \E a, b \in Hives : MoveFrame(a, b)

Spec == Init /\ [][Next]_vars

FramesInRange == \A h \in Hives : frames[h] \in 0..MaxFrames
====
