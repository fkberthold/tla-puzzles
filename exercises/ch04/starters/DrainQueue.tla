---- MODULE DrainQueue ----
EXTENDS Integers

Jobs == {1, 2, 3}

(*--algorithm drain_queue
variables
  pending = Jobs,
  cleared = {};

define
  \* Nothing to fill in here. Predict first, then run.
  AllPositive == \A j \in pending: j > 0

  SomePositive == \E j \in pending: j > 0
end define;

begin
Drain:
  while pending # {} do
    with j \in pending do
      pending := pending \ {j};
      cleared := cleared \union {j};
    end with;
  end while;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "f65f9170" /\ chksum(tla) = "14c30f5e")
VARIABLES pc, pending, cleared

(* define statement *)
AllPositive == \A j \in pending: j > 0

SomePositive == \E j \in pending: j > 0


vars == << pc, pending, cleared >>

Init == (* Global variables *)
        /\ pending = Jobs
        /\ cleared = {}
        /\ pc = "Drain"

Drain == /\ pc = "Drain"
         /\ IF pending # {}
               THEN /\ \E j \in pending:
                         /\ pending' = pending \ {j}
                         /\ cleared' = (cleared \union {j})
                    /\ pc' = "Drain"
               ELSE /\ pc' = "Done"
                    /\ UNCHANGED << pending, cleared >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Drain
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

====
