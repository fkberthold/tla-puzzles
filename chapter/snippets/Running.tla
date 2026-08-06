----------------------------- MODULE Running -----------------------------
(***************************************************************************)
(* The implementation keeps a count and a total.  It does not keep the     *)
(* values.  There is no expression over `num` and `sum` that equals the    *)
(* sequence of values -- the information is gone.                          *)
(*                                                                         *)
(* Adapted from Lamport and Merz, Prophecy Made Simple, section 3.1 --     *)
(* their specification A.                                                  *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Vals, MaxInputs

VARIABLES num, sum
vars == << num, sum >>

Init == num = 0 /\ sum = 0

Take(v) ==
  /\ num < MaxInputs
  /\ num' = num + 1
  /\ sum' = sum + v

Next == \E v \in Vals : Take(v)

Spec == Init /\ [][Next]_vars
=========================================================================
