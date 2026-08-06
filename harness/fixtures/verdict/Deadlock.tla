-------------------------- MODULE Deadlock --------------------------
(***************************************************************************)
(* rc=11 fixture.  Next is enabled only while x < 2, so the state x = 2     *)
(* has no successor: a genuine deadlock.                                    *)
(*                                                                          *)
(* Requires deadlock CHECKING to be on.  TLC's -deadlock flag means "do NOT *)
(* check for deadlock", and it is present in the canonical invocation, so   *)
(* verdict.sh must be run with --check-deadlock for this fixture to reach   *)
(* rc=11 at all.                                                            *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x < 2 /\ x' = x + 1
Spec == Init /\ [][Next]_x

=============================================================================
