-------------------------- MODULE ProbeStoreFirst --------------------------
(***************************************************************************)
(* THE PROBE THAT ASKS WHETHER CLAUSE 1 IS THREE NAMES FOR TWO THINGS.      *)
(*                                                                          *)
(* Clause 1 implies clauses 2 and 3 as a matter of arithmetic over the       *)
(* location set: "moved or unaffected" means loc[m] is exactly {tgt} or      *)
(* exactly {src}, which rules out the empty set that clause 2 rules out and  *)
(* the full set that clause 3 rules out. So clause 1 can never fail while    *)
(* either of the others holds, unless "unaffected" carries something the     *)
(* location does not.                                                        *)
(*                                                                          *)
(* It does: the \Deleted flag. The question is whether a state that uses it  *)
(* is reachable, and that is a fact about the server rather than about the   *)
(* clause.                                                                   *)
(*                                                                          *)
(* Refuted means some reachable state has clauses 2 and 3 holding while      *)
(* clause 1 fails, so clause 1 is strictly stronger than their conjunction   *)
(* and earns its own name. rc 0 would mean the three names cover two things  *)
(* in this model, which is the redundancy shape                             *)
(* .claude/rules/tla-practice.md section 4 found in 3 configs out of 899.    *)
(***************************************************************************)
EXTENDS MoveStoreFirst

ClauseOneIsNoStronger ==
    (NotLostOrOrphaned /\ NotInBothMailboxes) => MovedOrUnaffected

(***************************************************************************)
(* THE OTHER DIRECTION, and the two I expect to HOLD.                       *)
(*                                                                          *)
(* These carry the normative consequence of the word that changed between   *)
(* RFC 6851 and RFC 9051. Clause 1 is a MUST in 9051 and was a SHOULD in    *)
(* 6851, and clause 3 is a SHOULD NOT in both. If clause 1 implies clause 3, *)
(* then a server that satisfies the 9051 MUST cannot leave a duplicate, and  *)
(* the SHOULD NOT has nothing left to permit. The paragraph then requires at  *)
(* MUST what it separately says only SHOULD NOT happen.                      *)
(*                                                                          *)
(* That is a claim about the clause set rather than about any server, so it  *)
(* holds or fails by arithmetic over the location set. Checking it here      *)
(* measures it instead of asserting it, over a server that reaches both the  *)
(* both-mailboxes shape and the flagged-one-mailbox shape.                   *)
(***************************************************************************)
ClauseOneImpliesNotBoth == MovedOrUnaffected => NotInBothMailboxes
ClauseOneImpliesNotLost == MovedOrUnaffected => NotLostOrOrphaned

===========================================================================
