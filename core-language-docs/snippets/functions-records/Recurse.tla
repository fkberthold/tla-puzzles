---- MODULE Recurse ----
EXTENDS Integers
VARIABLE n

\* The bracket form. It calls itself, and there is no RECURSIVE line.
Fact[i \in 0..5] == IF i = 0 THEN 1 ELSE i * Fact[i - 1]

\* Sugar for the same thing, written as a literal.
FactLit == [i \in 0..5 |-> IF i = 0 THEN 1 ELSE i * Fact[i - 1]]

Init == n = 0
Next == n' = (n + 1) % 6
Spec == Init /\ [][Next]_<<n>>

\* The same form over an infinite domain. TLC evaluates lazily, so applying
\* it costs nothing. Forcing the whole value would not terminate.
Up[i \in Nat] == IF i = 0 THEN 0 ELSE Up[i - 1] + 1

Known == Fact[0] = 1 /\ Fact[5] = 120
Grows == Fact[n] >= n
Sugar == Fact = FactLit
Domain == DOMAIN Fact = 0..5
Infinite == Up[4] = 4

Holds == Known /\ Grows /\ Sugar /\ Domain /\ Infinite
=======================
