-------------------------- MODULE TxnRefObl --------------------------
(***************************************************************************)
(* The reference obligations for the `txn-epoch` degenerate-model package.  *)
(* Variable-free by construction.                                           *)
(*                                                                          *)
(* WHICH OF THE EIGHT REQUIREMENTS ARE HERE, AND WHY THE REST ARE NOT. The  *)
(* statement's task is to classify its eight claims rather than to satisfy  *)
(* them, and two of the eight are false of the office. A phi_i that the     *)
(* reference itself refutes would invert every Adequacy run, so only the    *)
(* claims the faithful office keeps are stated:                             *)
(*                                                                          *)
(*   requirement 5, the card never runs ahead       Req_card_never_ahead    *)
(*   requirement 3, the book never goes back        Step_book_never_back    *)
(*   requirement 4, an entry is one leaf            Step_entry_one_leaf     *)
(*                                                                          *)
(* Requirement 1 is false of the office, measured at rc 12 by the step 5    *)
(* reader and refutable from rule 8 against rule 4 with no model at all.    *)
(* Requirement 2 is a liveness claim and is false of the office as well.    *)
(* Requirements 6, 7 and 8 are left out to keep the package cheap, not      *)
(* because anything is wrong with them.                                      *)
(***************************************************************************)
EXTENDS Naturals

ObsLeaves    == 3
ObsStandings == {"clear", "open", "completed", "abandoned", "spent"}

ObsDomain == [standing:  ObsStandings,
              leaf:      1 .. ObsLeaves,
              card:      1 .. ObsLeaves,
              withdrawn: BOOLEAN]

(***************************************************************************)
(* PHI_1, requirement 5. The leaf on the card is the leaf the desk holds or *)
(* an earlier one. Chaos reaches a card that names a later leaf, so this is *)
(* the obligation that keeps the package standing.                          *)
(***************************************************************************)
Req_card_never_ahead(o) == o.card =< o.leaf

(***************************************************************************)
(* PHI_2, requirement 3, over a pair of successive observations.            *)
(***************************************************************************)
Step_book_never_back(o, p) == p.leaf >= o.leaf

(***************************************************************************)
(* PHI_3, requirement 4. An entry moves the authority on by exactly one.    *)
(***************************************************************************)
Step_entry_one_leaf(o, p) == p.leaf = o.leaf \/ p.leaf = o.leaf + 1

(***************************************************************************)
(* THE TWO LANDMARKS. A Step_* obliges the package to two that no single    *)
(* observation satisfies together, because a frozen observation satisfies   *)
(* every boxed action there is. These two disagree about `withdrawn`, so    *)
(* the disjointness run is settled by one field.                            *)
(*                                                                          *)
(* Landmark_recovered IS THE ONE THAT CATCHES THE DEGENERATE MODEL, and it  *)
(* is a reading only row 4 of rule 5 reaches. A withdrawal leaves the card  *)
(* one leaf behind the book and writes nothing on it, and no entry the gang *)
(* can bring will fire while the card disagrees. So the card catches up only *)
(* on a second copy, and a watch that has logged a withdrawal beside a card *)
(* that agrees with the book is the signature of the retry row having run.  *)
(***************************************************************************)
Landmark_recovered(o) == o.withdrawn /\ o.card = o.leaf

Landmark_opening(o) ==
  /\ o.standing = "clear"
  /\ o.card = o.leaf
  /\ ~o.withdrawn

=============================================================================
