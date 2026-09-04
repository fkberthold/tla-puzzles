------------------------ MODULE ModelledFloor ------------------------
(***************************************************************************)
(* THE NEGATIVE CONTROL FOR THE FLOOR, and it is the half without which     *)
(* the floor cannot be shown to bite. A floor that flagged every            *)
(* submission would satisfy the positive row on its own.                    *)
(*                                                                          *)
(* Same domain as TranscriptFloor.tla, actually modelled: the step can go   *)
(* both ways, so the state space is explored rather than recited. 40        *)
(* distinct states (0..39).                                                 *)
(*                                                                          *)
(* The pair is run at ONE floor, not two. TranscriptFloor at --min-states   *)
(* 24 is flagged and ModelledFloor at --min-states 24 is not, so the        *)
(* discriminating thing is the submission and not the number. The existing  *)
(* Healthy.tla rows in test-vacuity.sh run the opposite experiment -- one   *)
(* fixture at two floors -- and neither direction substitutes for the       *)
(* other.                                                                   *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE step

Init == step = 0
Up   == step < 39 /\ step' = step + 1
Down == step > 0 /\ step' = step - 1
Next == Up \/ Down
Spec == Init /\ [][Next]_step

Modelled == step \in 0..39

=============================================================================
