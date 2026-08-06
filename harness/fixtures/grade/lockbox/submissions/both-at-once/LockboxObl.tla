--------------------------- MODULE LockboxObl ---------------------------
(***************************************************************************)
(* The stated requirement that makes this submission too strong. The        *)
(* reference reaches level 3, so `PHI => Req_never_three` is refuted and    *)
(* the over-constraint witness points here.                                 *)
(***************************************************************************)
EXTENDS Naturals

Req_never_three(o) == o.level # 3

=============================================================================
