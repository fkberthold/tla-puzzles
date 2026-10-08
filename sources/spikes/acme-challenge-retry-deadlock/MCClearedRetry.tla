--------------------------- MODULE MCClearedRetry ---------------------------
(* The vacuity guard on MCCleared. Erratum 5732's own sentence, asserted
   against the model where its correction holds. Expect rc=12: a second
   validation query is reachable, so the invariant in MCCleared is satisfied
   by a model that does retry rather than by one that cannot. *)
EXTENDS Challenge
=============================================================================
