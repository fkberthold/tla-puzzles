---- MODULE Allowance ----
\* STARTER for exercise 1. Copy this file somewhere you can edit it.
\*
\* This module runs as it stands. It also has a 4 welded into it, so the only
\* way to check a different starting credit is to edit the spec. That is the
\* habit this chapter breaks.
\*
\* After you change the PlusCal, re-run `pcal Allowance.tla` to refresh the
\* translation below. TLC runs the translation, not the PlusCal you typed.
EXTENDS Integers

(*--algorithm allowance
variable credit = 4;

define
  CreditNeverNegative == credit >= 0
end define;

begin
  Spend:
    while credit > 0 do
      credit := credit - 2;
    end while;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "f4bd88e2" /\ chksum(tla) = "846fbe1b")
VARIABLES pc, credit

(* define statement *)
CreditNeverNegative == credit >= 0


vars == << pc, credit >>

Init == (* Global variables *)
        /\ credit = 4
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
