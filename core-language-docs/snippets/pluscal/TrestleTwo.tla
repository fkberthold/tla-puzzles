---- MODULE TrestleTwo ----
EXTENDS Integers

(*--algorithm trestletwo {
  variables span = 0;
  {
    Lay:
      while (TRUE) {
        span := (span + 1) % 3;
      Rest:
        skip;
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "f3978ff2" /\ chksum(tla) = "364a8502")
VARIABLES pc, span

vars == << pc, span >>

Init == (* Global variables *)
        /\ span = 0
        /\ pc = "Lay"

Lay == /\ pc = "Lay"
       /\ span' = (span + 1) % 3
       /\ pc' = "Rest"

Rest == /\ pc = "Rest"
        /\ TRUE
        /\ pc' = "Lay"
        /\ span' = span

Next == Lay \/ Rest

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 
===========================
