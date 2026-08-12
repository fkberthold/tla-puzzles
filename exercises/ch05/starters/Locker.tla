---- MODULE Locker ----
\* SKELETON for exercise 3. Copy this file somewhere you can edit it.
\*
\* `holder` names whoever holds the locker. `claimed` records the same fact a
\* second way. `Unclaimed` is the placeholder that means nobody holds it.
\*
\* Two holes to fill.
\*   1. FreeIffSentinel is TRUE below, so it checks nothing. Replace it with a
\*      predicate tying `claimed` to whether `holder` is still the placeholder.
\*   2. Locker.cfg assigns nothing to `Unclaimed`. Assign it two different
\*      ways and run each. One way makes the sentinel distinct from every slot
\*      id no matter what the slots are. The other picks a value and hopes.
\*
\* After you change the PlusCal or the define block, re-run `pcal Locker.tla`.
EXTENDS Integers

CONSTANT Unclaimed

Slots == 1..3

(*--algorithm locker
variables holder = Unclaimed, claimed = FALSE;

define
  FreeIffSentinel == TRUE
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
\* BEGIN TRANSLATION (chksum(pcal) = "16716c" /\ chksum(tla) = "cf4a9769")
VARIABLES pc, holder, claimed

(* define statement *)
FreeIffSentinel == TRUE


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
