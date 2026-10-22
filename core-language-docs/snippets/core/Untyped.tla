---- MODULE Untyped ----
EXTENDS Integers
VARIABLE box

Init == box = 0
Flip == box' = IF box = 0 THEN "zero" ELSE 0
Next == Flip
Spec == Init /\ [][Next]_<<box>>

\* Comparing an integer to a string. This is a claim, and it is false.
Never == box = "0"

\* The box holds an integer. Nothing in the spec promises that.
Numeric == box \in Int

\* The same claim against a bounded interval.
Interval == box \in 0..3

\* And against an explicit set.
Bounded == box \in {0, 1, 2, 3}
=========================
