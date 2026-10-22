---- MODULE Trestle ----
EXTENDS Integers

(*--algorithm trestle {
  variables span = 0;
  {
    Lay:
      while (TRUE) {
        span := (span + 1) % 3;
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "6ad25dfc" /\ chksum(tla) = "784bba6a")
VARIABLE span

vars == << span >>

Init == (* Global variables *)
        /\ span = 0

Next == span' = (span + 1) % 3

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 
========================
