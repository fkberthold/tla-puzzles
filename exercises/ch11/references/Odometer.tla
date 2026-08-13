---- MODULE Odometer ----
\* Exercise 1 reference answer.
\*
\* A delivery van drives a fixed number of legs. `miles` is the odometer and
\* `legs` counts completed legs. The two never move in the same step, which is
\* the point: each action property has to tolerate the steps that leave its own
\* variable alone, and the `[...]_var` brackets are what does that.
EXTENDS Integers

MaxLegs == 3
LegLength == 2

(*--algorithm odometer {
  variables
    miles = 0,
    legs = 0;
  define {
    \* The odometer is a ratchet. It may hold still, it may climb, it may
    \* never drop.
    MilesNeverFall == [][miles' >= miles]_miles

    \* The leg counter is stricter. When it moves at all it moves by one.
    \* `Roll` and `Depot` leave `legs` alone, and the brackets are what lets
    \* those steps through.
    LegsCountUpByOne == [][legs' = legs + 1]_legs
  }
  {
    Depot:
      while (legs < MaxLegs) {
        Roll:
          miles := miles + LegLength;
        Log:
          legs := legs + 1;
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "521fe311" /\ chksum(tla) = "b137bfb2")
VARIABLES pc, miles, legs

(* define statement *)
MilesNeverFall == [][miles' >= miles]_miles




LegsCountUpByOne == [][legs' = legs + 1]_legs


vars == << pc, miles, legs >>

Init == (* Global variables *)
        /\ miles = 0
        /\ legs = 0
        /\ pc = "Depot"

Depot == /\ pc = "Depot"
         /\ IF legs < MaxLegs
               THEN /\ pc' = "Roll"
               ELSE /\ pc' = "Done"
         /\ UNCHANGED << miles, legs >>

Roll == /\ pc = "Roll"
        /\ miles' = miles + LegLength
        /\ pc' = "Log"
        /\ legs' = legs

Log == /\ pc = "Log"
       /\ legs' = legs + 1
       /\ pc' = "Depot"
       /\ miles' = miles

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Depot \/ Roll \/ Log
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
