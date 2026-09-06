--------------------------- MODULE MCFencedWitness --------------------------
(***************************************************************************)
(* The vacuity probe for Fenced.tla, at the same model size.               *)
(*                                                                         *)
(* Fenced.tla exits 0. On its own that result is also what you would get    *)
(* from a storage service that accepts NOTHING, since a log that stays      *)
(* empty is trivially in increasing order. So this run checks the opposite  *)
(* claim: TwoWritesLand says fewer than two writes ever land, and it is     *)
(* meant to FAIL. The counterexample is the evidence that the fenced        *)
(* system still does the work.                                             *)
(*                                                                         *)
(* Expect TLC to exit 12 here. A 0 would mean Fenced.tla passes vacuously.  *)
(***************************************************************************)
EXTENDS Fenced

=============================================================================
