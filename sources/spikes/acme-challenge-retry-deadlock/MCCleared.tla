----------------------------- MODULE MCCleared -----------------------------
(* Erratum 5732's corrected section 8, under the one extra assumption that
   makes it hold: a successful validation empties the error field. The RFC
   does not say that anywhere. Expect rc=0.

   Paired with MCClearedRetry, which is the proof that this rc=0 is not the
   wedge wearing a different invariant. *)
EXTENDS Challenge
=============================================================================
