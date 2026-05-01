---- MODULE Tracker ----
EXTENDS Integers, Sequences

VARIABLES
  \* @type: Set(Int);
  pending,
  \* @type: Seq(Int);
  queue,
  \* @type: <<Int, Int>>;
  shift,
  \* @type: { id: Int, priority: Str };
  currentOrder,
  \* @type: Int -> Str;
  status
vars == << pending, queue, shift, currentOrder, status >>

Init ==
  /\ pending      = { 1, 2, 3 }
  /\ queue        = << >>
  /\ shift        = << 10, 20 >>
  /\ currentOrder = [ id |-> 0, priority |-> "none" ]
  /\ status       = [ i \in { 1, 2, 3 } |-> "pending" ]

Promote ==
  \E i \in pending:
    /\ pending'      = pending \ { i }
    /\ queue'        = Append(queue, i)
    /\ currentOrder' = [ id |-> i, priority |-> "high" ]
    /\ status'       = [ status EXCEPT ![i] = "processing" ]
    /\ shift'        = shift

Done ==
  /\ pending = {}
  /\ UNCHANGED vars

Next == Promote \/ Done

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ pending \subseteq { 1, 2, 3 }
  /\ Len(queue) <= 3
  /\ shift = << 10, 20 >>
  /\ currentOrder.id \in 0..3
  /\ currentOrder.priority \in { "none", "high" }
====
