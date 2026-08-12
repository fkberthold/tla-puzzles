---- MODULE Locker ----
\* Reference solution for exercise 3.
\* Unclaimed is a placeholder meaning "nobody holds this locker".
\* `claimed` tracks the same fact a second way, so FreeIffSentinel fails the
\* moment the sentinel stops being distinguishable from a real slot id.
\* A model value keeps the two views agreeing for free, because it is equal
\* to itself and to nothing else. Any ordinary value you pick you must argue
\* for, and the argument is easy to get wrong.
EXTENDS Integers

CONSTANT Unclaimed

Slots == 1..3

(*--algorithm locker
variables holder = Unclaimed, claimed = FALSE;

define
  FreeIffSentinel == claimed = (holder # Unclaimed)
end define;

begin
  Claim:
    with s \in Slots do
      holder := s;
      claimed := TRUE;
    end with;
  Release:
    holder := Unclaimed;
    claimed := FALSE;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "822c4541" /\ chksum(tla) = "ee827136")
VARIABLES pc, holder, claimed

(* define statement *)
FreeIffSentinel == claimed = (holder # Unclaimed)


vars == << pc, holder, claimed >>

Init == (* Global variables *)
        /\ holder = Unclaimed
        /\ claimed = FALSE
        /\ pc = "Claim"

Claim == /\ pc = "Claim"
         /\ \E s \in Slots:
              /\ holder' = s
              /\ claimed' = TRUE
         /\ pc' = "Release"

Release == /\ pc = "Release"
           /\ holder' = Unclaimed
           /\ claimed' = FALSE
           /\ pc' = "Done"

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Claim \/ Release
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
