--------------------------- MODULE LockboxObl ---------------------------
(***************************************************************************)
(* The submission's OWN stated requirements, psi_j. Variable-free, over the *)
(* observation record `o`, same shape as the reference package's half.      *)
(*                                                                          *)
(* grade.sh checks `PHI => psi_j` for each of these: the reference must     *)
(* satisfy every requirement the submission states. A psi_j the reference   *)
(* violates is over-constraint, and the witness is a location IN THIS FILE  *)
(* -- the submission's own text, which is what 3.7 says feedback may be.    *)
(***************************************************************************)
EXTENDS Naturals

Req_within_capacity(o) == o.level \in 0..3

=============================================================================
