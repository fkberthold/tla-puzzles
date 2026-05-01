---- MODULE Vacuum ----
EXTENDS Integers, TLC

\* Starting spec with a deliberate fairness bug.
\* Run TLC, read the liveness violation, then fix the fairness on
\* exactly ONE process to make Charges pass. Re-translate and re-check.

(*--algorithm Vacuum {
  variables available = FALSE, charged = 0;

  define {
    TypeOK == available \in BOOLEAN /\ charged \in 0..3
    \* Charges keeps recurring: the robot tops up infinitely often.
    \* (charged is mod 4 so the state space is finite.)
    Charges == []<>(charged > 0)
  }

  \* The dock cycles between unavailable and available.
  fair process (dock = "Dock") {
    cycle:
      while (TRUE) {
        await ~available;
        available := TRUE;
      }
  }

  \* The robot waits for the dock, charges, and releases.
  process (robot = "Robot") {
    work:
      while (TRUE) {
        await available;
        charged := (charged + 1) % 4;
        available := FALSE;
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "2c37a41b" /\ chksum(tla) = "d7136a9")
VARIABLES available, charged

(* define statement *)
TypeOK == available \in BOOLEAN /\ charged \in 0..3


Charges == []<>(charged > 0)


vars == << available, charged >>

ProcSet == {"Dock"} \cup {"Robot"}

Init == (* Global variables *)
        /\ available = FALSE
        /\ charged = 0

dock == /\ ~available
        /\ available' = TRUE
        /\ UNCHANGED charged

robot == /\ available
         /\ charged' = (charged + 1) % 4
         /\ available' = FALSE

Next == dock \/ robot

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(dock)

\* END TRANSLATION 
================================
