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

\* Two next-state relations over the same action, one of them incomplete.
Loose == Init /\ [][Wind \/ Stop]_vars
Tight == Init /\ [][WindOk \/ Stop]_vars

Bounded == coil <= 2
===========================
