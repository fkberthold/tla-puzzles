----------------------- MODULE MoveSetAtomicObl -----------------------
(***************************************************************************)
(* The degenerate model's own requirements, which are the statement's three *)
(* rendered over Observe. Nothing here is wrong. Each one is true of the    *)
(* faithful clerk as well, so obligation 2, PHI => psi_j, passes on all     *)
(* three and reports no over-constraint.                                    *)
(*                                                                          *)
(* That is the measurement this package exists for. A submission can state  *)
(* every rule the statement declares, state them correctly, and still have  *)
(* removed the mechanism.                                                    *)
(***************************************************************************)

Req_nothing_half_made(o) ==
  \A m \in DOMAIN o.sending : o.sending[m] # "part" /\ o.receiving[m] # "part"

Req_nobody_off_both(o) ==
  \A m \in DOMAIN o.sending : o.sending[m] = "on" \/ o.receiving[m] = "on"

Req_nobody_on_both(o) ==
  \A m \in DOMAIN o.sending : ~(o.sending[m] = "on" /\ o.receiving[m] = "on")

=============================================================================
