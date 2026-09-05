------------------------- MODULE LadderRefObl -------------------------
(***************************************************************************)
(* The reference obligations for `strength-order`. Bead tla-nyrb, clause    *)
(* C2.                                                                      *)
(*                                                                          *)
(* Req_unanimity is the answer key. The two submissions beside this package *)
(* state their own requirement, one of them this rule and one of them a     *)
(* strict weakening of it, and today both come back with the same result.   *)
(***************************************************************************)
EXTENDS Naturals

ObsDomain == [issued: BOOLEAN, sealed: BOOLEAN, approvals: 0..3]

(***************************************************************************)
(* PHI_1. A document is issued only with all three approvals.              *)
(***************************************************************************)
Req_unanimity(o) == o.issued => o.approvals = 3

(***************************************************************************)
(* PHI_2. The seal agrees with the document. It is the obligation that      *)
(* refuses chaos over the domain above, so the package stands on its own    *)
(* account under the tla-x8s probe. It plays no part in the strength        *)
(* question and every submission here meets it.                             *)
(***************************************************************************)
Req_sealflag(o) == o.sealed <=> o.issued

(***************************************************************************)
(* LANDMARK. The reference reaches an issued document, so a submission has  *)
(* to reach one too.                                                        *)
(***************************************************************************)
Landmark_issued(o) == o.issued

=============================================================================
