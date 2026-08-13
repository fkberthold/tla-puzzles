---- MODULE MaxScanBroken ----
EXTENDS Integers, Sequences

Input == <<3, 7, 2, 7, 5>>

(*--algorithm max_scan_broken {
variables
  i = 1,
  best = Input[1];

define {
  \* TODO: paste the SAME three definitions you completed in MaxScan.tla.
  \* The algorithm below is wrong on purpose. A real invariant has to
  \* fail on it.
  UpperBound == \A k \in 1..Len(Input): TRUE

  Attained == \E k \in 1..Len(Input): TRUE

  BestIsMax == TRUE => (UpperBound /\ Attained)
}

{
Scan:
  while (i <= Len(Input)) {
    best := Input[i];
    i := i + 1;
  };
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "a3bd5bf7" /\ chksum(tla) = "67ee8efb")
VARIABLES pc, i, best

(* define statement *)
UpperBound == \A k \in 1..Len(Input): TRUE

Attained == \E k \in 1..Len(Input): TRUE

BestIsMax == TRUE => (UpperBound /\ Attained)


vars == << pc, i, best >>

Init == (* Global variables *)
        /\ i = 1
        /\ best = Input[1]
        /\ pc = "Scan"

Scan == /\ pc = "Scan"
        /\ IF i <= Len(Input)
              THEN /\ best' = Input[i]
                   /\ i' = i + 1
                   /\ pc' = "Scan"
              ELSE /\ pc' = "Done"
                   /\ UNCHANGED << i, best >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Scan
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

====
