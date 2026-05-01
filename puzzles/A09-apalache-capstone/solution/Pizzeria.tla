---- MODULE Pizzeria ----
EXTENDS Integers, Sequences, FiniteSets, Apalache

\* @typeAlias: order = { id: Int, topping: Str, size: Int };
\* @typeAlias: oven  = { id: Int, holding: $order, busy: Bool };
PizzeriaTypes == TRUE

CONSTANTS
  \* @type: Int;
  MaxOrders,
  \* @type: Set(Str);
  Toppings

\* @type: Int;
VARIABLE nextId

\* @type: Seq($order);
VARIABLE pendingQueue

\* @type: Int -> $oven;
VARIABLE ovens

\* @type: Set($order);
VARIABLE completed

\* @type: Int -> Int;
VARIABLE handled

vars == << nextId, pendingQueue, ovens, completed, handled >>

OvenIDs == { 1, 2 }

idleOrder  == [ id |-> 0, topping |-> "none", size |-> 0 ]
IdleOven(i) == [ id |-> i, holding |-> idleOrder, busy |-> FALSE ]

Init ==
  /\ nextId       := 1
  /\ pendingQueue := << >>
  /\ ovens        := [ i \in OvenIDs |-> IdleOven(i) ]
  /\ completed    := {}
  /\ handled      := [ i \in OvenIDs |-> 0 ]

Submit ==
  /\ nextId <= MaxOrders
  /\ \E t \in Toppings, s \in 1..3:
       LET o == [ id |-> nextId, topping |-> t, size |-> s ] IN
       /\ nextId'       := nextId + 1
       /\ pendingQueue' := Append(pendingQueue, o)
       /\ ovens'        := ovens
       /\ completed'    := completed
       /\ handled'      := handled

Assign ==
  /\ Len(pendingQueue) > 0
  /\ \E i \in OvenIDs:
       /\ ~ovens[i].busy
       /\ \A j \in OvenIDs: j < i => ovens[j].busy   \* pick the LOWEST idle oven
       /\ LET head == Head(pendingQueue) IN
          /\ ovens'        := [ ovens EXCEPT ![i] = [ id |-> i, holding |-> head, busy |-> TRUE ] ]
          /\ pendingQueue' := Tail(pendingQueue)
       /\ nextId'    := nextId
       /\ completed' := completed
       /\ handled'   := handled

Bake ==
  \E i \in OvenIDs:
    /\ ovens[i].busy
    /\ LET o == ovens[i].holding IN
       /\ completed' := completed \cup { o }
       /\ ovens'     := [ ovens EXCEPT ![i] = IdleOven(i) ]
       /\ handled'   := [ handled EXCEPT ![i] = handled[i] + 1 ]
    /\ nextId'       := nextId
    /\ pendingQueue' := pendingQueue

Finished ==
  /\ nextId > MaxOrders
  /\ pendingQueue = << >>
  /\ \A i \in OvenIDs: ~ovens[i].busy

Done ==
  /\ Finished
  /\ UNCHANGED vars

Next == Submit \/ Assign \/ Bake \/ Done

Spec == Init /\ [][Next]_vars

\* ------------------------------------------------------------------
\* Derived values (A05 — folds, no RECURSIVE)
\* ------------------------------------------------------------------

TotalCompleted == Cardinality(completed)

TotalSizeBaked ==
  LET Plus(acc, o) == acc + o.size
  IN  ApaFoldSet(Plus, 0, completed)

\* ------------------------------------------------------------------
\* Invariants
\* ------------------------------------------------------------------

TypeOK ==
  /\ nextId \in 0..(MaxOrders + 1)
  /\ Len(pendingQueue) <= MaxOrders
  /\ \A i \in OvenIDs: ovens[i].id = i
  /\ \A i \in OvenIDs: ovens[i].busy \in BOOLEAN
  /\ \A o \in completed: o.size \in 1..3
  /\ \A i \in OvenIDs: handled[i] \in 0..MaxOrders

BakedFitsCompleted ==
  TotalSizeBaked <= MaxOrders * 3

\* ------------------------------------------------------------------
\* Apalache parameterization
\* ------------------------------------------------------------------

ConstInit ==
  /\ MaxOrders \in 1..3
  /\ Toppings  = { "cheese", "pepperoni" }
====
