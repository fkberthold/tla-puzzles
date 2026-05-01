---- MODULE Timer ----
EXTENDS Integers

CONSTANT MaxTicks

(*--algorithm Timer {
  variables ticks = 0;

  define {
    TypeOK == ticks \in 0..MaxTicks
  }

  fair process (clk = "Clock") {
    tick:
      while (ticks < MaxTicks) {
        ticks := ticks + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "b6baed4c" /\ chksum(tla) = "2242818b")
VARIABLES ticks, pc

(* define statement *)
TypeOK == ticks \in 0..MaxTicks


vars == << ticks, pc >>

ProcSet == {"Clock"}

Init == (* Global variables *)
        /\ ticks = 0
        /\ pc = [self \in ProcSet |-> "tick"]

tick == /\ pc["Clock"] = "tick"
        /\ IF ticks < MaxTicks
              THEN /\ ticks' = ticks + 1
                   /\ pc' = [pc EXCEPT !["Clock"] = "tick"]
              ELSE /\ pc' = [pc EXCEPT !["Clock"] = "Done"]
                   /\ ticks' = ticks

clk == tick

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == clk
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(clk)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
