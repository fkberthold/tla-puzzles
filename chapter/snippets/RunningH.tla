---------------------------- MODULE RunningH ----------------------------
(***************************************************************************)
(* Running, with a history variable `h` bolted on.  `h` records what the   *)
(* implementation was handed.  Nothing in the implementation reads it.     *)
(*                                                                         *)
(* Two checks live here, and they are the two halves of the obligation     *)
(* that adding `h` changed nothing:                                        *)
(*                                                                         *)
(*   Refines       -- RunningH implements Ledger under `log <- h`.         *)
(*                    This is the point of adding h.                       *)
(*                                                                         *)
(*   NoNewBehavior -- RunningH implements Running under the identity on    *)
(*                    num and sum.  This is half of "h changed nothing":   *)
(*                    the half a model checker can do.                     *)
(*                                                                         *)
(* The other half -- that h forbids nothing Running allowed -- is not a    *)
(* refinement check and TLC cannot do it.  For a history variable you get  *)
(* it by construction: `h` is only ever conjoined to an existing action,   *)
(* and its new value is uniquely determined, so no behavior is lost.       *)
(***************************************************************************)
EXTENDS Sequences, Naturals

CONSTANTS Vals, MaxInputs

VARIABLES num, sum, h
vars == << num, sum, h >>

Init == num = 0 /\ sum = 0 /\ h = << >>

Take(v) ==
  /\ num < MaxInputs
  /\ num' = num + 1
  /\ sum' = sum + v
  /\ h'   = Append(h, v)

Next == \E v \in Vals : Take(v)

Spec == Init /\ [][Next]_vars

L == INSTANCE Ledger WITH log <- h
R == INSTANCE Running

Refines       == L!Spec
NoNewBehavior == R!Spec

(***************************************************************************)
(* And a mapping that computes, is not frozen, tracks nothing, and passes. *)
(*                                                                         *)
(* `AllOnes` is the sequence of `num` ones.  It grows on every Take, so    *)
(* the frozen-mapping probe is satisfied.  And it passes the refinement    *)
(* check, because appending a 1 is a legal Ledger step whatever the        *)
(* implementation actually took -- 1 is in Vals.                           *)
(*                                                                         *)
(* So the probe rules out the degenerate mapping.  It does not rule out a  *)
(* mapping that moves for reasons of its own.                              *)
(***************************************************************************)
AllOnes == [i \in 1..num |-> 1]

LAllOnes == INSTANCE Ledger WITH log <- AllOnes

RefinesAllOnes == LAllOnes!Spec

NotFrozenAllOnes == AllOnes = << >>

Alias == [ num |-> num, sum |-> sum, h |-> h, log |-> AllOnes ]
=========================================================================
