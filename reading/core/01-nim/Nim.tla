---- MODULE Nim ----
EXTENDS Integers

CONSTANT Heap
ASSUME Heap \in 1..15

\* Bitwise exclusive-or, built low bit first.
RECURSIVE _ (+) _
m (+) n ==
  IF m = 0 /\ n = 0
    THEN 0
    ELSE ((m + n) % 2) + (2 * ((m \div 2) (+) (n \div 2)))

VARIABLES a, b, c
vars == <<a, b, c>>

TypeOK ==
  /\ a \in 0..Heap
  /\ b \in 0..Heap
  /\ c \in 0..Heap

NimSum == (a (+) b) (+) c

Init == a = Heap /\ b = Heap /\ c = Heap

Take ==
  \/ \E k \in 1..a : a' = a - k /\ UNCHANGED <<b, c>>
  \/ \E k \in 1..b : b' = b - k /\ UNCHANGED <<a, c>>
  \/ \E k \in 1..c : c' = c - k /\ UNCHANGED <<a, b>>

Next == Take

Spec == Init /\ [][Next]_vars

NoEscape == [][NimSum = 0 => NimSum' # 0]_vars

ZeroIsOneMoveAway ==
  LET Flat(x, y, z) == (x (+) y) (+) z = 0
  IN  NimSum # 0 =>
        \/ \E k \in 0..a : k < a /\ Flat(k, b, c)
        \/ \E k \in 0..b : k < b /\ Flat(a, k, c)
        \/ \E k \in 0..c : k < c /\ Flat(a, b, k)
====
