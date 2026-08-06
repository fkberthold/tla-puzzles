---------------------------- MODULE LateProph ----------------------------
(***************************************************************************)
(* Late, with a prophecy variable `p`.                                     *)
(*                                                                         *)
(* The recipe is Lamport and Merz, Prophecy Made Simple, section 4.2.      *)
(* Reveal is `\E v \in Vals : out' = v`, which is a disjunction of one      *)
(* elementary action per value, so their index set P is Vals:              *)
(*                                                                         *)
(*   1. Conjoin p \in P to Init.                                           *)
(*   2. Replace each action A_i by (p = i) /\ (p' \in P) /\ A_i.  Here      *)
(*      that collapses to out' = p, and since only one prediction is ever  *)
(*      needed, p' \in P specializes to p' = p.                            *)
(*   3. Every OTHER elementary action gets p' = p.  There are none.        *)
(*                                                                         *)
(* Step 2 constrains the action.  That is why prophecy has to earn what a  *)
(* history variable gets for free: you must check that the constraint      *)
(* removes no behavior of the original variables.  NoNewBehavior below is  *)
(* the half TLC can check; the other half is the argument that p ranges    *)
(* over exactly the outcomes Reveal could have produced.                   *)
(***************************************************************************)
CONSTANTS Vals, Nothing

VARIABLES out, done, p
vars  == << out, done, p >>
ovars == << out, done >>

Init ==
  /\ out = Nothing
  /\ done = FALSE
  /\ p \in Vals              \* 1. predict

Reveal ==
  /\ ~done
  /\ out' = p                \* 2. keep the promise
  /\ done' = TRUE
  /\ UNCHANGED p             \*    and p' \in P, specialized

Next == Reveal

Spec == Init /\ [][Next]_vars

O == INSTANCE Oracle WITH pick <- p
L == INSTANCE Late

Refines       == O!Spec
NoNewBehavior == L!Spec
=========================================================================
