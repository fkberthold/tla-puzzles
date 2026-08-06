--------------------------- MODULE LockboxObl ---------------------------
(***************************************************************************)
(* A requirement that is true of everything, so the Relational suite's      *)
(* stated-requirement member cannot be what catches this submission.        *)
(***************************************************************************)
EXTENDS Naturals

Req_trivial(o) == o.level >= 0

=============================================================================
