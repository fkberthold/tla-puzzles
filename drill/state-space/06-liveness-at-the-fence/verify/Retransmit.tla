---------------------------- MODULE Retransmit ----------------------------
EXTENDS Naturals

\* A sender puts one message on a lossy link and resends until it is
\* acknowledged. The attempt counter is there because somebody wanted a
\* number to bound. Nothing reads it.

VARIABLES msg, acked, attempts

vars == <<msg, acked, attempts>>

TypeOK ==
    /\ msg \in {"none", "inflight"}
    /\ acked \in BOOLEAN
    /\ attempts \in Nat

Init ==
    /\ msg = "none"
    /\ acked = FALSE
    /\ attempts = 0

Send ==
    /\ msg = "none"
    /\ ~acked
    /\ msg' = "inflight"
    /\ attempts' = attempts + 1
    /\ UNCHANGED acked

Drop ==
    /\ msg = "inflight"
    /\ msg' = "none"
    /\ UNCHANGED <<acked, attempts>>

Deliver ==
    /\ msg = "inflight"
    /\ msg' = "none"
    /\ acked' = TRUE
    /\ UNCHANGED attempts

Next == Send \/ Drop \/ Deliver

\* The link is lossy but not dead: a message that keeps being sent is
\* eventually delivered. Strong fairness, since Deliver is disabled on
\* every step where the link has just dropped.
Spec == Init /\ [][Next]_vars /\ WF_vars(Send) /\ SF_vars(Deliver)

\* The same system with the sender's fairness left out, for the second
\* cell of the measurement.
SpecNoSenderFairness == Init /\ [][Next]_vars /\ SF_vars(Deliver)

EventuallyAcked == <>acked

==========================================================================
