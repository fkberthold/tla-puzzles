---- MODULE MaxScanBroken ----
EXTENDS Integers, Sequences

Input == <<3, 7, 2, 7, 5>>

(*--algorithm max_scan_broken {
variables
  i = 1,
  best = Input[1];

define {
  UpperBound == \A k \in 1..Len(Input): Input[k] <= best

  Attained == \E k \in 1..Len(Input): Input[k] = best

  BestIsMax == pc = "Done" => (UpperBound /\ Attained)
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
\* BEGIN TRANSLATION (chksum(pcal) = "ea49603d" /\ chksum(tla) = "3606dab5")
VARIABLES pc, i, best

(* define statement *)
UpperBound == \A k \in 1..Len(Input): Input[k] <= best

Attained == \E k \in 1..Len(Input): Input[k] = best

BestIsMax == pc = "Done" => (UpperBound /\ Attained)


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
