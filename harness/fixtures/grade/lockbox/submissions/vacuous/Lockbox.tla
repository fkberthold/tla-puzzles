---------------------------- MODULE Lockbox ----------------------------
(***************************************************************************)
(* SUBMISSION: vacuous. `Init` is unsatisfiable, so the state space is      *)
(* empty and every safety obligation holds over no states at all.           *)
(*                                                                          *)
(* THIS IS THE FIXTURE THAT JUSTIFIES OBLIGATION 3. Obligation 1 grades it  *)
(* PERFECT -- every reference conjunct is satisfied, vacuously -- and the   *)
(* selftest asserts exactly that alongside the vacuity failure, so the      *)
(* consequence of deleting the vacuity check is visible in the fixture      *)
(* matrix rather than only in a comment.                                    *)
(*                                                                          *)
(* Deadlock checking does not catch this. TLC reports "No error has been    *)
(* found", 0 states generated, rc=0 (V2-PLAN.md 5.3).                       *)
(*                                                                          *)
(* It is also the MAXIMALLY over-constrained spec, which is why whole-spec  *)
(* refinement against a gold reference passes it: it refines everything.    *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0 /\ level = 1

Next == level' = level

Spec == Init /\ [][Next]_level

Observe == [level |-> level]

=============================================================================
