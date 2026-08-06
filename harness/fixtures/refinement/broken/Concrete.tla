------------------------------- MODULE Concrete -------------------------------
(***************************************************************************)
(* THE NEGATIVE CONTROL FOR THE REFINEMENT CHANNEL ITSELF.                  *)
(*                                                                          *)
(* The mapping is the correct, moving one from correct/Concrete.tla. What   *)
(* is wrong is the CONCRETE SPEC: `Untick` lets ticks fall, so the mapped   *)
(* level can go DOWN, and the abstract only ever climbs. TLC reports the    *)
(* implied-action violation.                                                *)
(*                                                                          *)
(* Without this fixture "correct/ passes" is unfalsifiable -- a harness     *)
(* that reported REFINES for everything would score full marks on every     *)
(* other row of the matrix. This is the row that says the refinement check  *)
(* is switched on.                                                          *)
(*                                                                          *)
(* Note what it does NOT fail on: the probe is perfectly healthy here,      *)
(* because the mapping moves. Broken spec, sound mapping -- the opposite    *)
(* pairing from frozen/, and the reason the two channels are reported       *)
(* separately.                                                              *)
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
