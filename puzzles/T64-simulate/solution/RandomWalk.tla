---- MODULE RandomWalk ----
EXTENDS Integers, TLC

(*--algorithm RandomWalk {
  variables x = 0, y = 0, z = 0, steps = 0;

  define {
    TypeOK == x \in -200..200 /\ y \in -200..200 /\ z \in -200..200 /\ steps \in 0..200
    StaysReachable == x*x + y*y + z*z <= 200*200
  }

  fair process (walker = "Walker") {
    walk:
      while (steps < 200) {
        either { x := x + 1; }
        or     { x := x - 1; }
        or     { y := y + 1; }
        or     { y := y - 1; }
        or     { z := z + 1; }
        or     { z := z - 1; };
        steps := steps + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "4f1bfecb" /\ chksum(tla) = "807d402d")
VARIABLES pc, x, y, z, steps

(* define statement *)
TypeOK == x \in -200..200 /\ y \in -200..200 /\ z \in -200..200 /\ steps \in 0..200
StaysReachable == x*x + y*y + z*z <= 200*200


vars == << pc, x, y, z, steps >>

ProcSet == {"Walker"}

Init == (* Global variables *)
        /\ x = 0
        /\ y = 0
        /\ z = 0
        /\ steps = 0
        /\ pc = [self \in ProcSet |-> "walk"]

walk == /\ pc["Walker"] = "walk"
        /\ IF steps < 200
              THEN /\ \/ /\ x' = x + 1
                         /\ UNCHANGED <<y, z>>
                      \/ /\ x' = x - 1
                         /\ UNCHANGED <<y, z>>
                      \/ /\ y' = y + 1
                         /\ UNCHANGED <<x, z>>
                      \/ /\ y' = y - 1
                         /\ UNCHANGED <<x, z>>
                      \/ /\ z' = z + 1
                         /\ UNCHANGED <<x, y>>
                      \/ /\ z' = z - 1
                         /\ UNCHANGED <<x, y>>
                   /\ steps' = steps + 1
                   /\ pc' = [pc EXCEPT !["Walker"] = "walk"]
              ELSE /\ pc' = [pc EXCEPT !["Walker"] = "Done"]
                   /\ UNCHANGED << x, y, z, steps >>

walker == walk

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == walker
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(walker)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
