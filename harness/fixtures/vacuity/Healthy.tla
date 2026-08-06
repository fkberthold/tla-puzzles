--------------------------- MODULE Healthy ---------------------------
(***************************************************************************)
(* THE POSITIVE CONTROL. Nothing is wrong with this spec, and vacuity.sh    *)
(* must say so.                                                             *)
(*                                                                          *)
(*   - 5 distinct states (0..4), so Gate!NonVacuous (>= 4) holds;           *)
(*   - Healthy.cfg configures a real INVARIANT, so                          *)
(*     Gate!InvariantConfigured holds;                                      *)
(*   - both Up and Down fire, so no action is dead.                         *)
(*                                                                          *)
(* It is also the carrier for the cfg-only fixtures. DanglingInvariant.cfg  *)
(* is applied to THIS module, because vector 2's whole point is that the    *)
(* module is fine and the checking is what went missing.                    *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE counter

Init == counter = 0
Up   == counter < 4 /\ counter' = counter + 1
Down == counter > 0 /\ counter' = counter - 1
Next == Up \/ Down
Spec == Init /\ [][Next]_counter

Bounded == counter \in 0..4

=============================================================================
