---- MODULE PatchDesk ----
\* Exercise 4 reference, learntla core ch.6 "Structured Data".
\*
\* `settings` is built and patched with `:>` and `@@` instead of a set
\* comprehension. The point of the exercise is the merge rule. `f @@ g` keeps
\* `f`'s value on a key both sides carry, so which operand goes on the left
\* decides whether an earlier override survives a later merge.
EXTENDS Integers, TLC

Keys == {"retries", "timeout"}

(*--algorithm patchdesk {
variables
  settings = [k \in Keys |-> 0];
  overridden = FALSE;

define {
  TypeOK == settings \in [Keys -> 0..9]

  KeysAreFixed == DOMAIN settings = Keys

  OverrideSticks == overridden => settings["retries"] = 5
}

{
  Override:
    settings := ("retries" :> 5) @@ settings;
    overridden := TRUE;
  Remerge:
    settings := settings @@ ("retries" :> 9);
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "6f77649d" /\ chksum(tla) = "449e1382")
VARIABLES pc, settings, overridden

(* define statement *)
TypeOK == settings \in [Keys -> 0..9]

KeysAreFixed == DOMAIN settings = Keys

OverrideSticks == overridden => settings["retries"] = 5


vars == << pc, settings, overridden >>

Init == (* Global variables *)
        /\ settings = [k \in Keys |-> 0]
        /\ overridden = FALSE
        /\ pc = "Override"

Override == /\ pc = "Override"
            /\ settings' = ("retries" :> 5) @@ settings
            /\ overridden' = TRUE
            /\ pc' = "Remerge"

Remerge == /\ pc = "Remerge"
           /\ settings' = settings @@ ("retries" :> 9)
           /\ pc' = "Done"
           /\ UNCHANGED overridden

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Override \/ Remerge
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
