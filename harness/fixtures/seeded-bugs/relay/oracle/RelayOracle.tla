---------------------------- MODULE RelayOracle -----------------------------
(***************************************************************************)
(* THE AUTHOR'S OWN TEMPORAL PROPERTY -- the liveness matrix's instrument.  *)
(*                                                                          *)
(* `[]<>(stage = 2)` is a recurrence property.  It cannot be refuted by any *)
(* finite prefix, so TLC checks it through the liveness channel and exits   *)
(* 13 rather than 12 when it fails -- harness/verdict.sh's table, the right *)
(* column.  That is the whole reason this fixture exists: a matrix whose    *)
(* refutation code is 12 cannot grade it.                                   *)
(*                                                                          *)
(* `.claude/rules/tla-practice.md` §3 is why this is not called `Inv`.      *)
(* A `*Inv` name tells a reader the obligation is a state predicate, and    *)
(* this one is not.  seeded-bugs.sh takes the operator name from            *)
(* --property, so the honest name costs nothing but the flag.               *)
(***************************************************************************)
EXTENDS Relay

Live == []<>(stage = 2)

=============================================================================
