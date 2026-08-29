---- MODULE Signal ----
\* Exercise 2, the middle of the chain. It builds the escalation policy on
\* top of the vocabulary, and it is the one line in this exercise you edit.

INSTANCE Palette

Escalated(c) == IsWarm(c) /\ c # "amber"
====
