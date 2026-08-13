---- MODULE Kiln ----
\* GIVEN module for exercise 2. Nothing to fill in. Read it, predict,
\* run it. The worked write-up is under references/ex2-kiln/.
\* Two constants that are only meaningful together, plus a size budget.
\* The ASSUME lines say both things out loud, so a nonsense pair is rejected
\* before any state is generated instead of surfacing later as a puzzling
\* invariant violation.
\*
\* Both guards are reachable from a plain .cfg. That is not automatic. A .cfg
\* assigns a literal, never an expression, so it cannot write a negative
\* number at all, and a guard like `ASSUME Warmup >= 0` could never fire from
\* one. A guard nobody can trip is documentation, not a check.
EXTENDS Integers

CONSTANT Warmup, Deadline
ASSUME Deadline > Warmup
ASSUME Deadline <= 6

(*--algorithm kiln {
variable clock = Warmup;

define {
  ClockInWindow == clock \in Warmup..Deadline
}

{
  Tick:
    while (clock < Deadline) {
      clock := clock + 1;
    };
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "5ddba3de" /\ chksum(tla) = "50529756")
VARIABLES pc, clock

(* define statement *)
ClockInWindow == clock \in Warmup..Deadline


vars == << pc, clock >>

Init == (* Global variables *)
        /\ clock = Warmup
        /\ pc = "Tick"

Tick == /\ pc = "Tick"
        /\ IF clock < Deadline
              THEN /\ clock' = clock + 1
                   /\ pc' = "Tick"
              ELSE /\ pc' = "Done"
                   /\ clock' = clock

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Tick
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
