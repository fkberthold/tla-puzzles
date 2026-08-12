---- MODULE TokenMove ----
EXTENDS Integers

Capacity == 3

(*--algorithm token_move
variables
  left = Capacity,
  right = 0;

define
  \* TODO: replace TRUE with a type invariant for `left` and `right`.
  \* Both are counts of tokens on a tray, and a tray holds at most
  \* `Capacity` of them.
  TypeInvariant == TRUE

  Conserved == left + right = Capacity
end define;

begin
Move:
  while left > 0 do
    left := left - 1;
    right := right + 1;
  end while;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "cd4f2340" /\ chksum(tla) = "76ef5220")
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
        /\ IF left > 0
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
