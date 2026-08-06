---------------------------- MODULE Gate ----------------------------
(***************************************************************************)
(* Non-vacuity gate, per V2-PLAN.md section 5.3.  Lives in its OWN module   *)
(* on purpose: putting NonVacuous inside the spec under test and then       *)
(* naming it via -postCondition yields "Circular dependency among .tla      *)
(* files".                                                                  *)
(*                                                                          *)
(* Used here as the rc=10 lever: -postCondition "Gate!NonVacuous" exits 10  *)
(* when the predicate is FALSE, which is the same channel ASSUME FALSE uses.*)
(***************************************************************************)
EXTENDS Naturals, TLC

NonVacuous == TLCGet("distinct") >= 4

=============================================================================
