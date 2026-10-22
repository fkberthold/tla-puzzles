---- MODULE Mainspring ----
EXTENDS Integers
VARIABLES coil, locked
vars == <<coil, locked>>

Init == coil = 0 /\ locked = FALSE

\* Wind says nothing about locked, so it does not describe a whole step.
Wind == coil < 2 /\ coil' = coil + 1

\* The same action with the missing half supplied.
WindOk == Wind /\ UNCHANGED locked

Stop == coil = 2 /\ UNCHANGED vars

\* Three next-state relations over the same action, two of them incomplete.
\* Loose and Solo differ only in whether the relation has a disjunct to name,
\* which is what decides which form of the message you get.
Loose == Init /\ [][Wind \/ Stop]_vars
Solo == Init /\ [][Wind]_vars
Tight == Init /\ [][WindOk \/ Stop]_vars

Bounded == coil <= 2
===========================
