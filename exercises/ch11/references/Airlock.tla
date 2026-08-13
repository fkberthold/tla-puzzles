---- MODULE Airlock ----
\* Exercise 5 reference answer.
\*
\* An airlock with two doors. The invariant says what a legal state looks like.
\* The two action properties say how a door is allowed to move. One helper
\* action carries the primed logic for both of them.
EXTENDS Integers

(*--algorithm airlock {
  variables
    outer = "shut",
    inner = "shut";
  define {
    \* A state predicate. Checked with INVARIANT.
    NeverBothOpen == ~(outer = "open" /\ inner = "open")

    \* A helper action. It mentions a primed variable, so it is an action and
    \* not a state predicate, and it can only appear inside an action property.
    Moves(door, to) == door' = to

    \* Both properties reuse the one helper.
    OuterOnlyShuts == [][outer = "open" => Moves(outer, "shut")]_outer
    InnerOnlyShuts == [][inner = "open" => Moves(inner, "shut")]_inner
  }
  {
    Cycle:
      while (TRUE) {
        either {
          await outer = "shut" /\ inner = "shut";
          outer := "open";
        } or {
          await outer = "open";
          outer := "shut";
        } or {
          await inner = "shut" /\ outer = "shut";
          inner := "open";
        } or {
          await inner = "open";
          inner := "shut";
        };
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "95d4fd6e" /\ chksum(tla) = "1af2ae29")
VARIABLES outer, inner

(* define statement *)
NeverBothOpen == ~(outer = "open" /\ inner = "open")



Moves(door, to) == door' = to


OuterOnlyShuts == [][outer = "open" => Moves(outer, "shut")]_outer
InnerOnlyShuts == [][inner = "open" => Moves(inner, "shut")]_inner


vars == << outer, inner >>

Init == (* Global variables *)
        /\ outer = "shut"
        /\ inner = "shut"

Next == \/ /\ outer = "shut" /\ inner = "shut"
           /\ outer' = "open"
           /\ inner' = inner
        \/ /\ outer = "open"
           /\ outer' = "shut"
           /\ inner' = inner
        \/ /\ inner = "shut" /\ outer = "shut"
           /\ inner' = "open"
           /\ outer' = outer
        \/ /\ inner = "open"
           /\ inner' = "shut"
           /\ outer' = outer

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 
====
