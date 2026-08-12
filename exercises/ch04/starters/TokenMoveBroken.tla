---- MODULE TokenMoveBroken ----
EXTENDS Integers

Capacity == 3

(*--algorithm token_move_broken
variables
  left = Capacity,
  right = 0;

define
  \* TODO: paste the SAME invariant you wrote in TokenMove.tla here.
  \* The algorithm below is wrong on purpose. A real invariant has to
  \* fail on it.
  TypeInvariant == TRUE

  Conserved == left + right = Capacity
end define;

begin
Move:
  while left >= 0 do
    left := left - 1;
    right := right + 1;
  end while;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "b44969ed" /\ chksum(tla) = "21e63bfe")
VARIABLES pc, left, right

(* define statement *)
TypeInvariant == TRUE

Conserved == left + right = Capacity


vars == << pc, left, right >>

Init == (* Global variables *)
        /\ left = Capacity
        /\ right = 0
        /\ pc = "Move"

Move == /\ pc = "Move"
        /\ IF left >= 0
              THEN /\ left' = left - 1
                   /\ right' = right + 1
                   /\ pc' = "Move"
              ELSE /\ pc' = "Done"
                   /\ UNCHANGED << left, right >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Move
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

====
