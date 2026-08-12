---- MODULE TokenMoveBroken ----
EXTENDS Integers

Capacity == 3

(*--algorithm token_move_broken
variables
  left = Capacity,
  right = 0;

define
  TypeInvariant ==
    /\ left \in 0..Capacity
    /\ right \in 0..Capacity

  Conserved == left + right = Capacity
end define;

begin
Move:
  while left >= 0 do
    left := left - 1;
    right := right + 1;
  end while;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "4d3398f9" /\ chksum(tla) = "f3fccc09")
VARIABLES pc, left, right

(* define statement *)
TypeInvariant ==
  /\ left \in 0..Capacity
  /\ right \in 0..Capacity

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
