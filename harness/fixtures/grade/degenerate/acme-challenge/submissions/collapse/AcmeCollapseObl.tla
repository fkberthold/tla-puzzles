----------------------- MODULE AcmeCollapseObl -----------------------
(***************************************************************************)
(* The collapse's own requirements: the statement's requirements 1 and 2,   *)
(* which are the two of the nine declared as an INVARIANT. Both are true of *)
(* the collapse, which is why a learner who built it would state them.      *)
(*                                                                          *)
(* REQUIREMENT 1 IS WHERE THIS PACKAGE DIFFERS FROM THE OTHER THREE. The    *)
(* faithful office refutes it, so obligation 2, PHI => psi_j, catches the    *)
(* collapse without the landmark having to. Both flags fire, and the        *)
(* grader prefers the stated requirement as the witness because it has a    *)
(* location in the learner's own code.                                      *)
(*                                                                          *)
(* That second catch is a finding about the statement rather than about the *)
(* collapse. Any submission stating requirement 1 draws it, because the     *)
(* requirement asks for more than the rules it was written over allow.       *)
(***************************************************************************)
EXTENDS Naturals

Req_entry_means_refused(o) ==
  \A a \in DOMAIN o.standing : o.defects[a] >= 1 => o.standing[a] = "refused"

Req_refusal_after_giveup(o) ==
  \A a \in DOMAIN o.standing : o.standing[a] = "refused" => o.givenUp[a]

=============================================================================
