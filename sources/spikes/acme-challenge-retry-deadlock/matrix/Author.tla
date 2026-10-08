------------------------------ MODULE Author ------------------------------
(* SUBMISSION 1: the author's full property, written out separately from
   Oracle.tla rather than EXTENDS-ing it, so that the graded artefact and the
   instrument are two files and a drift between them would show. Expect
   BUGS_CAUGHT. *)
EXTENDS AcmeChallenge

Inv ==
    /\ status \in Status
    /\ errors \in 0..MaxQueries
    /\ queries \in 0..MaxQueries
    /\ gaveUp \in BOOLEAN
    /\ clientRequest \in BOOLEAN
    /\ (errors > 0 => status \in {Processing, Invalid})
    /\ errors <= queries
    /\ (status = Pending => (queries = 0 /\ errors = 0))
    /\ (gaveUp => status = Invalid)
    /\ (status = Invalid => errors > 0)
    /\ (status = Processing => errors = queries)
=============================================================================
