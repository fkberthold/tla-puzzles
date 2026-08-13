---- MODULE BellTower ----
\* Exercise 5 reference. Identical to the starter, which already runs.
\*
\* Two ringers each pull a rope `Quota` times. `chimes` counts every pull by
\* anybody. `left` is each ringer's own countdown, and it is a process-local
\* variable, so each ringer has its own.
\*
\* Note where `TallyMatches` sits. It is the last line before the `====`, below
\* where `pcal` will put the translation. `RightTotal` sits in the `define`
\* block instead. The exercise is about why they cannot swap places.
EXTENDS Integers, FiniteSets

Ringers == 1..2
Quota == 2

(*--algorithm belltower {
  variables chimes = 0;

  define {
    AllRung == \A r \in Ringers : pc[r] = "Done"
    RightTotal == AllRung => chimes = Quota * Cardinality(Ringers)
  }

  process (ringer \in Ringers)
    variables left = Quota;
  {
    Pull:
      while (left > 0) {
        chimes := chimes + 1;
        left := left - 1;
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "6ea5c07a" /\ chksum(tla) = "78a732b")
VARIABLES pc, chimes

(* define statement *)
AllRung == \A r \in Ringers : pc[r] = "Done"
RightTotal == AllRung => chimes = Quota * Cardinality(Ringers)

VARIABLE left

vars == << pc, chimes, left >>

ProcSet == (Ringers)

Init == (* Global variables *)
        /\ chimes = 0
        (* Process ringer *)
        /\ left = [self \in Ringers |-> Quota]
        /\ pc = [self \in ProcSet |-> "Pull"]

Pull(self) == /\ pc[self] = "Pull"
              /\ IF left[self] > 0
                    THEN /\ chimes' = chimes + 1
                         /\ left' = [left EXCEPT ![self] = left[self] - 1]
                         /\ pc' = [pc EXCEPT ![self] = "Pull"]
                    ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
                         /\ UNCHANGED << chimes, left >>

ringer(self) == Pull(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Ringers: ringer(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

\* The two ringers are written out by hand here. Adding up one entry per
\* element of a set needs a recursive operator, which this course has not
\* reached yet.
TallyMatches == chimes + left[1] + left[2] = Quota * Cardinality(Ringers)
====
