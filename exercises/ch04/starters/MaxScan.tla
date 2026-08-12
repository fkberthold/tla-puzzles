---- MODULE MaxScan ----
EXTENDS Integers, Sequences

Input == <<3, 7, 2, 7, 5>>

(*--algorithm max_scan
variables
  i = 1,
  best = Input[1];

define
  \* TODO: replace TRUE. No element of `Input` is above `best`.
  UpperBound == \A k \in 1..Len(Input): TRUE

  \* TODO: replace TRUE. Some element of `Input` equals `best`.
  Attained == \E k \in 1..Len(Input): TRUE

  \* TODO: replace the first TRUE. The check applies only once the
  \* algorithm has finished. Chapter 4 names the variable that tells you.
  BestIsMax == TRUE => (UpperBound /\ Attained)
end define;

begin
Scan:
  while i <= Len(Input) do
    if Input[i] > best then
      best := Input[i];
    end if;
    i := i + 1;
  end while;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "f14e42db" /\ chksum(tla) = "eab3cd84")
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
