---- MODULE Rehearsal ----
\* Reference solution for exercise 5.
\* StrictMode carries no data. It picks which of two behaviours the spec has,
\* the way a command line flag picks a code path. The ASSUME is what stops a
\* stray 7 in the .cfg from turning `IF StrictMode` into a silent surprise.
EXTENDS Integers

CONSTANT StrictMode
ASSUME StrictMode \in BOOLEAN

Ceiling == IF StrictMode THEN 2 ELSE 5

(*--algorithm rehearsal {
variable level = 0;

define {
  LevelCapped == level <= 2
}

{
  Climb:
    while (level < Ceiling) {
      level := level + 1;
    };
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "4334c0d5" /\ chksum(tla) = "46d71b1e")
VARIABLES pc, level

(* define statement *)
LevelCapped == level <= 2


vars == << pc, level >>

Init == (* Global variables *)
        /\ level = 0
        /\ pc = "Climb"

Climb == /\ pc = "Climb"
         /\ IF level < Ceiling
               THEN /\ level' = level + 1
                    /\ pc' = "Climb"
               ELSE /\ pc' = "Done"
                    /\ level' = level

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Climb
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
