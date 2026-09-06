-------------------------------- MODULE Tiny --------------------------------
(***************************************************************************)
(* Fixture for harness/test-spike-measure.sh. Every number the test pins    *)
(* is a consequence of what is written here, so read this before changing   *)
(* a pinned figure.                                                         *)
(*                                                                          *)
(* Two variables, each climbing independently from 0 to 2. The reachable    *)
(* state space is therefore the 3 by 3 grid, 9 distinct states, and the     *)
(* longest path is 4 steps so the search depth is 5.                        *)
(*                                                                          *)
(* The invariant holds everywhere, so this run exits 0. That needs           *)
(* CHECK_DEADLOCK FALSE in the config: at (2,2) no action is enabled, and    *)
(* without it TLC calls the intended rest state a deadlock and exits 11.     *)
(* Broken.tla is the                                                        *)
(* same system with an invariant that fails.                                *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES x, y

vars == << x, y >>

Init == x = 0 /\ y = 0

BumpX == x < 2 /\ x' = x + 1 /\ y' = y
BumpY == y < 2 /\ y' = y + 1 /\ x' = x

Next == BumpX \/ BumpY

Spec == Init /\ [][Next]_vars

Bounded == x <= 2 /\ y <= 2

=============================================================================
