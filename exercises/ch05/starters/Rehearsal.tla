---- MODULE Rehearsal ----
\* STARTER for exercise 5. This is your own copy, so edit it in place.
\*
\* The climb stops at 5. `LevelCapped` wants it to stop at 2. As written the
\* two disagree and there is no way to reconcile them without editing the
\* spec.
\*
\* Your job is to add one constant that picks between the two ceilings, so a
\* .cfg can ask for either behaviour. The constant carries no data. It selects
\* a behaviour, the way a command line flag selects a code path.
\*
\* After you change the PlusCal, re-run `pcal Rehearsal.tla`.
EXTENDS Integers

Ceiling == 5

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
