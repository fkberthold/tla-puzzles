--------------------------- MODULE MCRetransmit ---------------------------
EXTENDS Retransmit

CONSTANT MaxAttempts

ASSUME MaxAttempts \in Nat

\* Knob: cut the graph at the counter. Named as CONSTRAINT AttemptsBound.
AttemptsBound == attempts <= MaxAttempts

\* The other knob: a sender that gives up. This is a different system, and
\* the requirement has to say so.
BoundedSend == Send /\ attempts < MaxAttempts
BoundedNext == BoundedSend \/ Drop \/ Deliver
BoundedSpec == Init /\ [][BoundedNext]_vars /\ WF_vars(BoundedSend) /\ SF_vars(Deliver)

AckedOrGaveUp == <>(acked \/ attempts = MaxAttempts)

==========================================================================
