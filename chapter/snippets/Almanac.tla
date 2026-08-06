---------------------------- MODULE Almanac ----------------------------
(***************************************************************************)
(* The abstract observatory.  An observatory takes proposals and turns     *)
(* them into archived datasets.  That is all it does.                      *)
(*                                                                         *)
(* Companion to the refinement chapter, worked example.                    *)
(***************************************************************************)
CONSTANT Proposals

VARIABLE logged
vars == << logged >>

Init == logged = {}

Record(p) ==
  /\ p \notin logged
  /\ logged' = logged \cup {p}

Next == \E p \in Proposals : Record(p)

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* Two facts about the archive, proved once, here, of a two-line spec.     *)
(***************************************************************************)
AppendOnly == [][logged \subseteq logged']_vars

NoDuplicates == [][\A p \in Proposals : p \in logged => p \in logged']_vars
========================================================================
