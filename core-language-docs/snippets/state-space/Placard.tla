---- MODULE Placard ----
EXTENDS Integers
CONSTANTS Vacant, Taken
VARIABLE slot

Init == slot = Vacant
Claim == slot = Vacant /\ slot' = Taken
Held == slot = Taken /\ UNCHANGED slot
Next == Claim \/ Held
Spec == Init /\ [][Next]_<<slot>>

\* The string spelled like the model value is a different value, and the
\* comparison is FALSE rather than an error.
Opaque == slot # "Taken"

Honest == slot # Taken

\* An order comparison on a model value is the one that stops the run.
Ranked == Vacant < Taken
========================
