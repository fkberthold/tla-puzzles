------------------------------- MODULE Concrete -------------------------------
(***************************************************************************)
(* A GENUINE REFINEMENT FAILURE THAT EXITS 12 INSTEAD OF 13.                *)
(*                                                                          *)
(* The mapping is the correct, moving one from `correct/Concrete.tla`, and  *)
(* the concrete spec breaks exactly one of the abstract's three conjuncts:  *)
(*                                                                          *)
(*   Init            ticks = 0 maps to level = 0, so this holds.            *)
(*   [][Next]_vars   every Tick is a stutter or an Up, every Untick is a    *)
(*                   Down, and the abstract allows all three.               *)
(*   [](Hot => []Hot)  Untick from ticks = 3 takes the mapped level from 1  *)
(*                   back to 0, which is what this forbids.                 *)
(*                                                                          *)
(* So the refinement fails, and it fails on the conjunct TLC can refute     *)
(* with a finite prefix. rc=12, SAFETY_VIOLATION, with no invariant         *)
(* declared anywhere in the run A config. `broken/Concrete.tla` fails the   *)
(* implied action instead and exits 13, and the two rows together are what  *)
(* pin refinement.sh's routing of both codes.                               *)
(*                                                                          *)
(* Bead tla-nesz, which found run A reporting this as SAFETY_VIOLATION.     *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE ticks

vars == << ticks >>

Init == ticks = 0
Tick   == ticks < 6 /\ ticks' = ticks + 1
Untick == ticks >= 3 /\ ticks' = ticks - 3
Next == Tick \/ Untick

Spec == Init /\ [][Next]_vars

TypeOK == ticks \in 0..6

A == INSTANCE Abstract WITH level <- (ticks \div 3)

Refines == A!Spec

Probe == A!vars = << 0 >>

===============================================================================
