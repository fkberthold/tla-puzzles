---- MODULE SafetyDemo ----
\* A toggle whose state is always either "on" or "off".
\* Demonstrates the SHAPE of a safety property: an INVARIANT.
\* Safety: "the state never escapes {on, off}".
\* Liveness: "eventually the toggle is on" — different shape, different cfg keyword.
EXTENDS Integers, TLC

(*--algorithm SafetyDemo {
  variables state = "off", flips = 0;

  define {
    \* Safety (invariant): state is always one of these two strings.
    StateOK == state \in {"on", "off"}

    \* Safety (invariant): flips never goes negative.
    FlipsNonNeg == flips >= 0

    \* Liveness (temporal property): eventually we reach "on".
    EventuallyOn == <>(state = "on")
  }

  fair process (toggler = "Toggler") {
    flip:
      while (flips < 2) {
        if (state = "off") { state := "on"; }
        else                { state := "off"; };
        flips := flips + 1;
      };
  }
}
*)
\* BEGIN TRANSLATION
VARIABLES pc, state, flips

(* define statement *)
StateOK == state \in {"on", "off"}


FlipsNonNeg == flips >= 0


EventuallyOn == <>(state = "on")


vars == << pc, state, flips >>

ProcSet == {"Toggler"}

Init == (* Global variables *)
        /\ state = "off"
        /\ flips = 0
        /\ pc = [self \in ProcSet |-> "flip"]

flip == /\ pc["Toggler"] = "flip"
        /\ IF flips < 2
              THEN /\ IF state = "off"
                         THEN /\ state' = "on"
                         ELSE /\ state' = "off"
                   /\ flips' = flips + 1
                   /\ pc' = [pc EXCEPT !["Toggler"] = "flip"]
              ELSE /\ pc' = [pc EXCEPT !["Toggler"] = "Done"]
                   /\ UNCHANGED << state, flips >>

toggler == flip

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == toggler
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(toggler)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
