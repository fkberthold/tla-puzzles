---- MODULE StampDesk ----
\* Exercise 4 reference answer.
\*
\* `EXTENDS Sequences` is not optional. The translator keeps a call stack in a
\* tuple, so a spec with a procedure needs the Sequences operators whether or
\* not the algorithm mentions a sequence anywhere.
\*
\* The procedure sits after the `define` block and before the process, which
\* is where PlusCal requires it.
EXTENDS Integers, Sequences

Clerks == {"ann", "bo"}
MaxInk == 4

(*--algorithm stampdesk {
  variables ink = MaxInk, stamped = 0;

  define {
    InkNeverNegative == ink >= 0

    LedgerBalances == stamped + ink = MaxInk
  }

  procedure Stamp(copies)
    variables made = 0;
  {
    Press:
      while (made < copies) {
        ink := ink - 1;
        stamped := stamped + 1;
        made := made + 1;
      };
    Finish:
      return;
  }

  process (clerk \in Clerks)
  {
    Job:
      call Stamp(2);
    Leave:
      skip;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "7de309c6" /\ chksum(tla) = "bc7e62d7")
CONSTANT defaultInitValue
VARIABLES pc, ink, stamped, stack

(* define statement *)
InkNeverNegative == ink >= 0

LedgerBalances == stamped + ink = MaxInk

VARIABLES copies, made

vars == << pc, ink, stamped, stack, copies, made >>

ProcSet == (Clerks)

Init == (* Global variables *)
        /\ ink = MaxInk
        /\ stamped = 0
        (* Procedure Stamp *)
        /\ copies = [ self \in ProcSet |-> defaultInitValue]
        /\ made = [ self \in ProcSet |-> 0]
        /\ stack = [self \in ProcSet |-> << >>]
        /\ pc = [self \in ProcSet |-> "Job"]

Press(self) == /\ pc[self] = "Press"
               /\ IF made[self] < copies[self]
                     THEN /\ ink' = ink - 1
                          /\ stamped' = stamped + 1
                          /\ made' = [made EXCEPT ![self] = made[self] + 1]
                          /\ pc' = [pc EXCEPT ![self] = "Press"]
                     ELSE /\ pc' = [pc EXCEPT ![self] = "Finish"]
                          /\ UNCHANGED << ink, stamped, made >>
               /\ UNCHANGED << stack, copies >>

Finish(self) == /\ pc[self] = "Finish"
                /\ pc' = [pc EXCEPT ![self] = Head(stack[self]).pc]
                /\ made' = [made EXCEPT ![self] = Head(stack[self]).made]
                /\ copies' = [copies EXCEPT ![self] = Head(stack[self]).copies]
                /\ stack' = [stack EXCEPT ![self] = Tail(stack[self])]
                /\ UNCHANGED << ink, stamped >>

Stamp(self) == Press(self) \/ Finish(self)

Job(self) == /\ pc[self] = "Job"
             /\ /\ copies' = [copies EXCEPT ![self] = 2]
                /\ stack' = [stack EXCEPT ![self] = << [ procedure |->  "Stamp",
                                                         pc        |->  "Leave",
                                                         made      |->  made[self],
                                                         copies    |->  copies[self] ] >>
                                                     \o stack[self]]
             /\ made' = [made EXCEPT ![self] = 0]
             /\ pc' = [pc EXCEPT ![self] = "Press"]
             /\ UNCHANGED << ink, stamped >>

Leave(self) == /\ pc[self] = "Leave"
               /\ TRUE
               /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ UNCHANGED << ink, stamped, stack, copies, made >>

clerk(self) == Job(self) \/ Leave(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in ProcSet: Stamp(self))
           \/ (\E self \in Clerks: clerk(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
