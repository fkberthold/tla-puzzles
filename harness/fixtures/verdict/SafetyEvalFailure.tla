---------------------- MODULE SafetyEvalFailure ----------------------
(***************************************************************************)
(* rc=76 fixture (EC.TLC_INVARIANT_EVALUATION_FAILED = 2111).               *)
(*                                                                          *)
(* f is a function on {0, 1}. The invariant applies it to x, and x reaches  *)
(* 2, so f[x] is undefined and the INVARIANT ITSELF blows up:               *)
(*                                                                          *)
(*   Evaluating invariant Inv failed.                                       *)
(*                                                                          *)
(* rc=76 is NOT rc=12. rc=12 means the invariant was evaluated and came     *)
(* out FALSE -- there is a counterexample, and the spec is fine. rc=76      *)
(* means the invariant could not be evaluated at all, so nothing is known   *)
(* about whether it holds. Reporting a 76 as SAFETY_VIOLATION would tell a  *)
(* learner their spec violates an invariant that was never actually         *)
(* checked.                                                                 *)
(*                                                                          *)
(* The reachable states are 0, 1, 2 and the invariant survives 0 and 1, so  *)
(* the failure is genuinely mid-run rather than at the initial state.       *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE x

Init == x = 0
Next == x' = (x + 1) % 3
Spec == Init /\ [][Next]_x

f == [i \in {0, 1} |-> i]

Inv == f[x] >= 0

=============================================================================
