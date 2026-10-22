---- MODULE Meter ----
EXTENDS Integers
VARIABLE m

Keys == {"a", "b"}

\* A record whose count field is itself a function.
Init == m = [count |-> [k \in Keys |-> 0], last |-> "none"]

\* @ is the value at the position the selector names, so the increment
\* never spells the function out a second time. Two clauses, one step.
Tick(k) == m' = [m EXCEPT !.count[k] = @ + 1, !.last = k]

Next == \E k \in Keys : Tick(k)
Spec == Init /\ [][Next]_<<m>>
Cap == m.count["a"] + m.count["b"] <= 2

\* Two clauses on the SAME key. The second @ reads the first clause's
\* result, not the value the step started from: 10 then 100 lands on 110.
Chain == [m.count EXCEPT !["a"] = @ + 10, !["a"] = @ + 100]
Chained == Chain["a"] = m.count["a"] + 110
Naive == Chain["a"] = m.count["a"] + 100

\* The nested selector is the two-level form written short.
Nested == [m EXCEPT !.count["a"] = @ + 1]
            = [m EXCEPT !.count = [@ EXCEPT !["a"] = @ + 1]]

Holds == Chained /\ Nested
=====================
