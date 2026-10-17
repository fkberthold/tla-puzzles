\* a fixture machine: a counter that can be stepped up twice and then stops, beside a flag that flips for ever, so something can always move.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES n, flag
vars == <<n, flag>>
Init == n = 0 /\ flag = 0
Step == n < 2 /\ n' = n + 1 /\ flag' = flag
Flip == flag' = 1 - flag /\ n' = n
Next == Step \/ Flip
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ Fair
Tops == <>(n = 2)
====
