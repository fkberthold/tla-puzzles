-------------------------- MODULE NaiveErrorRule --------------------------
(* SUBMISSION 2: nothing but the sentence this whole problem is about.
   Erratum 5732's corrected section 8, and no other arm -- not even a type
   invariant, because a learner who has just worked out what the erratum
   fixes has no reason to add one and the point here is what the SENTENCE
   buys on its own.

   It is sound against the reference, so the matrix reaches the grading
   phase. Expect PROPERTY_TOO_WEAK, and the interesting number is how many of
   the five variants walk past it. *)
EXTENDS AcmeChallenge

Inv == errors > 0 => status \in {Processing, Invalid}
=============================================================================
