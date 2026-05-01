---- MODULE Lock ----
EXTENDS Integers

VARIABLE state

TypeOK == state \in {"locked", "unlocked"}

Locked == state = "locked"

LockIt ==
  /\ state = "unlocked"
  /\ state' = "locked"

Unlock ==
  /\ state = "locked"
  /\ state' = "unlocked"

Stable == UNCHANGED state

Init == state = "locked"

Next == LockIt \/ Unlock

EventuallyUnlocked == <>(state = "unlocked")

NeverDoubleLocked == [](state \in {"locked", "unlocked"})

Spec == Init /\ [][Next]_state /\ WF_state(Unlock)
====
