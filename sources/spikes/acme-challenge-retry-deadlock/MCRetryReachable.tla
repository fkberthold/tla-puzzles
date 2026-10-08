-------------------------- MODULE MCRetryReachable --------------------------
(* The erratum's sentence against the prose-faithful model. Expect rc=12: a
   second validation query IS reachable once the give-up decision is its own
   action. The same invariant holds at rc=0 against Wedged.tla, and the pair
   is the whole finding. *)
EXTENDS Challenge
=============================================================================
