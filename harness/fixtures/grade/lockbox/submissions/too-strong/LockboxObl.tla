--------------------------- MODULE LockboxObl ---------------------------
(***************************************************************************)
(* A requirement the reference violates. This is over-constraint stated out *)
(* loud, so the witness for it is a location in this file.                  *)
(***************************************************************************)
EXTENDS Naturals

Req_at_most_one(o) == o.level =< 1

=============================================================================
