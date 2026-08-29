---- MODULE Palette ----
\* Exercise 2, the bottom of the chain. It holds the colour vocabulary and
\* nothing else, so it has no EXTENDS line at all.

Warm == {"red", "amber"}

Cool == {"green"}

IsWarm(c) == c \in Warm
====
