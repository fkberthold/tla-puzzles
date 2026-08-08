------------------------------- MODULE Abstract -------------------------------
(***************************************************************************)
(* An abstract spec whose OWN Spec formula carries a safety-shaped temporal *)
(* conjunct. That third conjunct is the whole fixture.                      *)
(*                                                                          *)
(* `Next` lets the level move both ways, so a concrete spec that goes down  *)
(* still satisfies the implied-action obligation. What forbids going down   *)
(* is `[](Hot => []Hot)`: once the level leaves 0, it stays away from 0.    *)
(* TLC refutes that with a finite prefix, so it reports a SAFETY violation  *)
(* and exits 12, not the 13 the implied-init and implied-action obligations *)
(* exit with (verdict.sh's row-13 note, bead tla-94n).                      *)
(*                                                                          *)
(* Splitting the two directions is deliberate. If `Next` forbade the        *)
(* downward step as well, a concrete spec that went down would break the    *)
(* implied action too, and the 13 from that channel would mask the 12 this  *)
(* fixture exists to produce. The conjunct has to be the only thing wrong.  *)
(*                                                                          *)
(* Sibling of `broken/Abstract.tla`, which is the same counter with the     *)
(* downward step and the conjunct both left out.                            *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

vars == << level >>

Hot == level > 0

Init == level = 0
Up   == level < 2 /\ level' = level + 1
Down == level > 0 /\ level' = level - 1
Next == Up \/ Down

Spec == Init /\ [][Next]_vars /\ [](Hot => []Hot)

===============================================================================
