----------------------- MODULE TranscriptFloor -----------------------
(***************************************************************************)
(* THE TRANSCRIPTION SHAPE, at the scale the bug was measured at.           *)
(*                                                                          *)
(* Custody step 4 found a 24-state deterministic script that replays the    *)
(* published satisfying trace and passes every obligation. This is that     *)
(* submission in miniature: a linear chain of scripted steps with no        *)
(* branching anywhere. There is exactly one successor per state, so the     *)
(* spec chooses nothing and models nothing -- it recites.                   *)
(*                                                                          *)
(*   - 12 distinct states (0..11), so it clears Gate!NonVacuous (>= 4)      *)
(*     COMFORTABLY. That is the whole point: the placeholder floor is not   *)
(*     a near miss here, it is three times clear.                           *)
(*   - TranscriptFloor.cfg configures a real INVARIANT, so                  *)
(*     Gate!InvariantConfigured holds;                                      *)
(*   - both Climb and Coast fire, so no action is dead.                     *)
(*                                                                          *)
(* Every probe vacuity.sh owns therefore passes it, and a problem whose     *)
(* floor is left at the placeholder waves it through. Only a per-problem    *)
(* floor above 12 can see it, which is why the floor cannot be optional.    *)
(*                                                                          *)
(* Its matched pair is ModelledFloor.tla: the same domain actually          *)
(* modelled, 40 distinct states, run against the SAME floor.                *)
(*                                                                          *)
(* The terminal state at step = 11 has no successor. That is deliberate     *)
(* and harmless -- a script ends -- because verdict.sh leaves deadlock      *)
(* checking OFF by default (verdict.sh:333, TLC's -deadlock flag is         *)
(* present unless --check-deadlock removes it).                             *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE step

Init  == step = 0
Climb == step < 6 /\ step' = step + 1
Coast == step >= 6 /\ step < 11 /\ step' = step + 1
Next  == Climb \/ Coast
Spec  == Init /\ [][Next]_step

Scripted == step \in 0..11

=============================================================================
