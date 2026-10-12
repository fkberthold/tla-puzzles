----------------------- MODULE RetransmitNoCounter -----------------------

\* The same sender with the counter deleted. Nothing read it, so nothing
\* changes except that the reachable graph is now four states and liveness
\* can be checked on all of it.

VARIABLES msg, acked

vars == <<msg, acked>>

TypeOK ==
    /\ msg \in {"none", "inflight"}
    /\ acked \in BOOLEAN

Init ==
    /\ msg = "none"
    /\ acked = FALSE

Send ==
    /\ msg = "none"
    /\ ~acked
    /\ msg' = "inflight"
    /\ UNCHANGED acked

Drop ==
    /\ msg = "inflight"
    /\ msg' = "none"
    /\ UNCHANGED acked

Deliver ==
    /\ msg = "inflight"
    /\ msg' = "none"
    /\ acked' = TRUE

Next == Send \/ Drop \/ Deliver

Spec == Init /\ [][Next]_vars /\ WF_vars(Send) /\ SF_vars(Deliver)

SpecNoSenderFairness == Init /\ [][Next]_vars /\ SF_vars(Deliver)

EventuallyAcked == <>acked

==========================================================================
