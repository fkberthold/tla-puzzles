------------------------- MODULE RolloutRef -------------------------
(***************************************************************************)
(* A STAND-IN reference for `progressive-sync-stale-status`, built for bead *)
(* tla-8kgj. The problem is at step 5 and its reference is frozen at step   *)
(* 6, so this is not the shipped reference. It carries the statement's      *)
(* frozen five-field Observe interface and the region of                    *)
(* sources/spikes/progressive-sync-stale-status/.                            *)
(*                                                                          *)
(* RULE 4 IS RENDERED AS AMENDED, which is the statement as it stands on    *)
(* main. Commit e8348c9 closed the hole the step 5 report called blocking:  *)
(* a box leaves `under issue` one way only, and that way is her reading the *)
(* box's line on the board and closing the issue off. Before that the box   *)
(* dropped out of `underIssue` by pasting, which handed her a completion    *)
(* signal that could not go stale and made the board optional.              *)
(*                                                                          *)
(* SO THE BOARD IS LOAD-BEARING HERE, and the two steps that make it so are *)
(* Visit and CloseOff. The clerk's round is his own, nothing waits on him,  *)
(* and between his visits a line stands as last written however the box has *)
(* moved since. That gap is the whole subject of the problem.                *)
(*                                                                          *)
(* `board` and `issued` are hers and are not fields of Observe. The         *)
(* statement says the board is not a field on purpose, and its shape is     *)
(* this module's own choice rather than anything a submission has to match. *)
(***************************************************************************)
EXTENDS Naturals, Sequences

Boxes     == {"b1", "b2"}
Districts == <<{"b1"}, {"b2"}>>
Last      == Len(Districts)

VARIABLES amendment, working, inHand, underIssue, signedOff, issued, board

vars == <<amendment, working, inHand, underIssue, signedOff, issued, board>>

(***************************************************************************)
(* Rule 8. Every box works to the standing edition, nothing is issued, and  *)
(* the board agrees with every box because the clerk has been round since   *)
(* the last thing that changed.                                             *)
(***************************************************************************)
Init ==
  /\ amendment  = 0
  /\ working    = [b \in Boxes |-> 0]
  /\ inHand     = 0
  /\ underIssue = {}
  /\ signedOff  = {}
  /\ issued     = {}
  /\ board      = [b \in Boxes |-> 0]

(***************************************************************************)
(* Rule 2. Head office issues the amendment once, and nothing follows it.   *)
(***************************************************************************)
IssueAmendment ==
  /\ amendment = 0
  /\ amendment' = 1
  /\ UNCHANGED <<working, inHand, underIssue, signedOff, issued, board>>

OpenCirculation ==
  /\ amendment # 0
  /\ inHand = 0
  /\ inHand' = 1
  /\ UNCHANGED <<amendment, working, underIssue, signedOff, issued, board>>

(***************************************************************************)
(* Rule 4, first paragraph. One box at a time, of the district in hand, and *)
(* only a box she hasn't got out already.                                   *)
(***************************************************************************)
Issue(b) ==
  /\ inHand \in 1 .. Last
  /\ b \in Districts[inHand]
  /\ b \notin issued
  /\ underIssue' = underIssue \cup {b}
  /\ issued' = issued \cup {b}
  /\ UNCHANGED <<amendment, working, inHand, signedOff, board>>

(***************************************************************************)
(* Rule 4, second paragraph. The paste is the box's step and she does not    *)
(* see it happen, so `underIssue` does not move here. That one UNCHANGED is *)
(* the amendment, and it is what the degenerate model takes back out.       *)
(***************************************************************************)
Paste(b) ==
  /\ b \in underIssue
  /\ working[b] # amendment
  /\ working' = [working EXCEPT ![b] = amendment]
  /\ UNCHANGED <<amendment, inHand, underIssue, signedOff, issued, board>>

(***************************************************************************)
(* Rule 6. The clerk's round. He takes boxes in whatever order he likes and  *)
(* no step of hers makes him move, so this action carries no guard at all.   *)
(***************************************************************************)
Visit(b) ==
  /\ board' = [board EXCEPT ![b] = working[b]]
  /\ UNCHANGED <<amendment, working, inHand, underIssue, signedOff, issued>>

(***************************************************************************)
(* Rule 4, third paragraph. Her step, on board evidence and nothing else.   *)
(***************************************************************************)
CloseOff(b) ==
  /\ b \in underIssue
  /\ board[b] = amendment
  /\ underIssue' = underIssue \ {b}
  /\ UNCHANGED <<amendment, working, inHand, signedOff, issued, board>>

(***************************************************************************)
(* Rule 7. A sign-off puts the next district in hand, and signing off the   *)
(* last district ends the circulation.                                      *)
(***************************************************************************)
SignOff ==
  /\ inHand \in 1 .. Last
  /\ Districts[inHand] \subseteq issued
  /\ underIssue \cap Districts[inHand] = {}
  /\ signedOff' = signedOff \cup {inHand}
  /\ inHand' = inHand + 1
  /\ UNCHANGED <<amendment, working, underIssue, issued, board>>

Next ==
  \/ IssueAmendment
  \/ OpenCirculation
  \/ \E b \in Boxes : Issue(b) \/ Paste(b) \/ Visit(b) \/ CloseOff(b)
  \/ SignOff

Spec == Init /\ [][Next]_vars

Observe == [amendment  |-> amendment,
            working    |-> working,
            inHand     |-> inHand,
            underIssue |-> underIssue,
            signedOff  |-> signedOff]

=============================================================================
