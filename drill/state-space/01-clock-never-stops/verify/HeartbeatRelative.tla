------------------------ MODULE HeartbeatRelative ------------------------
EXTENDS Naturals

CONSTANTS Timeout, Fence

ASSUME Timeout \in Nat
ASSUME Fence \in BOOLEAN

\* The supervisor never reads the clock. It reads how long since the last
\* beat, and past Timeout + 1 it stops caring how much longer. So `since`
\* is bounded by construction and there is no clock to bound.

VARIABLES since, primary, standby

vars == <<since, primary, standby>>

TypeOK ==
    /\ since \in 0..(Timeout + 1)
    /\ primary \in {"working", "paused", "fenced"}
    /\ standby \in {"idle", "working"}

Init ==
    /\ since = 0
    /\ primary = "working"
    /\ standby = "idle"

Tick ==
    /\ since' = IF since > Timeout THEN since ELSE since + 1
    /\ UNCHANGED <<primary, standby>>

Beat ==
    /\ primary = "working"
    /\ since' = 0
    /\ UNCHANGED <<primary, standby>>

Pause ==
    /\ primary = "working"
    /\ primary' = "paused"
    /\ UNCHANGED <<since, standby>>

Resume ==
    /\ primary = "paused"
    /\ primary' = "working"
    /\ UNCHANGED <<since, standby>>

Promote ==
    /\ standby = "idle"
    /\ since > Timeout
    /\ standby' = "working"
    /\ primary' = IF Fence THEN "fenced" ELSE primary
    /\ UNCHANGED since

Next == Tick \/ Beat \/ Pause \/ Resume \/ Promote

Spec == Init /\ [][Next]_vars

OneWorker == ~(primary = "working" /\ standby = "working")

==========================================================================
