--------------------- MODULE LivenessEvalFailure ---------------------
(***************************************************************************)
(* rc=77 fixture (EC.TLC_LIVE_FORMULA_TAUTOLOGY = 2253).                    *)
(*                                                                          *)
(* Taut quantifies over the EMPTY set, so it is vacuously TRUE and TLC      *)
(* refuses it rather than checking it:                                      *)
(*                                                                          *)
(*   Temporal formula is a tautology (its negation is unsatisfiable).       *)
(*                                                                          *)
(* The mechanism is in SpecProcessor: a config property that is a bounded   *)
(* quantifier gets a ContextEnumerator over its bound set, and an           *)
(* enumerator that is done before it yields anything raises 2253.           *)
(*                                                                          *)
(* This is the §5.3 vacuity hazard wearing a temporal hat, and it is the    *)
(* good case: TLC refuses LOUDLY. Compare DanglingKeyword.cfg, where a      *)
(* .cfg keyword with no operand makes TLC exit 0 having checked nothing --  *)
(* the same "nothing was actually checked" failure, silent instead.         *)
(*                                                                          *)
(* Do not "fix" the empty set. The empty bound is the fixture.              *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x' = (x + 1) % 3
Spec == Init /\ [][Next]_x

Taut == \A i \in {} : [](x >= i)

=============================================================================
