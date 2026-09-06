---------------------------- MODULE MCFencedRestartLockout ----------------------------
(***************************************************************************)
(* FencedRestart.tla with Strict = TRUE, checking availability rather than *)
(* safety. The strict fence is safe under a counter reset -- and it refuses *)
(* the client that currently holds a LIVE lease, permanently. Expect 12.   *)
(***************************************************************************)
EXTENDS FencedRestart

=============================================================================
