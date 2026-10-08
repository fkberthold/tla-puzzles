---------------------- MODULE RolloutBoardless ----------------------
(***************************************************************************)
(* THE DEGENERATE MODEL for `progressive-sync-stale-status`: a region with  *)
(* no board and no clerk in it. A box under issue pastes the amendment in   *)
(* and leaves `underIssue` in the same step, so her sign-off guard reads her *)
(* own records and never consults a board at all.                           *)
(*                                                                          *)
(* The step 5 reader measured this against the statement's own seven        *)
(* requirements and got rc 0 over 14 distinct states at depth 11, and the   *)
(* statement's declared completion check passes too. So a learner could     *)
(* pass both of the statement's checks over a region in which the stale     *)
(* board, which is the whole subject of argo-cd issue #29410, cannot occur.  *)
(*                                                                          *)
(* Rule 4 was amended on main after that measurement, and this module is    *)
(* the reading the amendment forbids. It is kept as a fixture rather than   *)
(* retired, because the requirement set still cannot see it. Only the       *)
(* landmark can.                                                            *)
(***************************************************************************)
EXTENDS Naturals, Sequences

Boxes     == {"b1", "b2"}
Districts == <<{"b1"}, {"b2"}>>
Last      == Len(Districts)

VARIABLES amendment, working, inHand, underIssue, signedOff, issued

vars == <<amendment, working, inHand, underIssue, signedOff, issued>>

Init ==
  /\ amendment  = 0
  /\ working    = [b \in Boxes |-> 0]
  /\ inHand     = 0
  /\ underIssue = {}
  /\ signedOff  = {}
  /\ issued     = {}

IssueAmendment ==
  /\ amendment = 0
  /\ amendment' = 1
  /\ UNCHANGED <<working, inHand, underIssue, signedOff, issued>>

OpenCirculation ==
  /\ amendment # 0
  /\ inHand = 0
  /\ inHand' = 1
  /\ UNCHANGED <<amendment, working, underIssue, signedOff, issued>>

Issue(b) ==
  /\ inHand \in 1 .. Last
  /\ b \in Districts[inHand]
  /\ b \notin issued
  /\ underIssue' = underIssue \cup {b}
  /\ issued' = issued \cup {b}
  /\ UNCHANGED <<amendment, working, inHand, signedOff>>

(***************************************************************************)
(* The collapse. The paste and the close-off are one step, which hands her  *)
(* a completion signal that cannot go stale.                                *)
(***************************************************************************)
Paste(b) ==
  /\ b \in underIssue
  /\ working[b] # amendment
  /\ working' = [working EXCEPT ![b] = amendment]
  /\ underIssue' = underIssue \ {b}
  /\ UNCHANGED <<amendment, inHand, signedOff, issued>>

SignOff ==
  /\ inHand \in 1 .. Last
  /\ Districts[inHand] \subseteq issued
  /\ underIssue \cap Districts[inHand] = {}
  /\ signedOff' = signedOff \cup {inHand}
  /\ inHand' = inHand + 1
  /\ UNCHANGED <<amendment, working, underIssue, issued>>

Next ==
  \/ IssueAmendment
  \/ OpenCirculation
  \/ \E b \in Boxes : Issue(b) \/ Paste(b)
  \/ SignOff

Spec == Init /\ [][Next]_vars

Observe == [amendment  |-> amendment,
            working    |-> working,
            inHand     |-> inHand,
            underIssue |-> underIssue,
            signedOff  |-> signedOff]

=============================================================================
