---- MODULE Grouped ----
EXTENDS Integers
VARIABLE n

Init == n = 0
Next == n' = n + 1

Spec == Init /\ [][Next]_<<n>>

Cap == n <= 2

Paren == (n = 0 /\ n < 5) \/ (n = 1 /\ n < 5)

Bullet == \/ /\ n = 0
             /\ n < 5
          \/ /\ n = 1
             /\ n < 5

Same == Paren = Bullet
=========================
