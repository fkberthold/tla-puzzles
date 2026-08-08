----------------------- MODULE SmuggledRefObl -----------------------
(***************************************************************************)
(* Obligations for `smuggled-constants`. Variable-free, as every            *)
(* obligations module is.                                                   *)
(***************************************************************************)
EXTENDS Naturals

Req_capacity(o) == o.level =< 3

Landmark_full(o) == o.level = 3

=============================================================================
