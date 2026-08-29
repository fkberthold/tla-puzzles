---- MODULE Band ----
\* Exercise 3, the library. Ships complete and is not edited.
\*
\* An abstract range with no idea what it is a range of. The two constants
\* are what a caller fills in, and filling them in twice under two names is
\* what makes one file serve two rooms.
EXTENDS Integers

CONSTANTS Lo, Hi

ASSUME Lo \in Int /\ Hi \in Int /\ Lo <= Hi

Holds(v) == v \in Lo..Hi

Headroom(v) == Hi - v
====
