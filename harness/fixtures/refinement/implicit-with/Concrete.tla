------------------------------- MODULE Concrete -------------------------------
(***************************************************************************)
(* OMITTING `WITH` IS SILENT (V2-PLAN.md section 5.4).                      *)
(*                                                                          *)
(* `A == INSTANCE Abstract` with no WITH clause is legal TLA+. Every        *)
(* abstract variable is substituted by the same-named expression in this    *)
(* module, so the mapping here is silently `level <- level`. TLC never says *)
(* a word about it.                                                          *)
(*                                                                          *)
(* Here the implicit mapping happens to be sound and the check passes at    *)
(* rc=0, which is precisely what makes it dangerous: a submission gets a    *)
(* green result for a mapping it never stated, and the next problem -- the  *)
(* one where the same-named variables mean different things -- gets the     *)
(* same green result for a mapping that is wrong.                            *)
(*                                                                          *)
(* refinement.sh refuses the shape rather than judging the mapping. State   *)
(* the mapping, even when it is the identity: `WITH level <- level`.        *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

vars == << level >>

Init == level = 0
Up   == level < 2 /\ level' = level + 1
Next == Up

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* No WITH. The mapping is whatever same-name substitution happens to give. *)
(***************************************************************************)
A == INSTANCE Abstract

Refines == A!Spec

===============================================================================
