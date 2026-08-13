---- MODULE Ex2Stale ----
EXTENDS Integers, TLC

\* This is the one starter that arrives already translated. Read the PlusCal,
\* read the translation, and write your prediction in LOG.md before you run
\* anything.

(*--algorithm thermostat {
  variables
    setpoint = 68,
    bumps = 0;

  {
    Warmer:
      setpoint := setpoint + 2;
      bumps := bumps + 1;
    Cooler:
      setpoint := setpoint - 1;
      bumps := bumps + 1;
    Check:
      assert setpoint = 69;
      assert bumps = 2;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "e05ac07d" /\ chksum(tla) = "bf20e186")
VARIABLES pc, setpoint, bumps

vars == << pc, setpoint, bumps >>

Init == (* Global variables *)
        /\ setpoint = 68
        /\ bumps = 0
        /\ pc = "Warmer"

Warmer == /\ pc = "Warmer"
          /\ setpoint' = setpoint + 3
          /\ bumps' = bumps + 1
          /\ pc' = "Cooler"

Cooler == /\ pc = "Cooler"
          /\ setpoint' = setpoint - 1
          /\ bumps' = bumps + 1
          /\ pc' = "Check"

Check == /\ pc = "Check"
         /\ Assert(setpoint = 69,
                   "Failure of assertion at line 17, column 7.")
         /\ Assert(bumps = 2, "Failure of assertion at line 18, column 7.")
         /\ pc' = "Done"
         /\ UNCHANGED << setpoint, bumps >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Warmer \/ Cooler \/ Check
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION
====
