\* a fixture machine: a counter that is driven up to two, dropped straight back to nothing, and driven up again for ever, beside a flag that flips.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES n, flag
vars == <<n, flag>>
Init == n = 0 /\ flag = 0
Step == n < 2 /\ n' = n + 1 /\ flag' = flag
Fall == n = 2 /\ n' = 0 /\ flag' = flag
Flip == flag' = 1 - flag /\ n' = n
Next == Step \/ Fall \/ Flip
Spec == Init /\ [][Next]_vars /\ WF_vars(Step) /\ WF_vars(Fall) /\ WF_vars(Flip)
Checked ==
__ANSWER__
====
