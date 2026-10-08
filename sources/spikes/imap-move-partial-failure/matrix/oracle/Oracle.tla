------------------------------- MODULE Oracle -------------------------------
(***************************************************************************)
(* THE AUTHOR'S OWN PROPERTY, which is the matrix's instrument and not a    *)
(* submission. It must exit 0 against the reference and 12 against every    *)
(* variant, and seeded-bugs.sh checks both before it grades anything.       *)
(*                                                                          *)
(* All four names come from MoveBase. The three normative clauses are the    *)
(* sentences of RFC 9051 section 6.4.8, and TypeOK is the type layer.        *)
(***************************************************************************)
EXTENDS MoveAtomic

Inv == /\ TypeOK
       /\ MovedOrUnaffected
       /\ NotLostOrOrphaned
       /\ NotInBothMailboxes

=============================================================================
