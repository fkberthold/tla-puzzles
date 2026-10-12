---- MODULE HeartbeatRefused ----
\* Neighbours that TLC or SANY refuses outright. They live apart from
\* Heartbeat so that a rejection here cannot fail the runs over there.
EXTENDS Heartbeat

N5 == []<>Beat
N6 == []<<Beat>>_last
====
