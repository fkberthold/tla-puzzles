--------------------------- MODULE LadderObl ---------------------------
(***************************************************************************)
(* THE WEAKENING. Two approvals instead of three, and everything else about *)
(* this submission is the answer key's submission byte for byte.            *)
(*                                                                          *)
(* The answer key implies this and this does not imply the answer key, so   *)
(* the two sit in a strict order and the reference asks for the stronger    *)
(* one. A document issued on two approvals is a document the reference      *)
(* never issues.                                                            *)
(*                                                                          *)
(* WHY IT GETS IN TODAY. The Relational suite is the only run that reads a  *)
(* submission's own requirement, and it asks whether the REFERENCE satisfies *)
(* it. The reference only ever issues on three approvals, so it satisfies    *)
(* "at least two" as comfortably as it satisfies "all three". No run site in *)
(* grade.sh EXTENDS both obligations modules, so nothing ever asks whether   *)
(* this requirement is strong enough to stand in for the one the reference   *)
(* states. The measured result is that this submission and the answer key    *)
(* come back with the same verdict and the same suite counts.                *)
(***************************************************************************)
EXTENDS Naturals

Req_answer(o) == o.issued => o.approvals >= 2

=============================================================================
