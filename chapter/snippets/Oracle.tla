----------------------------- MODULE Oracle -----------------------------
(***************************************************************************)
(* The abstract spec decides at time zero and announces later.             *)
(***************************************************************************)
CONSTANT Vals

VARIABLES pick, done
vars == << pick, done >>

Init ==
  /\ pick \in Vals
  /\ done = FALSE

Announce ==
  /\ ~done
  /\ done' = TRUE
  /\ UNCHANGED pick

Next == Announce

Spec == Init /\ [][Next]_vars
=========================================================================
