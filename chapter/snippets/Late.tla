------------------------------ MODULE Late ------------------------------
(***************************************************************************)
(* The implementation decides at the last moment.  Same visible behavior:  *)
(* out ends up holding some value of Vals and done ends up TRUE.           *)
(*                                                                         *)
(* There is no expression over `out` and `done` that can serve as Oracle's *)
(* `pick`, because in the initial state the value has not been chosen yet  *)
(* and nothing in the state says which one it will be.  The obvious try is *)
(* below, and it fails on the initial predicate.                           *)
(***************************************************************************)
CONSTANTS Vals, Nothing

VARIABLES out, done
vars == << out, done >>

Init ==
  /\ out = Nothing
  /\ done = FALSE

Reveal ==
  /\ ~done
  /\ \E v \in Vals : out' = v
  /\ done' = TRUE

Next == Reveal

Spec == Init /\ [][Next]_vars

O == INSTANCE Oracle WITH pick <- out

RefinesNaive == O!Spec

Alias == [ out |-> out, done |-> done, pick |-> out ]
=========================================================================
