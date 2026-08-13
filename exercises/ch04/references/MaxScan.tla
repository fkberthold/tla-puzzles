---- MODULE MaxScan ----
EXTENDS Integers, Sequences

Input == <<3, 7, 2, 7, 5>>

(*--algorithm max_scan {
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
    if (Input[i] > best) {
      best := Input[i];
    };
    i := i + 1;
  };
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "f9c898d8" /\ chksum(tla) = "b850f09c")
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
              THEN /\ IF Input[i] > best
                         THEN /\ best' = Input[i]
                         ELSE /\ TRUE
                              /\ best' = best
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
