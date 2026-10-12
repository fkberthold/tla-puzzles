------------------------------ MODULE Locks ------------------------------
EXTENDS Naturals, Sequences

CONSTANTS Workers, Locks, NoOne, Order

ASSUME NoOne \notin Workers
ASSUME Order \in [Workers -> Seq(Locks)]

\* Each worker takes its locks in the order the constant gives it, works,
\* then releases both. With one worker ordered the other way round, two
\* workers each holding the other's first lock have nowhere to go. With
\* the same order everywhere, the only state with no successor is the one
\* where everybody has finished, which is the state the system is for.

VARIABLES holder, pc

vars == <<holder, pc>>

TypeOK ==
    /\ holder \in [Locks -> Workers \cup {NoOne}]
    /\ pc \in [Workers -> 0..3]

Init ==
    /\ holder = [l \in Locks |-> NoOne]
    /\ pc = [w \in Workers |-> 0]

Acquire(w) ==
    /\ pc[w] \in {0, 1}
    /\ LET l == Order[w][pc[w] + 1] IN
        /\ holder[l] = NoOne
        /\ holder' = [holder EXCEPT ![l] = w]
    /\ pc' = [pc EXCEPT ![w] = pc[w] + 1]

ReleaseAll(w) ==
    /\ pc[w] = 2
    /\ holder' = [l \in Locks |-> IF holder[l] = w THEN NoOne ELSE holder[l]]
    /\ pc' = [pc EXCEPT ![w] = 3]

AllDone == \A w \in Workers : pc[w] = 3

Next == \E w \in Workers : Acquire(w) \/ ReleaseAll(w)

Spec == Init /\ [][Next]_vars

\* The alternative to switching the check off: say in the behaviour
\* formula that finishing is allowed to go nowhere. Then the only state
\* TLC can report is one that is stuck for some other reason.
Terminating == AllDone /\ UNCHANGED vars
SpecWithEnd == Init /\ [][Next \/ Terminating]_vars

\* A worker that is working holds every lock. Holds on both orderings; the
\* ordering bug is a deadlock, not a safety violation, which is why the
\* deadlock check is the only thing that can see it.
WorkingHoldsBoth == \A w \in Workers : pc[w] = 2 => \A l \in Locks : holder[l] = w

==========================================================================
