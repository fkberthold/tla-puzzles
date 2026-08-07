------------------------- MODULE AssertInInit -------------------------
(***************************************************************************)
(* rc=75 fixture, second route (EC.TLC_NESTED_EXPRESSION = 2103).            *)
(*                                                                          *)
(* The twin of AssertViolation.tla, and the pair is the point. The SAME     *)
(* construct -- Assert with a FALSE first argument -- exits 14 when it      *)
(* fires during behaviour exploration and 75 when it fires while TLC is     *)
(* computing initial states, because the initial-state computation wraps    *)
(* the EvalException as a nested-expression failure instead of letting the  *)
(* assertion's own error code through.                                      *)
(*                                                                          *)
(* So rc=14 does not mean "an Assert failed". It means "an Assert failed    *)
(* AFTER the spec was already evaluating behaviour". Anyone reading the     *)
(* exit-code table as a map from language construct to code will get this   *)
(* wrong, which is why both halves are pinned rather than one.              *)
(*                                                                          *)
(* Corollary for rc=75: it is a FAMILY, not a condition. This fixture and   *)
(* SpecEvalFailure.tla reach it through entirely different defects (2103 vs *)
(* 2109), and EC routes 2115 and 2147 there as well.                        *)
(***************************************************************************)
EXTENDS Naturals, TLC

VARIABLE x

Init == /\ Assert(FALSE, "assert failed while computing initial states")
        /\ x = 0
Next == x' = (x + 1) % 3
Spec == Init /\ [][Next]_x

TypeOK == x \in 0..2

=============================================================================
