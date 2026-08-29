----------------------------- MODULE Paired -----------------------------
(***************************************************************************)
(* The honest submission for the `chaos-probe` package, and ONE submission  *)
(* serves all three references beside it.                                   *)
(*                                                                          *)
(* That is what makes the two directions readable. The same correct spec is *)
(* graded against three obligation sets over the same system. One of them   *)
(* cannot tell this box from a spec with no transitions at all, and its     *)
(* package is refused. The other two can, and they grade this submission    *)
(* PASS. So the refusal is a fact about the reference, and holding the      *)
(* submission fixed is what shows that.                                     *)
(*                                                                          *)
(* The observation carries a `full` flag beside the level. It is derived    *)
(* rather than stored, so it says nothing the level does not, and the       *)
(* reference that states no Step_* needs it. A requirement relating two     *)
(* fields is a requirement that chaos over the record type can break.       *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Fill  == level < 3 /\ level' = level + 1
Empty == level > 0 /\ level' = level - 1

Next == Fill \/ Empty

Spec == Init /\ [][Next]_level

(***************************************************************************)
(* The observation operator. Grading keys off this and never off `level`.   *)
(***************************************************************************)
Observe == [level |-> level, full |-> (level = 3)]

=============================================================================
