--------------------------- MODULE LockboxObl ---------------------------
(***************************************************************************)
(* Well-formed on purpose. The fault under test is in Lockbox.tla, so this  *)
(* half must not be the reason the run fails.                               *)
(***************************************************************************)
EXTENDS Naturals

Req_never_negative(o) == o.level >= 0

=============================================================================
