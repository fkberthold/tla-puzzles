---------------------------- MODULE Lockbox ----------------------------
(***************************************************************************)
(* SUBMISSION: does not parse. `Init ==` has no right-hand side.            *)
(*                                                                          *)
(* A broken submission must be reported as INVALID, never as a grade. The   *)
(* danger it pins is the one scripts/verify-puzzle.sh actually shipped: a   *)
(* spec that never parsed reported a PASS, because the check read TLC's     *)
(* stdout instead of its exit status. Here the PARSE_ERROR verdict comes    *)
(* from harness/verdict.sh's rc and is reported as its own outcome.         *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init ==

Next == level' = level

Spec == Init /\ [][Next]_level

Observe == [level |-> level]

=============================================================================
