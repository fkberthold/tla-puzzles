----------------------- MODULE AssertViolation -----------------------
(***************************************************************************)
(* rc=14 fixture (EC.TLC_VALUE_ASSERT_FAILED = 2132).                       *)
(*                                                                          *)
(* Assert's first argument is FALSE at x = 2, and the failure happens while *)
(* TLC is exploring BEHAVIOUR -- x = 0 and x = 1 both satisfy it, so the    *)
(* initial state computes cleanly and the run is already in the next-state  *)
(* relation when the assertion blows up.                                    *)
(*                                                                          *)
(* WHEN the assertion fires is the whole fixture. The identical Assert in   *)
(* Init is rc=75, not rc=14 -- see AssertInInit.tla, which is this spec's   *)
(* twin and exists to pin that boundary. Moving this Assert into Init, or   *)
(* weakening it so it fails on the initial state, silently converts this    *)
(* fixture into a duplicate of that one and deletes the rc=14 row.          *)
(***************************************************************************)
EXTENDS Naturals, TLC

VARIABLE x

Init == x = 0
Next == /\ Assert(x < 2, "x reached 2 in Next")
        /\ x' = (x + 1) % 3
Spec == Init /\ [][Next]_x

TypeOK == x \in 0..2

=============================================================================
