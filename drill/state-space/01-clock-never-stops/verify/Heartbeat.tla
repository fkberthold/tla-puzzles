---------------------------- MODULE Heartbeat ----------------------------
EXTENDS Naturals

CONSTANTS Timeout, Fence

ASSUME Timeout \in Nat
ASSUME Fence \in BOOLEAN

VARIABLES clock, lastBeat, primary, standby

vars == <<clock, lastBeat, primary, standby>>

TypeOK ==
    /\ clock \in Nat
    /\ lastBeat \in Nat
    /\ primary \in {"working", "paused", "fenced"}
    /\ standby \in {"idle", "working"}

Init ==
    /\ clock = 0
    /\ lastBeat = 0
    /\ primary = "working"
    /\ standby = "idle"

Tick ==
    /\ clock' = clock + 1
    /\ UNCHANGED <<lastBeat, primary, standby>>

Beat ==
    /\ primary = "working"
    /\ lastBeat' = clock
    /\ UNCHANGED <<clock, primary, standby>>

Pause ==
    /\ primary = "working"
    /\ primary' = "paused"
    /\ UNCHANGED <<clock, lastBeat, standby>>

Resume ==
    /\ primary = "paused"
    /\ primary' = "working"
    /\ UNCHANGED <<clock, lastBeat, standby>>

Promote ==
    /\ standby = "idle"
    /\ clock - lastBeat > Timeout
    /\ standby' = "working"
    /\ primary' = IF Fence THEN "fenced" ELSE primary
    /\ UNCHANGED <<clock, lastBeat>>

Next == Tick \/ Beat \/ Pause \/ Resume \/ Promote

Spec == Init /\ [][Next]_vars

OneWorker == ~(primary = "working" /\ standby = "working")

==========================================================================
