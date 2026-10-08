---------------------------- MODULE MCBrokenStuck ---------------------------
(***************************************************************************)
(* The terminal trap as a state invariant, so the liveness failure has a    *)
(* safety surrogate that cheap tooling can grade.  The seeded-bug matrix in *)
(* harness/seeded-bugs.sh writes `INVARIANT <prop>` and nothing else, so an *)
(* invariant is the only shape it can take -- see REPORT.md.               *)
(*                                                                         *)
(* Expect exit 12.                                                        *)
(***************************************************************************)
EXTENDS TxnBroken

=============================================================================
