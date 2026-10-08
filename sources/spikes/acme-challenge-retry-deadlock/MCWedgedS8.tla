----------------------------- MODULE MCWedgedS8 -----------------------------
(* Section 8 as published, against the model that enforces it in the
   transition relation. Expect rc=0. This is the half of the finding that is
   easy to miss: the wedged reading is not INCONSISTENT, it is CONSISTENT and
   useless. Nothing a safety check can say about it is wrong. *)
EXTENDS Wedged
=============================================================================
