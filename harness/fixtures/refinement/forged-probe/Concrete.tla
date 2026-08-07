------------------------------- MODULE Concrete -------------------------------
(***************************************************************************)
(* A FORGED PROBE. The mapping is the frozen one from frozen/Concrete.tla,  *)
(* and the module then defines a `Probe` that is violated in the initial    *)
(* state.                                                                    *)
(*                                                                          *)
(* A harness that took the submission's word for what the probe is would    *)
(* see rc=12 -- probe violated, mapping moves, PASS -- on a mapping that is *)
(* nailed to the floor. This is the same class of hole as the frozen        *)
(* mapping itself, one level up: the subject under evaluation weakening its *)
(* own grading. It is why V2-PLAN.md section 5.4 keeps the .cfg             *)
(* harness-owned, and why refinement.sh generates its own probe operator    *)
(* (HarnessProbe) and never names a module-supplied one.                    *)
(*                                                                          *)
(* Expected verdict: FROZEN_MAPPING, identical to frozen/. The forgery must *)
(* make no difference at all.                                               *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE ticks

vars == << ticks >>

Init == ticks = 0
Tick == ticks < 6 /\ ticks' = ticks + 1
Next == Tick

Spec == Init /\ [][Next]_vars

A == INSTANCE Abstract WITH level <- 0

Refines == A!Spec

(***************************************************************************)
(* THE FORGERY. It watches the CONCRETE variable instead of the mapped      *)
(* expression, so it is violated as soon as `ticks` moves -- which it does, *)
(* whatever the mapping is nailed to. Raw TLC gives rc=12 on it: mapping    *)
(* moves, PASS.                                                             *)
(*                                                                          *)
(* Note the forgery is not even dishonest-looking. Watching the concrete    *)
(* variable is a plausible misreading of "the mapped expression", which is  *)
(* why the harness cannot accept a module-supplied probe on trust and grade *)
(* the intent later.                                                        *)
(*                                                                          *)
(* A blunter forgery, `Probe == FALSE`, would NOT work: TLC rejects a       *)
(* constant-false invariant outright with "The invariant of Probe is equal  *)
(* to FALSE" at rc=151. Measured on the TLC 2026.03.04.183147 nightly and   *)
(* again on tla2tools v1.8.0 (TLC 2026.07.31.184830). The forgery has to be *)
(* state-dependent to get through, and this one is.                         *)
(***************************************************************************)
Probe == ticks = 0

===============================================================================
