--------------------------- MODULE LateProphMC ---------------------------
(***************************************************************************)
(* What happens when the thing you predict cannot happen, and the spec has *)
(* a liveness conjunct.                                                    *)
(*                                                                         *)
(* `p` now ranges over Vals plus one impossible outcome, Never.  Reveal    *)
(* only fires when the prediction is one Reveal could keep, so a behavior  *)
(* that predicted Never simply halts.                                      *)
(*                                                                         *)
(* Then conjoin weak fairness -- on the ORIGINAL action, over the ORIGINAL *)
(* variables, which is what a liveness property of the implementation      *)
(* looks like.  RevealAny stays enabled forever in a halted behavior, and  *)
(* never occurs, so weak fairness rules that behavior out.  A liveness     *)
(* conjunct has just forbidden an initial state.                           *)
(*                                                                         *)
(* The technical name is that SpecWF is not machine closed.  The example   *)
(* is the SendInt one from Lamport and Merz, Auxiliary Variables in TLA+,  *)
(* section 4.6, transplanted.                                              *)
(***************************************************************************)
CONSTANTS Vals, Nothing, Never

VARIABLES out, done, p
vars  == << out, done, p >>
ovars == << out, done >>

Init ==
  /\ out = Nothing
  /\ done = FALSE
  /\ p \in Vals \cup {Never}

Reveal ==
  /\ ~done
  /\ p \in Vals
  /\ out' = p
  /\ done' = TRUE
  /\ UNCHANGED p

Next == Reveal

\* The action the implementation is fair to: it says nothing about p.
RevealAny ==
  /\ ~done
  /\ \E v \in Vals : out' = v
  /\ done' = TRUE

Safety == Init /\ [][Next]_vars

SpecWF == Init /\ [][Next]_vars /\ WF_ovars(RevealAny)

Eventually == <>done

\* Is the impossible prediction reachable from Init and Next alone?
NeverNotPicked == p # Never
=========================================================================
