----------------------------- MODULE MoveBase -----------------------------
(***************************************************************************)
(* Shared declarations for the IMAP MOVE partial-failure spike.             *)
(*                                                                          *)
(* RFC 9051 section 6.4.8 states three normative clauses about a MOVE that  *)
(* fails partway through a set of messages.  This module declares the state  *)
(* they talk about and names each clause once, so the three server models    *)
(* that EXTEND it cannot drift apart on what is being checked.               *)
(*                                                                          *)
(* MODELLING THE APPLICATION, NOT THE MECHANISM.                             *)
(*                                                                          *)
(* A message here is a model value with a location and a flag.  It has no    *)
(* UID, no sequence number, no body, no internal date, and the server has    *)
(* no UIDNEXT and no response-code stream.  All of that is the mechanism of  *)
(* IMAP and none of it is the requirement.  The requirement is a claim about *)
(* which of two mailboxes each message is in, so that is the whole state.    *)
(*                                                                          *)
(* WHY `pending` IS A SET AND NOT AN INDEX.                                  *)
(*                                                                          *)
(* The content of this problem is the per-message granularity of the         *)
(* failure, and the RFC says nothing about what the server does with the     *)
(* rest of the set after one message fails.  A model that walks an index     *)
(* answers that silence with "it stops", and the reachable outcomes are      *)
(* then prefixes of the set.  A set-valued `pending` leaves the silence      *)
(* open: a failure lands on whichever message the behavior picks, and the    *)
(* rest may still be attempted.  The choice is recorded in REPORT.md under   *)
(* "Where the RFC is silent", and probe `NoMixedOutcome` is the evidence     *)
(* that the model really does admit the wider set.                           *)
(***************************************************************************)

CONSTANT Msg

\* SEEDED VARIANT: abort-loses-pending. WRONG ON PURPOSE.
\*
\* Abort answers a tagged NO and drops the source copy of everything it had
\* not got to. RFC 9051 section 6.4.8 closes the paragraph with "This is true
\* even if the server returns a tagged NO response to the command", so the
\* guarantee has to hold on this path too.
\*
\* This one mutates MoveBase rather than MoveAtomic, because Abort is shared
\* by all four servers. The variant therefore also supplies an unchanged
\* MoveAtomic, which the harness requires of every variant.

(***************************************************************************)
(* The two mailboxes are defined here rather than declared as constants, so *)
(* no .cfg can assign them.  Message identifiers ARE model values, and a    *)
(* model value compared against a string aborts TLC at rc=255.  Keeping the  *)
(* mailbox names inside the module means the two domains never meet in a     *)
(* comparison the configuration could get wrong.                             *)
(***************************************************************************)
Source  == "src"
Target  == "tgt"
Mailbox == {Source, Target}

Replies == {"open", "ok", "no"}

VARIABLES
    loc,        \* loc[m] is the set of mailboxes holding message m
    flagged,    \* flagged[m] is the \Deleted flag on m's source copy
    pending,    \* the messages the server has not yet finished with
    resp        \* the tagged response to the MOVE command

vars == << loc, flagged, pending, resp >>

TypeOK == /\ loc \in [Msg -> SUBSET Mailbox]
          /\ flagged \in [Msg -> BOOLEAN]
          /\ pending \subseteq Msg
          /\ resp \in Replies

(***************************************************************************)
(* THE THREE CLAUSES, one per sentence of the RFC paragraph.                 *)
(*                                                                          *)
(* They get three names rather than one conjunction because a named          *)
(* obligation is a label in TLC's failure report.  Merging two throws the    *)
(* label away, and the whole interest here is which clause a given server    *)
(* breaks.  See .claude/rules/tla-practice.md section 1.                     *)
(*                                                                          *)
(* `Unaffected` carries the flag as well as the location.  A message still   *)
(* sitting in the source mailbox with \Deleted set is in exactly one         *)
(* mailbox and is not unaffected, and RFC 9051 section 6.4.8 says so         *)
(* directly: "the \Deleted flag MUST NOT be set for any message".  That one  *)
(* conjunct is what keeps clause 1 from collapsing into clauses 2 and 3.     *)
(* Probe `ClauseOneIsNoStronger` measures the difference.                    *)
(***************************************************************************)
Moved(m)      == loc[m] = {Target}
Unaffected(m) == loc[m] = {Source} /\ ~flagged[m]

\* Sentence 1. MUST in RFC 9051, SHOULD in RFC 6851. The word that changed.
MovedOrUnaffected == \A m \in Msg : Moved(m) \/ Unaffected(m)

\* Sentence 2. MUST in both. The safety floor.
NotLostOrOrphaned == \A m \in Msg : loc[m] # {}

\* Sentence 3. SHOULD NOT in both. The preference a conforming server may break.
NotInBothMailboxes == \A m \in Msg : ~(Source \in loc[m] /\ Target \in loc[m])

(***************************************************************************)
(* Every message starts in the source mailbox, unflagged, and the command   *)
(* has the whole set left to do.                                             *)
(***************************************************************************)
Init == /\ loc = [m \in Msg |-> {Source}]
        /\ flagged = [m \in Msg |-> FALSE]
        /\ pending = Msg
        /\ resp = "open"

(***************************************************************************)
(* The command answers once it has been through the set.                     *)
(***************************************************************************)
Reply(r) ==
    /\ resp = "open"
    /\ pending = {}
    /\ resp' = r
    /\ UNCHANGED << loc, flagged, pending >>

(***************************************************************************)
(* Or it gives up and answers NO with work left to do.  The last sentence of *)
(* the paragraph is about this branch: "This is true even if the server      *)
(* returns a tagged NO response to the command."  So the guarantee has to    *)
(* hold here too, and a client that reads NO as "nothing happened" is wrong. *)
(* Probe `NoMeansNothingHappened` is the evidence.                           *)
(***************************************************************************)
Abort ==
    /\ resp = "open"
    /\ pending # {}
    /\ pending' = {}
    /\ resp' = "no"
    /\ loc' = [m \in Msg |-> IF m \in pending THEN {} ELSE loc[m]]
    /\ UNCHANGED flagged

(***************************************************************************)
(* A normalising record for the seeded-bug matrix's trace dump.  It lives in *)
(* the spec because the oracle run and the graded run must normalise the     *)
(* same way or the comparison says nothing.                                  *)
(***************************************************************************)
Alias == [ inSource |-> {m \in Msg : Source \in loc[m]},
           inTarget |-> {m \in Msg : Target \in loc[m]},
           deleted  |-> {m \in Msg : flagged[m]},
           left     |-> pending,
           reply    |-> resp ]

===========================================================================
