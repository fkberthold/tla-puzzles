---- MODULE Footbridge ----
\* Exercise 1 reference solution.
\*
\* A footbridge is shut, open, or condemned. An inspector may condemn it at any
\* time, and a condemned bridge never reopens. `StateOK` is an ordinary
\* invariant. `CondemnedIsForever` is a safety property that no single state can
\* decide, which is why it goes in PROPERTY rather than INVARIANT.

States == {"shut", "open", "condemned"}

(*--algorithm footbridge {
  variables state = "shut";

  define {
    StateOK == state \in States

    CondemnedIsForever ==
      [](state = "condemned" => [](state = "condemned"))
  }

  process (Warden = "warden") {
    Tend:
      while (TRUE) {
        either {
          await state = "shut";
          state := "open";
        } or {
          await state = "open";
          state := "shut";
        } or {
          await state # "condemned";
          state := "condemned";
        }
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "398add9" /\ chksum(tla) = "2bde1dc2")
VARIABLE state

(* define statement *)
StateOK == state \in States

CondemnedIsForever ==
  [](state = "condemned" => [](state = "condemned"))


vars == << state >>

ProcSet == {"warden"}

Init == (* Global variables *)
        /\ state = "shut"

Warden == \/ /\ state = "shut"
             /\ state' = "open"
          \/ /\ state = "open"
             /\ state' = "shut"
          \/ /\ state # "condemned"
             /\ state' = "condemned"

Next == Warden

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 
====
