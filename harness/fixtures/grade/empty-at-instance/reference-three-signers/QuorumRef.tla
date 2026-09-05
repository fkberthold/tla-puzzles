--------------------------- MODULE QuorumRef ---------------------------
(***************************************************************************)
(* The reference spec PHI for the `empty-at-instance` fixture, bead         *)
(* tla-nyrb.                                                                *)
(*                                                                          *)
(* THE SYSTEM: a document that three named signers can approve. Anyone may  *)
(* approve at any time, approving twice changes nothing, and the document   *)
(* is issued only once everybody has approved.                              *)
(*                                                                          *)
(* THE SPEC ITSELF CARRIES NO TRICK, and it declares no CONSTANT. The       *)
(* fixture lives in the obligations module beside it and in the             *)
(* constants.cfg beside that. Keeping the constant out of here is not       *)
(* tidiness either. No run site in grade.sh EXTENDS the reference spec and  *)
(* the reference obligations module together today, but the                 *)
(* landmark-disjointness run would if this package ever stated a Step_*,    *)
(* and two modules that both declare the same CONSTANT make it ambiguous.   *)
(* SANY warns and TLC then reports the identifier as undefined.             *)
(***************************************************************************)

VARIABLES issued, approvedBy

Names == {"a", "b", "c"}

Init == issued = FALSE /\ approvedBy = {}

Approve(s) == approvedBy' = approvedBy \cup {s} /\ UNCHANGED issued
Issue      == approvedBy = Names /\ issued' = TRUE /\ UNCHANGED approvedBy

Next == (\E s \in Names : Approve(s)) \/ Issue

Spec == Init /\ [][Next]_<<issued, approvedBy>>

(***************************************************************************)
(* The observation. `sealed` is derived from `issued` and says nothing that *)
(* `issued` does not, which is what makes it useful. It is the second field *)
(* that QuorumRefObl!Req_sealflag relates, and relating two fields is how   *)
(* this package refuses chaos over its own domain. Same job as the `full`   *)
(* flag in `lockbox`, same reason, bead tla-x8s.                            *)
(***************************************************************************)
Observe == [issued |-> issued, sealed |-> issued, approvedBy |-> approvedBy]

=============================================================================
