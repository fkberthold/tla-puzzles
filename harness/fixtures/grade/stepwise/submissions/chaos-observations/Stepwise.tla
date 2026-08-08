--------------------------- MODULE Stepwise ---------------------------
(***************************************************************************)
(* SUBMISSION: no structure at all, and NO LYING ANYWHERE.                  *)
(*                                                                          *)
(* This is the fixture beads tla-59s and tla-x8s exist for, and the first   *)
(* thing to say about it is what it is NOT. The observation operator is     *)
(* maximally honest: the state variable IS the observation and Observe is   *)
(* the identity on it. Nothing is fabricated, nothing is hidden, and no     *)
(* amount of scrutiny of the mapping would find anything wrong with it.     *)
(*                                                                          *)
(* The state machine is chaos over the observation space. Every permitted   *)
(* observation is an initial state and any permitted observation may follow *)
(* any other. There is no ordering, no causality, and nothing that could be *)
(* called a lockbox -- a box whose contents teleport from empty to full and *)
(* back is not a box.                                                       *)
(*                                                                          *)
(* WHY IT USED TO PASS, and it is worth being exact because the intuitive   *)
(* diagnosis is wrong. It is not that the grader was fooled. Every          *)
(* single-state requirement a reference can state about this system is      *)
(* TRUE of this spec, because its reachable observation set is exactly the  *)
(* admissible one. The maximally permissive spec passes obligation 1 by     *)
(* construction, for any reference, and it needs no lie to do it. Measured  *)
(* against the state-only `lockbox` reference that ships beside this one:   *)
(* verdict PASS, rc=0, Adequacy 2/2, Relational 1/1, zero witnesses.        *)
(*                                                                          *)
(* Step_onestep is what refuses it: the observation jumps from 0 to 3 in    *)
(* one step, which is a fact about a PAIR of observations and invisible to  *)
(* every predicate over one.                                                *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE obs

Permitted == 0..3

Init == obs \in Permitted

Next == obs' \in Permitted

Spec == Init /\ [][Next]_obs

Observe == [level |-> obs]

=============================================================================
