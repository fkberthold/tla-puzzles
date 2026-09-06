-------------------------- MODULE ProbeSnapshotLU --------------------------
(***************************************************************************)
(* Vacuity probes for LostUpdateSnapshot, which passed.                    *)
(*                                                                         *)
(* Snapshot isolation prevents lost update by refusing a commit. That is    *)
(* only a real prevention if BOTH of the following are refuted: the counter *)
(* can still reach 2 when the two clients do not overlap, and an abort      *)
(* really happens when they do.                                             *)
(***************************************************************************)
EXTENDS LostUpdateSnapshot

\* Refuted means: both increments can land, so the invariant did not
\* survive by the counter being stuck.
CounterNeverTwo == store[Counter] # 2

\* Refuted means: first committer wins actually fires.
NobodyAborts == \A t \in Txn : state[t] # "aborted"

==========================================================================
