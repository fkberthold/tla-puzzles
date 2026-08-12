---- MODULE Ex5DeadLabel ----
EXTENDS Integers, TLC

\* The probe sits in Trip. temp never rises above 30, so the guard temp > 40
\* is never true, so Trip is never entered and the assert never runs. TLC
\* explores the whole state space and reports OK.

(*--algorithm sensor
  variables
    temp \in 0..30,
    mode = "idle";

begin
  Sense:
    if temp > 40 then
      Trip:
        assert FALSE;
        mode := "alarm";
    elsif temp > 20 then
      mode := "cool";
    else
      mode := "hold";
    end if;
  Settle:
    skip;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "46f245ce" /\ chksum(tla) = "503c4c3b")
VARIABLES pc, temp, mode

vars == << pc, temp, mode >>

Init == (* Global variables *)
        /\ temp \in 0..30
        /\ mode = "idle"
        /\ pc = "Sense"

Sense == /\ pc = "Sense"
         /\ IF temp > 40
               THEN /\ pc' = "Trip"
                    /\ mode' = mode
               ELSE /\ IF temp > 20
                          THEN /\ mode' = "cool"
                          ELSE /\ mode' = "hold"
                    /\ pc' = "Settle"
         /\ temp' = temp

Trip == /\ pc = "Trip"
        /\ Assert(FALSE, "Failure of assertion at line 17, column 9.")
        /\ mode' = "alarm"
        /\ pc' = "Settle"
        /\ temp' = temp

Settle == /\ pc = "Settle"
          /\ TRUE
          /\ pc' = "Done"
          /\ UNCHANGED << temp, mode >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Sense \/ Trip \/ Settle
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
