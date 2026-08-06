----------------------------- MODULE Ledger -----------------------------
(***************************************************************************)
(* The abstract spec keeps every value it was ever handed.                 *)
(*                                                                         *)
(* Adapted from Lamport and Merz, Prophecy Made Simple, section 3.2 --     *)
(* their specification B, which keeps the whole input sequence in `seq`.   *)
(***************************************************************************)
EXTENDS Sequences, Naturals

CONSTANTS Vals, MaxInputs

VARIABLE log
vars == << log >>

Init == log = << >>

Record(v) ==
  /\ Len(log) < MaxInputs
  /\ log' = Append(log, v)

Next == \E v \in Vals : Record(v)

Spec == Init /\ [][Next]_vars
=========================================================================
