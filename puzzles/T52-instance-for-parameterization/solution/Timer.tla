---- MODULE Timer ----
EXTENDS Integers

CONSTANT MaxMinutes

ASSUME MaxMinutes \in Nat
ASSUME MaxMinutes >= 1

Range == 0..MaxMinutes

Ringing(t) == t = MaxMinutes

====
