---- MODULE Marquee ----
EXTENDS Integers
VARIABLES lamp, ticks
vars == <<lamp, ticks>>

Init == lamp = 0 /\ ticks = 0
Flip == lamp' = 1 - lamp /\ ticks' = ticks + 1
Next == Flip
Spec == Init /\ [][Next]_vars

Short == ticks <= 2

\* A record built from the variables. Named by ALIAS it dresses a trace. Named
\* by INVARIANT it is a record where TLC wants a Boolean.
Board == [light |-> lamp, elapsed |-> ticks, warm |-> ticks > 0]
========================
