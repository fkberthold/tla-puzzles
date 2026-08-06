------------------------------- MODULE Concrete -------------------------------
(***************************************************************************)
(* THE POSITIVE CONTROL. A correct concrete spec under a correct, MOVING    *)
(* refinement mapping.                                                      *)
(*                                                                          *)
(* Seven ticks map onto three abstract levels, three ticks to a level. Two  *)
(* of every three ticks leave `level` alone -- a stuttering step of the     *)
(* abstract -- and the third advances it, which is exactly `Up`. So this    *)
(* refines, and the mapped expression MOVES: it takes the values 0, 1 and 2 *)
(* over the reachable state space.                                          *)
(*                                                                          *)
(* `frozen/Concrete.tla` is this file with one line changed -- the WITH     *)
(* clause -- and nothing else. That is deliberate: it is what lets the      *)
(* fixture matrix show that the harness separates a meaningful refinement   *)
(* from a vacuous one on the strength of the MAPPING alone.                 *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE ticks

vars == << ticks >>

Init == ticks = 0
Tick == ticks < 6 /\ ticks' = ticks + 1
Next == Tick

Spec == Init /\ [][Next]_vars

TypeOK == ticks \in 0..6

(***************************************************************************)
(* The refinement mapping. Three ticks to a level.                          *)
(***************************************************************************)
A == INSTANCE Abstract WITH level <- (ticks \div 3)

Refines == A!Spec

(***************************************************************************)
(* A module-authored probe, present only so the raw-TLC guard matrix in     *)
(* fixtures/refinement/cfg/ has a bare identifier to name. THE HARNESS DOES *)
(* NOT USE IT and must not: a probe the submission authors is a probe the   *)
(* submission can forge, which is what `forged-probe/` demonstrates.        *)
(* refinement.sh always generates its own, named HarnessProbe.              *)
(***************************************************************************)
Probe == A!vars = << 0 >>

===============================================================================
