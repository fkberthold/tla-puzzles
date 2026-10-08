------------------------------- MODULE Relay --------------------------------
(***************************************************************************)
(* THE REFERENCE SPEC for the matrix's LIVENESS pair (bead tla-r2ih).      *)
(*                                                                          *)
(* crossing/ is the safety pair: its obligation is a state predicate, its   *)
(* refutations are rc=12, and every row built on it passes on a script      *)
(* that writes `INVARIANT` unconditionally.  That is why the INVARIANT bug  *)
(* survived to be found in the field rather than here.  This matrix is the  *)
(* row crossing/ cannot be: its obligation is a TEMPORAL formula, so a      *)
(* script that writes the wrong keyword over it cannot report a verdict at  *)
(* all.                                                                     *)
(*                                                                          *)
(* A relay that cycles 0 -> 1 -> 2 -> 0.  Three states, one cycle, and      *)
(* EVERY state has a successor.  Both of those are deliberate:              *)
(*                                                                          *)
(*   Three states, because the matrix runs 2 x (1 + N) TLC invocations and   *)
(*   every one of them has to be cheap.                                     *)
(*                                                                          *)
(*   No terminal state, because seeded-bugs.sh generates its own .cfg and   *)
(*   writes no CHECK_DEADLOCK line, so deadlock checking is ON.  A liveness  *)
(*   fixture that could stop would exit 11 before TLC ever looked at the     *)
(*   temporal formula, and the matrix would pass that through as DEADLOCK.   *)
(*   Every seeded variant below keeps that property for the same reason.     *)
(*                                                                          *)
(* This module defines no obligation.  The obligation is what the learner    *)
(* supplies; see ../oracle/RelayOracle.tla for the author's own.             *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES stage

vars == << stage >>

Stages == 0 .. 2

Init == stage = 0

Advance == stage < 2 /\ stage' = stage + 1
Recycle == stage = 2 /\ stage' = 0

Next == Advance \/ Recycle

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* THE FAIRNESS CONJUNCT, AND WHY THE MATRIX IS DRIVEN AGAINST THIS ONE.    *)
(*                                                                          *)
(* `Spec` alone admits the behaviour that takes one step and then stutters   *)
(* for ever.  That behaviour violates every liveness property any learner   *)
(* could write, including the correct one, so against `Spec` the matrix's    *)
(* PHASE 1 would report the author's own oracle as unsound and grade         *)
(* nothing.  Against `FairSpec` the stuttering behaviour is excluded and a   *)
(* refutation is about the relay rather than about the trace's tail.         *)
(*                                                                          *)
(* `.claude/rules/tla-practice.md` §2 is the reason the subscript is the     *)
(* whole `vars` tuple rather than `stage` alone: 98% of the WF_/SF_ sites in *)
(* the 666-module corpus subscript over every variable, and there is no      *)
(* reason here to be one of the 2%.                                          *)
(*                                                                          *)
(* seeded-bugs.sh reads this definition.  A temporal obligation refuted      *)
(* against a spec operator carrying no WF_/SF_ conjunct is refused rather    *)
(* than counted as a catch -- the counterexample would be the stuttering     *)
(* tail, not the bug.                                                        *)
(***************************************************************************)
FairSpec == Spec /\ WF_vars(Next)

(***************************************************************************)
(* NORMALISATION FOR THE TRACE DUMP, as in crossing/Crossing.tla: the alias *)
(* is the SPEC's, never the submission's, because the oracle run and the    *)
(* submission run have to normalise identically for the counterexample      *)
(* comparison to mean anything.                                             *)
(***************************************************************************)
Alias == [ position |-> stage ]

=============================================================================
