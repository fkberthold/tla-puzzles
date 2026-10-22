---- MODULE Merge ----
EXTENDS Integers, TLC
VARIABLE f

\* A function with a gappy domain, built one pair at a time.
Init == f = 2 :> 20 @@ 5 :> 50
Next == f' = f @@ (11 :> 110)
Spec == Init /\ [][Next]_<<f>>

\* On a key both sides hold, the LEFT operand wins.
LeftWins == (f @@ (2 :> 999))[2] = 20
RightWins == (f @@ (2 :> 999))[2] = 999

\* :> builds a one-pair function, and @@ joins them into a literal's equal.
Singleton == (7 :> "v") = [i \in {7} |-> "v"]
Dense == (2 :> 2 @@ 3 :> 3 @@ 4 :> 4) = [i \in 2..4 |-> i]

\* The domain is whatever was named, with no pattern to fit.
Gaps == DOMAIN f \subseteq {2, 5, 11}

\* The three notations TLC prints a function in, asserted as equalities. A
\* domain of 1..n prints as a sequence and a domain of strings as a record,
\* so what the printer picks is the shortest notation the domain allows.
Printed == /\ [i \in 1..3 |-> i * i] = <<1, 4, 9>>
           /\ [i \in {"p", "q"} |-> 1] = [p |-> 1, q |-> 1]

Holds == LeftWins /\ Singleton /\ Dense /\ Gaps /\ Printed
=====================
