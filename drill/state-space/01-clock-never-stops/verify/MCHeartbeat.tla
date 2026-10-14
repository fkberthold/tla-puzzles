--------------------------- MODULE MCHeartbeat ---------------------------
EXTENDS Heartbeat

CONSTANT MaxTime

ASSUME MaxTime \in Nat

\* Knob 1: bound the clock inside the behavior formula. The system TLC
\* checks is one whose clock stops at MaxTime.
BoundedNext == Next /\ clock' <= MaxTime
BoundedSpec == Init /\ [][BoundedNext]_vars

\* Knob 2: leave Spec alone and tell TLC which states to expand.
\* Named in the .cfg as CONSTRAINT ClockBound.
ClockBound == clock <= MaxTime

\* Knob 3: the same bound keyed on the step rather than the state.
\* Named in the .cfg as ACTION_CONSTRAINT TickWithin.
TickWithin == clock' <= MaxTime

\* Probe: is a state outside the CONSTRAINT still checked against the
\* invariants, or only dropped? Declared as INVARIANT InsideBound next to
\* CONSTRAINT ClockBound. If TLC checks before it drops, this is violated.
InsideBound == clock <= MaxTime

==========================================================================
