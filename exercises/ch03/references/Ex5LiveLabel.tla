---- MODULE Ex5LiveLabel ----
EXTENDS Integers, TLC

\* The control run for Ex5DeadLabel. The probe has moved one label down, into
\* Settle, which every behaviour reaches. The assert fires.
\*
\* Run this one whenever the dead-label run comes back OK. An OK means either
\* "the label never runs" or "the probe never worked", and only this run tells
\* those two apart.

(*--algorithm sensor {
  variables
    temp \in 0..30,
    mode = "idle";

  {
    Sense:
      if (temp > 40) {
        Trip:
          mode := "alarm";
      } else {
        if (temp > 20) {
          mode := "cool";
        } else {
          mode := "hold";
        }
      };
    Settle:
      assert FALSE;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "1946d781" /\ chksum(tla) = "82b5cb7b")
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
        /\ mode' = "alarm"
        /\ pc' = "Settle"
        /\ temp' = temp

Settle == /\ pc = "Settle"
          /\ Assert(FALSE, "Failure of assertion at line 22, column 7.")
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
