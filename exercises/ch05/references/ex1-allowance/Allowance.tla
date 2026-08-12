---- MODULE Allowance ----
\* Reference solution for exercise 1.
\* The whole point of this module is that the number 4 is nowhere in it.
\* StartingCredit arrives from the .cfg, so one spec serves both the small
\* model you iterate on and the larger model you gate on.
EXTENDS Integers

CONSTANT StartingCredit

(*--algorithm allowance
variable credit = StartingCredit;

define
  CreditNeverNegative == credit >= 0
end define;

begin
  Spend:
    while credit > 0 do
      credit := credit - 2;
    end while;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "74a67d68" /\ chksum(tla) = "98f32472")
VARIABLES pc, credit

(* define statement *)
CreditNeverNegative == credit >= 0


vars == << pc, credit >>

Init == (* Global variables *)
        /\ credit = StartingCredit
        /\ pc = "Spend"

Spend == /\ pc = "Spend"
         /\ IF credit > 0
               THEN /\ credit' = credit - 2
                    /\ pc' = "Spend"
               ELSE /\ pc' = "Done"
                    /\ UNCHANGED credit

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Spend
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
