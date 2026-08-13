---- MODULE SeatDesk ----
\* Exercise 1 reference answer.
\*
\* The whole point sits in the label structure. `Look` holds all three
\* statements, so an agent's look and its sale are one indivisible step and no
\* other agent can act between them. Give the `if` its own label and the two
\* agents can both look at a one-seat desk, both see a free seat, and both
\* sell it.
EXTENDS Integers

Agents == {"ann", "bo"}
Capacity == 1

(*--algorithm seatdesk {
  variables seats = Capacity, sold = 0;

  define {
    NeverOversold == seats >= 0

    BooksBalance == seats + sold = Capacity
  }

  process (agent \in Agents)
    variables sawFree = FALSE;
  {
    Look:
      sawFree := (seats > 0);
      if (sawFree) {
        seats := seats - 1;
        sold := sold + 1;
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "567c2700" /\ chksum(tla) = "f49d8273")
VARIABLES pc, seats, sold

(* define statement *)
NeverOversold == seats >= 0

BooksBalance == seats + sold = Capacity

VARIABLE sawFree

vars == << pc, seats, sold, sawFree >>

ProcSet == (Agents)

Init == (* Global variables *)
        /\ seats = Capacity
        /\ sold = 0
        (* Process agent *)
        /\ sawFree = [self \in Agents |-> FALSE]
        /\ pc = [self \in ProcSet |-> "Look"]

Look(self) == /\ pc[self] = "Look"
              /\ sawFree' = [sawFree EXCEPT ![self] = (seats > 0)]
              /\ IF sawFree'[self]
                    THEN /\ seats' = seats - 1
                         /\ sold' = sold + 1
                    ELSE /\ TRUE
                         /\ UNCHANGED << seats, sold >>
              /\ pc' = [pc EXCEPT ![self] = "Done"]

agent(self) == Look(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Agents: agent(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
