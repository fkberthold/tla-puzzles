----------------------- MODULE AdmitsChaosRefObl -----------------------
(***************************************************************************)
(* Obligations for `chaos-probe/reference-admits-chaos`. Variable-free,     *)
(* like every obligations module.                                           *)
(*                                                                          *)
(* EVERY OBLIGATION HERE IS TRUE OF PURE CHAOS OVER ObsDomain, and that is  *)
(* the whole fixture. Req_capacity holds at every record in the domain, and *)
(* a chaos spec reaches every record in the domain, so it reaches the       *)
(* landmark as well. A box whose contents teleport from empty to full and   *)
(* back satisfies this set entire. A set of requirements that a teleporting *)
(* box satisfies is not a description of a box.                             *)
(*                                                                          *)
(* NOTHING ELSE IS WRONG WITH THE PACKAGE, and the fixture would not be     *)
(* worth much if there were. It parses, it grades, its landmark is          *)
(* reachable, and the submission beside it is correct and grades PASS       *)
(* against the two references that do refuse chaos. What this set cannot do *)
(* is tell a lockbox from chaos, so grade.sh refuses the package and names  *)
(* this module. The defect is the author's, and no verdict about a          *)
(* submission is printed for it.                                            *)
(*                                                                          *)
(* Beads tla-59s and tla-x8s.                                               *)
(***************************************************************************)
EXTENDS Naturals

(***************************************************************************)
(* THE DECLARED OBSERVATION DOMAIN: the records the observation may take.   *)
(*                                                                          *)
(* The chaos probe ranges over this, and the requirements below carve it.   *)
(* Without a declared domain there is nothing for a probe to range over. An *)
(* obligations module is variable-free by construction, so it carries no    *)
(* state space of its own and no domain to quantify a record over.          *)
(***************************************************************************)
ObsDomain == [level: 0..3, full: BOOLEAN]

(***************************************************************************)
(* PHI_1 -- the box holds between zero and three parcels. True at every     *)
(* record in ObsDomain, so no spec that observes into ObsDomain can break   *)
(* it.                                                                      *)
(***************************************************************************)
Req_capacity(o) == o.level \in 0..3

(***************************************************************************)
(* LANDMARK -- an observation the reference reaches. Chaos reaches every    *)
(* record in the domain, so chaos reaches this one too.                     *)
(***************************************************************************)
Landmark_full(o) == o.full

=============================================================================
