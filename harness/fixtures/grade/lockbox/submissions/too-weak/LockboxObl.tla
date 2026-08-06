--------------------------- MODULE LockboxObl ---------------------------
(***************************************************************************)
(* One stated requirement, and it is TRUE of the reference. The Relational  *)
(* suite must therefore pass this submission even though the Adequacy suite *)
(* fails it -- the two verdicts are independent (V2-PLAN.md 5.2).           *)
(***************************************************************************)
EXTENDS Naturals

Req_never_negative(o) == o.level >= 0

=============================================================================
